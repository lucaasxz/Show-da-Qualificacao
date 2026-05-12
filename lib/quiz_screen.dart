import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _transCtrl;
  late Animation<double> _fade;
  late Animation<double> _slide;

  bool _loading      = true;
  bool _hasSavedState = false;
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

  @override
  void initState() {
    super.initState();
    _transCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
    _fade = CurvedAnimation(parent: _transCtrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 28, end: 0)
        .animate(CurvedAnimation(parent: _transCtrl, curve: Curves.easeOut));
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
        _hasSavedState = true;
        _loading     = false;
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

  void _onOptionTap(int idx) {
    if (_revealed || _elim.contains(idx)) return;
    setState(() {
      _selectedOpt = idx;
      _revealed    = true;
      _answered++;
      if (idx == _cur.correctIdx) _correct++; else _wrong++;
    });
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
    });
  }

  void _onSkip() {
    if (_revealed || _skipsLeft <= 0 || _cur.skippedOnce) return;
    if (_currentPos >= _queue.length - 1) return;
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transCtrl.dispose();
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF1C1C1C),
                border: Border.all(color: const Color(0xFF2E2E2E)),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFF888888), size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.examName.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFC8870A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Questão ${_currentPos + 1} de ${_queue.length}',
                  style: const TextStyle(
                      color: Color(0xFF555555), fontSize: 11),
                ),
              ],
            ),
          ),
          _buildScoreBadge(),
        ],
      ),
    );
  }

  Widget _buildScoreBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFF4CAF50), size: 15),
          const SizedBox(width: 5),
          Text('$_correct',
              style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          Container(
              width: 1, height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: const Color(0xFF2A2A2A)),
          const Icon(Icons.close_rounded, color: Color(0xFFE53935), size: 15),
          const SizedBox(width: 5),
          Text('$_wrong',
              style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ── Progress row ──────────────────────────────────────────────────────────

  Widget _buildProgressRow() {
    final val = _totalQ == 0 ? 0.0 : _answered / _totalQ;
    final pct = (val * 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: val,
                backgroundColor: const Color(0xFF1A1A1A),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFC8870A)),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '$pct%',
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lifelines ─────────────────────────────────────────────────────────────

  Widget _buildLifelines() {
    final canHint = _hintsLeft > 0 && !_revealed && _elim.isEmpty;
    final canSkip = _skipsLeft > 0 && !_revealed && !_cur.skippedOnce &&
        _currentPos < _queue.length - 1;
    final accuracy = _answered == 0 ? -1.0 : _correct / _answered * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _lifeline(
            icon: Icons.lightbulb_rounded,
            label: 'DICA',
            sublabel: 'Elimina 2 erradas',
            total: 3,
            left: _hintsLeft,
            color: const Color(0xFFFFB300),
            active: canHint,
            onTap: _onHint,
          ),
          const SizedBox(width: 10),
          _lifeline(
            icon: Icons.fast_forward_rounded,
            label: 'PULAR',
            sublabel: 'Próxima questão',
            total: 3,
            left: _skipsLeft,
            color: const Color(0xFF42A5F5),
            active: canSkip,
            onTap: _onSkip,
          ),
          const Spacer(),
          // Live accuracy chip
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF111111),
              border: Border.all(
                color: accuracy < 0
                    ? const Color(0xFF1E1E1E)
                    : accuracy >= 60
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.40)
                        : const Color(0xFFE53935).withValues(alpha: 0.40),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  accuracy < 0 ? '–' : '${accuracy.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: accuracy < 0
                        ? const Color(0xFF444444)
                        : accuracy >= 60
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE53935),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text('precisão',
                    style: TextStyle(
                        color: Color(0xFF444444),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lifeline({
    required IconData icon,
    required String label,
    required String sublabel,
    required int total,
    required int left,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active
              ? color.withValues(alpha: 0.09)
              : const Color(0xFF0D0D0D),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.45)
                : const Color(0xFF181818),
            width: 1.5,
          ),
          boxShadow: active
              ? [BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 12, spreadRadius: 1)]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? color.withValues(alpha: 0.16)
                    : const Color(0xFF141414),
              ),
              child: Icon(icon,
                  color: active ? color : const Color(0xFF282828), size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                      color: active ? color : const Color(0xFF2A2A2A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    )),
                const SizedBox(height: 3),
                Row(
                  children: List.generate(total, (i) => Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(right: i < total - 1 ? 3 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < left
                          ? (active ? color : const Color(0xFF2A2A2A))
                          : (active
                              ? color.withValues(alpha: 0.18)
                              : const Color(0xFF181818)),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0F0F0F),
        border: Border.all(
          color: const Color(0xFFC8870A).withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC8870A).withValues(alpha: 0.06),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags row
          Row(
            children: [
              _tag(_cur.source.group, const Color(0xFFC8870A)),
              if (_elim.isNotEmpty) ...[
                const SizedBox(width: 8),
                _tag('50:50 ativo', const Color(0xFFFFB300)),
              ],
              if (_cur.skippedOnce) ...[
                const SizedBox(width: 8),
                _tag('pulada', const Color(0xFF42A5F5)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _cur.source.text,
            style: const TextStyle(
              color: Color(0xFFE8E8E8),
              fontSize: 14,
              height: 1.65,
              fontWeight: FontWeight.w500,
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
