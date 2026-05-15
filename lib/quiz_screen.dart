import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/question.dart';
import 'services/exam_service.dart';
import 'result_screen.dart';

// ── Internal display model ────────────────────────────────────────────────────

class _Q {
  final Question source;
  final List<String> opts;
  final int correctIdx;
  bool skippedOnce = false;

  _Q({required this.source, required this.opts, required this.correctIdx});

  factory _Q.from(Question q) {
    final rng = Random();
    final wrongIdx = List.generate(q.options.length, (i) => i)..remove(q.correctIndex);
    wrongIdx.shuffle(rng);
    final pool = [q.correctIndex, ...wrongIdx.take(3)];
    pool.shuffle(rng);
    return _Q(
      source: q,
      opts: pool.map((i) => q.options[i]).toList(),
      correctIdx: pool.indexOf(q.correctIndex),
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source.toJson(),
    'opts': opts,
    'correct_idx': correctIdx,
    'skipped_once': skippedOnce,
  };

  factory _Q.fromJson(Map<String, dynamic> j) => _Q(
    source: Question.fromJson(j['source'] as Map<String, dynamic>),
    opts: List<String>.from(j['opts'] as List),
    correctIdx: j['correct_idx'] as int,
  )..skippedOnce = j['skipped_once'] as bool;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class QuizScreen extends StatefulWidget {
  final String examName;
  final int examIndex;

  const QuizScreen({super.key, required this.examName, required this.examIndex});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _transCtrl;
  late AnimationController _timerCtrl;
  late Animation<double> _fade;
  late Animation<double> _slide;

  bool _loading = true;
  List<_Q> _queue = [];
  int _currentPos = 0;
  int _totalQ     = 0;
  int _answered   = 0;
  int _correct    = 0;
  int _wrong      = 0;
  int _skipsLeft  = 3;
  int _hintsLeft  = 3;

  int? _selectedOpt;
  bool _revealed = false;
  Set<int> _elim = {};

  late AudioPlayer _bgPlayer;
  int _bgStartToken = 0;
  late AudioPlayer _sfxPlayer;

  @override
  void initState() {
    super.initState();
    _transCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
    _timerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 40));
    _timerCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_revealed) {
        _onTimeExpired();
      }
    });
    _fade = CurvedAnimation(parent: _transCtrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 28, end: 0)
        .animate(CurvedAnimation(parent: _transCtrl, curve: Curves.easeOut));
    _bgPlayer  = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    WidgetsBinding.instance.addObserver(this);
    _loadExam();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_loading && _queue.isNotEmpty) {
      _saveStateToPrefs();
    }
  }

  Future<void> _loadExam() async {
    try {
      if (await _tryRestoreFromPrefs()) {
        _transCtrl.forward();
        _timerCtrl.forward(from: 0.0);
        _startTimerAudio();
        return;
      }
      final questions = await ExamService().generateTeoricaGeral();
      if (!mounted) return;
      setState(() {
        _queue   = questions.map(_Q.from).toList();
        _totalQ  = _queue.length;
        _loading = false;
      });
      _transCtrl.forward();
      _timerCtrl.forward(from: 0.0);
      _startTimerAudio();
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ── Save / restore ────────────────────────────────────────────────────────

  String get _saveKey => 'saved_exam_${widget.examIndex}';

  Future<bool> _tryRestoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null) return false;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final queue = (data['queue'] as List)
          .map((e) => _Q.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return false;
      setState(() {
        _queue       = queue;
        _totalQ      = queue.length;
        _currentPos  = data['current_pos'] as int;
        _answered    = data['answered'] as int;
        _correct     = data['correct'] as int;
        _wrong       = data['wrong'] as int;
        _skipsLeft   = data['skips_left'] as int;
        _hintsLeft   = data['hints_left'] as int;
        _loading = false;
      });
      return true;
    } catch (_) {
      await prefs.remove(_saveKey);
      return false;
    }
  }

  Future<void> _saveStateToPrefs() async {
    if (_loading || _queue.isEmpty) return;
    // If an answer is already revealed, advance past it for the save point
    final savePos = _revealed ? _currentPos + 1 : _currentPos;
    if (savePos >= _queue.length) return; // effectively finished
    final state = {
      'current_pos': savePos,
      'answered':    _revealed ? _answered : _answered,
      'correct':     _correct,
      'wrong':       _wrong,
      'skips_left':  _skipsLeft,
      'hints_left':  _hintsLeft,
      'queue':       _queue.map((q) => q.toJson()).toList(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(state));
  }

  Future<void> _clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  _Q get _cur => _queue[_currentPos];

  // ── Actions ───────────────────────────────────────────────────────────────

  void _onTimeExpired() {
    if (!mounted || _revealed) return;
    _stopTimerAudio();
    setState(() {
      _revealed = true;
      _answered++;
      _wrong++;
    });
    _playAnswerSound(false);
    Future.delayed(const Duration(milliseconds: 1600), _advance);
  }

  void _onOptionTap(int idx) {
    if (_revealed || _elim.contains(idx)) return;
    final isCorrect = idx == _cur.correctIdx;
    _timerCtrl.stop();
    _stopTimerAudio();
    setState(() {
      _selectedOpt = idx;
      _revealed    = true;
      _answered++;
      if (isCorrect) { _correct++; } else { _wrong++; }
    });
    _playAnswerSound(isCorrect);
    Future.delayed(const Duration(milliseconds: 1600), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_currentPos >= _queue.length - 1) { _finishExam(); return; }
    _transCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentPos++;
        _selectedOpt = null;
        _revealed    = false;
        _elim        = {};
      });
      _transCtrl.forward();
      _timerCtrl.forward(from: 0.0);
      _startTimerAudio();
    });
  }

  void _onSkip() {
    if (_revealed || _skipsLeft <= 0 || _cur.skippedOnce) return;
    if (_currentPos >= _queue.length - 1) return;
    _stopTimerAudio();
    setState(() {
      _skipsLeft--;
      _cur.skippedOnce = true;
    });
    final q = _queue.removeAt(_currentPos);
    _queue.add(q);
    _transCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() { _selectedOpt = null; _revealed = false; _elim = {}; });
      _transCtrl.forward();
      _timerCtrl.forward(from: 0.0);
      _startTimerAudio();
    });
  }

  void _onHint() {
    if (_revealed || _hintsLeft <= 0 || _elim.isNotEmpty) return;
    final wrong = List.generate(4, (i) => i)
      ..removeWhere((i) => i == _cur.correctIdx)
      ..shuffle();
    setState(() { _hintsLeft--; _elim = {wrong[0], wrong[1]}; });
  }

  Future<void> _finishExam() async {
    _stopTimerAudio();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_games',   (prefs.getInt('total_games')   ?? 0) + 1);
    await prefs.setInt('total_correct', (prefs.getInt('total_correct') ?? 0) + _correct);
    await prefs.setInt('total_wrong',   (prefs.getInt('total_wrong')   ?? 0) + _wrong);
    final ch = prefs.getStringList('correct_history') ?? [];
    final wh = prefs.getStringList('wrong_history')   ?? [];
    await prefs.setStringList('correct_history', ch..add('$_correct'));
    await prefs.setStringList('wrong_history',   wh..add('$_wrong'));
    const accuracyKeys = [
      'teorica_geral_best_accuracy',
      'documentos_tecnicos_best_accuracy',
      'tratamento_termico_best_accuracy',
      'dureza_best_accuracy',
    ];
    if (widget.examIndex < accuracyKeys.length) {
      final acc  = _totalQ > 0 ? _correct / _totalQ * 100 : 0.0;
      final key  = accuracyKeys[widget.examIndex];
      final best = prefs.getDouble(key) ?? 0.0;
      if (acc > best) await prefs.setDouble(key, acc);
    }
    await _clearSavedState();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => ResultScreen(
        examName:  widget.examName,
        correct:   _correct,
        wrong:     _wrong,
        total:     _totalQ,
        examIndex: widget.examIndex,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  void _startTimerAudio() {
    _bgPlayer.stop().catchError((_) {});
    final token = ++_bgStartToken;
    Future.delayed(const Duration(seconds: 10), () async {
      if (!mounted || _bgStartToken != token) return;
      try {
        await _bgPlayer.stop();
        await _bgPlayer.setVolume(0.65);
        await _bgPlayer.play(AssetSource('sounds/time.mp3'));
      } catch (_) {}
    });
  }

  void _stopTimerAudio() {
    _bgStartToken++;
    _bgPlayer.stop().catchError((_) {});
  }

  Future<void> _playAnswerSound(bool correct) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(
          correct ? 'sounds/acertou.mp3' : 'sounds/errou.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _bgStartToken++;
    _bgPlayer.dispose();
    _sfxPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _transCtrl.dispose();
    _timerCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFC8870A), strokeWidth: 2))
            : Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 8),
                  _buildProgressRow(),
                  const SizedBox(height: 14),
                  _buildLifelines(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _transCtrl,
                      builder: (_, child) => Opacity(
                        opacity: _fade.value,
                        child: Transform.translate(
                            offset: Offset(0, _slide.value), child: child),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuestionCard(),
                            const SizedBox(height: 12),
                            _buildOption(0),
                            const SizedBox(height: 8),
                            _buildOption(1),
                            const SizedBox(height: 8),
                            _buildOption(2),
                            const SizedBox(height: 8),
                            _buildOption(3),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showQuitSheet,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF161616),
                border: Border.all(color: const Color(0xFF272727)),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFF666666), size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.examName.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFC8870A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Score inline — sem container pesado
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50), size: 14),
              const SizedBox(width: 5),
              Text('$_correct',
                  style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 15,
                      fontWeight: FontWeight.w900)),
              Container(
                  width: 1,
                  height: 13,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: const Color(0xFF252525)),
              const Icon(Icons.cancel_rounded,
                  color: Color(0xFFE53935), size: 14),
              const SizedBox(width: 5),
              Text('$_wrong',
                  style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 15,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progress row ──────────────────────────────────────────────────────────

  Widget _buildProgressRow() {
    final val = _totalQ == 0 ? 0.0 : _answered / _totalQ;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTimerRing(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Questão ${_currentPos + 1} de ${_queue.length}',
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(_answered / (_totalQ == 0 ? 1 : _totalQ) * 100).toInt()}%',
                      style: const TextStyle(
                        color: Color(0xFF3A3A3A),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: val,
                    backgroundColor: const Color(0xFF1A1A1A),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFC8870A)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerRing() {
    return AnimatedBuilder(
      animation: _timerCtrl,
      builder: (_, __) {
        final remaining = ((1 - _timerCtrl.value) * 40).ceil();
        final color = remaining > 20
            ? const Color(0xFF4CAF50)
            : remaining > 10
                ? const Color(0xFFFFB300)
                : const Color(0xFFE53935);
        return SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 1 - _timerCtrl.value,
                backgroundColor: const Color(0xFF1E1E1E),
                valueColor: AlwaysStoppedAnimation(color),
                strokeWidth: 3.5,
              ),
              Text(
                '$remaining',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Lifelines ─────────────────────────────────────────────────────────────

  Widget _buildLifelines() {
    final canHint = _hintsLeft > 0 && !_revealed && _elim.isEmpty;
    final canSkip = _skipsLeft > 0 && !_revealed && !_cur.skippedOnce &&
        _currentPos < _queue.length - 1;
    final accuracy = _answered == 0 ? -1.0 : _correct / _answered * 100;
    final accColor = accuracy < 0
        ? const Color(0xFF333333)
        : accuracy >= 60
            ? const Color(0xFF4CAF50)
            : const Color(0xFFE53935);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _lifelineChip(
            icon: Icons.lightbulb_rounded,
            label: 'DICA',
            left: _hintsLeft,
            total: 3,
            color: const Color(0xFFFFB300),
            active: canHint,
            onTap: _onHint,
          ),
          const SizedBox(width: 8),
          _lifelineChip(
            icon: Icons.fast_forward_rounded,
            label: 'PULAR',
            left: _skipsLeft,
            total: 3,
            color: const Color(0xFF42A5F5),
            active: canSkip,
            onTap: _onSkip,
          ),
          const Spacer(),
          // Precisão
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF0F0F0F),
              border: Border.all(
                color: accuracy < 0
                    ? const Color(0xFF1E1E1E)
                    : accColor.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  accuracy < 0 ? '–' : '${accuracy.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: accColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'precisão',
                  style: TextStyle(
                    color: accuracy < 0
                        ? const Color(0xFF333333)
                        : accColor.withValues(alpha: 0.55),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lifelineChip({
    required IconData icon,
    required String label,
    required int left,
    required int total,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active ? color.withValues(alpha: 0.08) : const Color(0xFF0D0D0D),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.40) : const Color(0xFF181818),
            width: 1.5,
          ),
          boxShadow: active
              ? [BoxShadow(
                  color: color.withValues(alpha: 0.10),
                  blurRadius: 10, spreadRadius: 1)]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? color : const Color(0xFF2A2A2A), size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: active ? color : const Color(0xFF2A2A2A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(total, (i) => Container(
                    width: 5,
                    height: 5,
                    margin: EdgeInsets.only(right: i < total - 1 ? 3 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < left
                          ? (active ? color : const Color(0xFF252525))
                          : (active
                              ? color.withValues(alpha: 0.15)
                              : const Color(0xFF161616)),
                    ),
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Question card ─────────────────────────────────────────────────────────

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF0D0D0D),
        border: Border.all(
          color: const Color(0xFFC8870A).withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC8870A).withValues(alpha: 0.05),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tag(_cur.source.group, const Color(0xFFC8870A)),
              if (_elim.isNotEmpty) ...[
                const SizedBox(width: 6),
                _tag('50:50', const Color(0xFFFFB300)),
              ],
              if (_cur.skippedOnce) ...[
                const SizedBox(width: 6),
                _tag('pulada', const Color(0xFF42A5F5)),
              ],
              const Spacer(),
              Text(
                '${_currentPos + 1}/${_queue.length}',
                style: const TextStyle(
                  color: Color(0xFF383838),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _cur.source.text,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 14,
              height: 1.70,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          )),
    );
  }

  // ── Option card ───────────────────────────────────────────────────────────

  Widget _buildOption(int idx) {
    final letter    = String.fromCharCode(65 + idx);
    final isCorrect = idx == _cur.correctIdx;
    final isChosen  = _selectedOpt == idx;
    final isElim    = _elim.contains(idx);

    Color borderColor = const Color(0xFF1E1E1E);
    Color bgColor     = const Color(0xFF0F0F0F);
    Color textColor   = const Color(0xFF999999);
    Color tagBg       = const Color(0xFF181818);
    Color tagColor    = const Color(0xFF444444);

    if (_revealed) {
      if (isCorrect) {
        borderColor = const Color(0xFF4CAF50).withValues(alpha: 0.65);
        bgColor     = const Color(0xFF4CAF50).withValues(alpha: 0.07);
        textColor   = const Color(0xFF66BB6A);
        tagBg       = const Color(0xFF4CAF50).withValues(alpha: 0.20);
        tagColor    = const Color(0xFF4CAF50);
      } else if (isChosen) {
        borderColor = const Color(0xFFE53935).withValues(alpha: 0.65);
        bgColor     = const Color(0xFFE53935).withValues(alpha: 0.07);
        textColor   = const Color(0xFFEF5350);
        tagBg       = const Color(0xFFE53935).withValues(alpha: 0.20);
        tagColor    = const Color(0xFFE53935);
      }
    } else if (isElim) {
      borderColor = const Color(0xFF141414);
      bgColor     = const Color(0xFF080808);
      textColor   = const Color(0xFF222222);
      tagBg       = const Color(0xFF0F0F0F);
      tagColor    = const Color(0xFF222222);
    }

    return GestureDetector(
      onTap: (!_revealed && !isElim) ? () => _onOptionTap(idx) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: (_revealed && isCorrect)
              ? [BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                  blurRadius: 14, spreadRadius: 1)]
              : (_revealed && isChosen && !isCorrect)
                  ? [BoxShadow(
                      color: const Color(0xFFE53935).withValues(alpha: 0.15),
                      blurRadius: 14, spreadRadius: 1)]
                  : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Letter badge
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: tagBg,
                border: Border.all(
                  color: _revealed && isCorrect
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.40)
                      : _revealed && isChosen && !isCorrect
                          ? const Color(0xFFE53935).withValues(alpha: 0.40)
                          : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(letter,
                    style: TextStyle(
                        color: tagColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            // Option text — wraps freely
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  isElim ? '—' : _cur.opts[idx],
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    height: 1.50,
                    fontWeight: FontWeight.w500,
                    decoration: isElim ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFF282828),
                  ),
                ),
              ),
            ),
            // Result icon
            if (_revealed && isCorrect)
              const Padding(
                padding: EdgeInsets.only(left: 10, top: 4),
                child: Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50), size: 20),
              ),
            if (_revealed && isChosen && !isCorrect)
              const Padding(
                padding: EdgeInsets.only(left: 10, top: 4),
                child: Icon(Icons.cancel_rounded,
                    color: Color(0xFFE53935), size: 20),
              ),
          ],
        ),
      ),
    );
  }

  // ── Quit sheet ────────────────────────────────────────────────────────────

  void _showQuitSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF131313),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: const Color(0xFF333333),
              ),
            ),
            const Text('Pausar prova?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Questão ${_currentPos + 1} de ${_queue.length} • '
              '$_correct acerto${_correct != 1 ? 's' : ''}',
              style: const TextStyle(color: Color(0xFF555555), fontSize: 12),
            ),
            const SizedBox(height: 22),
            // Salvar e sair
            GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
                await _saveStateToPrefs();
                if (mounted) Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDFA030), Color(0xFFC8870A), Color(0xFF8A5E06)],
                  ),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFFC8870A).withValues(alpha: 0.28),
                    blurRadius: 14, offset: const Offset(0, 4),
                  )],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_rounded, color: Color(0xFF0A0A0A), size: 18),
                    SizedBox(width: 8),
                    Text('SALVAR E SAIR',
                        style: TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Abandonar
            GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
                await _clearSavedState();
                if (mounted) Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF1A1A1A),
                  border: Border.all(
                    color: const Color(0xFFE53935).withValues(alpha: 0.40)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFE53935), size: 18),
                    SizedBox(width: 8),
                    Text('ABANDONAR PROVA',
                        style: TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Continuar
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF111111),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: const Text('CONTINUAR JOGANDO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
