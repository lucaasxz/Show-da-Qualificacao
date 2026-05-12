import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatefulWidget {
  final String examName;
  final int correct;
  final int wrong;
  final int total;
  final int examIndex;

  const ResultScreen({
    super.key,
    required this.examName,
    required this.correct,
    required this.wrong,
    required this.total,
    required this.examIndex,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.80, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.elasticOut)));
    _slide = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  double get _accuracy =>
      widget.total == 0 ? 0 : widget.correct / widget.total * 100;

  bool get _passed => _accuracy >= 80;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Opacity(opacity: _fade.value, child: child),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, child) =>
                      Transform.scale(scale: _scale.value, child: child),
                  child: _buildScoreCircle(),
                ),
                const SizedBox(height: 28),
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, child) => Transform.translate(
                      offset: Offset(0, _slide.value), child: child!),
                  child: Column(
                    children: [
                      _buildPassBadge(),
                      const SizedBox(height: 28),
                      _buildBreakdown(),
                      const SizedBox(height: 20),
                      _buildXpCard(),
                      const SizedBox(height: 32),
                      _buildActions(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Score circle ────────────────────────────────────────────────────────────

  Widget _buildScoreCircle() {
    final pct = _accuracy;
    final color = _passed ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              strokeWidth: 10,
              backgroundColor: const Color(0xFF1E1E1E),
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: color.withValues(alpha: 0.50), blurRadius: 20)],
                ),
              ),
              Text(
                'de acerto',
                style: const TextStyle(color: Color(0xFF555555), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pass / fail badge ───────────────────────────────────────────────────────

  Widget _buildPassBadge() {
    final color = _passed ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    final icon  = _passed ? Icons.emoji_events_rounded : Icons.replay_rounded;
    final label = _passed ? 'APROVADO' : 'REPROVADO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.40), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Breakdown cards ─────────────────────────────────────────────────────────

  Widget _buildBreakdown() {
    return Row(
      children: [
        Expanded(child: _statCard('${widget.correct}', 'ACERTOS', const Color(0xFF4CAF50))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('${widget.wrong}',   'ERROS',   const Color(0xFFE53935))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('${widget.total}',   'TOTAL',   const Color(0xFFC8870A))),
      ],
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: color.withValues(alpha: 0.45), blurRadius: 10)])),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
        ],
      ),
    );
  }

  // ── XP card ─────────────────────────────────────────────────────────────────

  Widget _buildXpCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC8870A).withValues(alpha: 0.14),
            ),
            child: const Icon(Icons.military_tech_rounded,
                color: Color(0xFFC8870A), size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('XP GANHO',
                  style: TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
              const SizedBox(height: 3),
              Text(
                '+${widget.correct} XP',
                style: const TextStyle(
                  color: Color(0xFFC8870A),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            widget.examName,
            style: const TextStyle(
                color: Color(0xFF444444), fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        _btn(
          label: 'JOGAR NOVAMENTE',
          icon: Icons.replay_rounded,
          gradient: const [Color(0xFFDFA030), Color(0xFFC8870A), Color(0xFF8A5E06)],
          textColor: const Color(0xFF0A0A0A),
          onTap: () => Navigator.of(context).pushReplacement(PageRouteBuilder(
            pageBuilder: (_, __, ___) => QuizScreen(
                examName: widget.examName, examIndex: widget.examIndex),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          )),
        ),
        const SizedBox(height: 10),
        _btn(
          label: 'VOLTAR AO INÍCIO',
          icon: Icons.home_rounded,
          gradient: const [Color(0xFF1C1C1C), Color(0xFF161616)],
          textColor: Colors.white,
          borderColor: const Color(0xFF2A2A2A),
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HomeScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
            (_) => false,
          ),
        ),
      ],
    );
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1)
              : null,
          boxShadow: gradient.first == const Color(0xFFDFA030)
              ? [BoxShadow(
                  color: const Color(0xFFC8870A).withValues(alpha: 0.30),
                  blurRadius: 16, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5)),
          ],
        ),
      ),
    );
  }
}
