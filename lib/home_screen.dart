import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quiz_screen.dart';
import 'rules_screen.dart';

// XP = total de respostas corretas
const _kLevels = [
  {'title': 'Novato',        'minXp': 0},
  {'title': 'Aprendiz',      'minXp': 15},
  {'title': 'Técnico',       'minXp': 40},
  {'title': 'Inspetor Jr.',  'minXp': 80},
  {'title': 'Inspetor',      'minXp': 150},
  {'title': 'Inspetor Sr.',  'minXp': 280},
  {'title': 'Especialista',  'minXp': 500},
  {'title': 'Mestre',        'minXp': 800},
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _fade;
  late Animation<double> _slideTop;
  late Animation<double> _slideBottom;

  String _playerName = '';
  int _selectedExam = 0;
  int _totalGames = 0;
  int _totalCorrect = 0;
  int _totalWrong = 0;
  // Best accuracy per exam (same order as _examTypes)
  final List<double> _examBestAccuracy = [0, 0, 0, 0];
  // Whether a mid-game save exists for each exam
  final List<bool> _hasSavedExam = [false, false, false, false];

  final List<Map<String, dynamic>> _examTypes = [
    {'name': 'Teórica Geral',       'icon': Icons.school_outlined},
    {'name': 'Documentos Técnicos', 'icon': Icons.description_outlined},
    {'name': 'Tratamento Térmico',  'icon': Icons.local_fire_department_outlined},
    {'name': 'Dureza',              'icon': Icons.hardware_outlined},
  ];

  List<Map<String, dynamic>> get _achievements => [
    {
      'icon': Icons.star_rounded,
      'label': '1ª Prova',
      'unlocked': _totalGames >= 1,
      'color': const Color(0xFFFFD700),
    },
    {
      'icon': Icons.local_fire_department_rounded,
      'label': '10 Acertos',
      'unlocked': _totalCorrect >= 10,
      'color': const Color(0xFFFF6B35),
    },
    {
      'icon': Icons.gps_fixed_rounded,
      'label': 'Precisão 80%',
      'unlocked': _accuracy >= 80 && _totalGames >= 3,
      'color': const Color(0xFF00BCD4),
    },
    {
      'icon': Icons.military_tech_rounded,
      'label': '20 Provas',
      'unlocked': _totalGames >= 20,
      'color': const Color(0xFF9C27B0),
    },
    {
      'icon': Icons.emoji_events_rounded,
      'label': 'Mestre',
      'unlocked': _totalCorrect >= 800,
      'color': const Color(0xFFC8870A),
    },
  ];

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _slideTop = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)),
    );
    _slideBottom = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _playerName   = prefs.getString('player_name') ?? '';
        _totalGames   = prefs.getInt('total_games') ?? 0;
        _totalCorrect = prefs.getInt('total_correct') ?? 0;
        _totalWrong   = prefs.getInt('total_wrong') ?? 0;
        _examBestAccuracy[0] = prefs.getDouble('teorica_geral_best_accuracy')       ?? 0;
        _examBestAccuracy[1] = prefs.getDouble('documentos_tecnicos_best_accuracy') ?? 0;
        _examBestAccuracy[2] = prefs.getDouble('tratamento_termico_best_accuracy')  ?? 0;
        _examBestAccuracy[3] = prefs.getDouble('dureza_best_accuracy')              ?? 0;
        for (int i = 0; i < 4; i++) {
          _hasSavedExam[i] = prefs.containsKey('saved_exam_$i');
        }
      });
      _entranceCtrl.forward();
    }
  }

  double get _accuracy {
    final total = _totalCorrect + _totalWrong;
    return total == 0 ? 0 : _totalCorrect / total * 100;
  }

  Future<void> _refreshStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _totalGames   = prefs.getInt('total_games')   ?? 0;
      _totalCorrect = prefs.getInt('total_correct') ?? 0;
      _totalWrong   = prefs.getInt('total_wrong')   ?? 0;
      _examBestAccuracy[0] = prefs.getDouble('teorica_geral_best_accuracy')       ?? 0;
      _examBestAccuracy[1] = prefs.getDouble('documentos_tecnicos_best_accuracy') ?? 0;
      _examBestAccuracy[2] = prefs.getDouble('tratamento_termico_best_accuracy')  ?? 0;
      _examBestAccuracy[3] = prefs.getDouble('dureza_best_accuracy')              ?? 0;
      for (int i = 0; i < 4; i++) {
        _hasSavedExam[i] = prefs.containsKey('saved_exam_$i');
      }
    });
  }

  // Each exam requires 80% in the previous one
  bool _isExamUnlocked(int index) =>
      index == 0 || _examBestAccuracy[index - 1] >= 80;

  int get _levelIndex {
    for (int i = _kLevels.length - 1; i >= 0; i--) {
      if (_totalCorrect >= (_kLevels[i]['minXp'] as int)) return i;
    }
    return 0;
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _entranceCtrl,
          builder: (context, child) => Opacity(opacity: _fade.value, child: child),
          child: Column(
            children: [
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _entranceCtrl,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideTop.value), child: child!),
                child: _buildHeader(),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _entranceCtrl,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideTop.value * 0.5), child: child!),
                child: _buildExamGrid(),
              ),
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _entranceCtrl,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideBottom.value), child: child!),
                child: _buildLevelCard(),
              ),
              const Spacer(flex: 1),
              AnimatedBuilder(
                animation: _entranceCtrl,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideBottom.value), child: child!),
                child: _buildAchievements(),
              ),
              const Spacer(flex: 1),
              AnimatedBuilder(
                animation: _entranceCtrl,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideBottom.value), child: child!),
                child: _buildStatsBar(),
              ),
              const Spacer(flex: 1),
              AnimatedBuilder(
                animation: _entranceCtrl,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideBottom.value), child: child!),
                child: _buildBottomActions(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            height: 64,
            width: 64,
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 38, color: const Color(0xFF222222)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BEM-VINDO DE VOLTA',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _playerName.isEmpty ? 'Inspetor' : _playerName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC8870A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
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

  // ── Exam grid ──────────────────────────────────────────────────────────────

  Widget _buildExamGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECIONE A MODALIDADE',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildExamCard(0)),
              const SizedBox(width: 10),
              Expanded(child: _buildExamCard(1)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildExamCard(2)),
              const SizedBox(width: 10),
              Expanded(child: _buildExamCard(3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(int index) {
    final exam       = _examTypes[index];
    final isSelected = _selectedExam == index;
    final unlocked   = _isExamUnlocked(index);

    return GestureDetector(
      onTap: unlocked
          ? () => setState(() => _selectedExam = index)
          : () => _showLockedSheet(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: unlocked
              ? (isSelected
                  ? const Color(0xFFC8870A).withValues(alpha: 0.11)
                  : const Color(0xFF111111))
              : const Color(0xFF0D0D0D),
          border: Border.all(
            color: unlocked
                ? (isSelected
                    ? const Color(0xFFC8870A).withValues(alpha: 0.65)
                    : const Color(0xFF1E1E1E))
                : const Color(0xFF191919),
            width: 1.5,
          ),
          boxShadow: (unlocked && isSelected)
              ? [BoxShadow(
                  color: const Color(0xFFC8870A).withValues(alpha: 0.14),
                  blurRadius: 16, spreadRadius: 2)]
              : [],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  exam['icon'] as IconData,
                  color: unlocked
                      ? (isSelected
                          ? const Color(0xFFC8870A)
                          : const Color(0xFF3A3A3A))
                      : const Color(0xFF252525),
                  size: 26,
                ),
                const SizedBox(height: 10),
                Text(
                  exam['name'] as String,
                  style: TextStyle(
                    color: unlocked
                        ? (isSelected ? Colors.white : const Color(0xFF555555))
                        : const Color(0xFF2E2E2E),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            if (!unlocked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF444444),
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLockedSheet(BuildContext context, int lockedIndex) {
    final prereqName = _examTypes[lockedIndex - 1]['name'] as String;
    final prereqAcc  = _examBestAccuracy[lockedIndex - 1];
    final color      = prereqAcc >= 80
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE53935);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF131313),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE53935).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFFE53935).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.lock_rounded,
                  color: Color(0xFFE53935), size: 28),
            ),
            const SizedBox(height: 18),
            const Text(
              'PROVA BLOQUEADA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Complete "$prereqName" com pelo menos\n80% de precisão para desbloquear\nesta modalidade.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 13,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF0D0D0D),
                border: Border.all(color: const Color(0xFF222222), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        prereqName,
                        style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                      ),
                      Text(
                        '${prereqAcc.toStringAsFixed(0)}% / 80%',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (prereqAcc / 80).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFF1E1E1E),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF1C1C1C),
                  border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
                ),
                child: const Text(
                  'ENTENDI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Level card ─────────────────────────────────────────────────────────────

  Widget _buildLevelCard() {
    final idx     = _levelIndex;
    final isMax   = idx == _kLevels.length - 1;
    final current = _kLevels[idx];
    final next    = isMax ? null : _kLevels[idx + 1];
    final progress = isMax
        ? 1.0
        : (_totalCorrect - (current['minXp'] as int)) /
          ((next!['minXp'] as int) - (current['minXp'] as int));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF111111),
          border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFC8870A).withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.military_tech_rounded,
                      color: Color(0xFFC8870A), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!isMax)
                        Text(
                          'Próximo: ${next!['title']}',
                          style: const TextStyle(
                              color: Color(0xFF444444), fontSize: 10),
                        ),
                    ],
                  ),
                ),
                Text(
                  '$_totalCorrect XP',
                  style: const TextStyle(
                    color: Color(0xFFC8870A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFF1E1E1E),
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFFC8870A)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Achievements ──────────────────────────────────────────────────────────

  Widget _buildAchievements() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONQUISTAS',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _achievements.map((a) {
              final unlocked = a['unlocked'] as bool;
              final color    = a['color'] as Color;
              return Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked
                          ? color.withValues(alpha: 0.15)
                          : const Color(0xFF111111),
                      border: Border.all(
                        color: unlocked
                            ? color.withValues(alpha: 0.55)
                            : const Color(0xFF1E1E1E),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      a['icon'] as IconData,
                      color: unlocked ? color : const Color(0xFF2A2A2A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    a['label'] as String,
                    style: TextStyle(
                      color: unlocked
                          ? const Color(0xFF777777)
                          : const Color(0xFF2E2E2E),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Stats bar ──────────────────────────────────────────────────────────────

  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF111111),
          border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
        ),
        child: Row(
          children: [
            Expanded(child: _buildStatItem('$_totalGames',   'Provas',  const Color(0xFFC8870A))),
            _buildDivider(),
            Expanded(child: _buildStatItem('$_totalCorrect', 'Acertos', const Color(0xFF4CAF50))),
            _buildDivider(),
            Expanded(child: _buildStatItem('$_totalWrong',   'Erros',   const Color(0xFFE53935))),
            _buildDivider(),
            Expanded(child: _buildStatItem(
              '${_accuracy.toStringAsFixed(0)}%',
              'Precisão',
              _accuracy >= 60 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildDivider() =>
      Container(width: 1, height: 28, color: const Color(0xFF1E1E1E));

  // ── Bottom actions ─────────────────────────────────────────────────────────

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildPlayButton(context),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildActionButton(
                Icons.menu_book_outlined, 'Regras', () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const RulesScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                ))),
              const SizedBox(width: 10),
              Expanded(child: _buildActionButton(
                Icons.person_outline, 'Perfil', _onEditName)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    final hasResume = _hasSavedExam[_selectedExam] && _isExamUnlocked(_selectedExam);
    return _PressableButton(
      onTap: () async {
        await Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (_, __, ___) => QuizScreen(
            examName: _examTypes[_selectedExam]['name'] as String,
            examIndex: _selectedExam,
          ),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: FadeTransition(opacity: anim, child: child),
          ),
          transitionDuration: const Duration(milliseconds: 380),
        ));
        _refreshStats();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDFA030), Color(0xFFC8870A), Color(0xFF8A5E06)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC8870A).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasResume ? Icons.bookmark_rounded : Icons.play_arrow_rounded,
              color: const Color(0xFF0A0A0A), size: 26),
            const SizedBox(width: 8),
            Text(
              hasResume ? 'CONTINUAR' : 'JOGAR',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A0A0A),
                  letterSpacing: 5)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF111111),
          border: Border.all(color: const Color(0xFF222222), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFC8870A), size: 17),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _onEditName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('player_name');
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// ── Pressable button ──────────────────────────────────────────────────────────

class _PressableButton extends StatefulWidget {
  const _PressableButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
