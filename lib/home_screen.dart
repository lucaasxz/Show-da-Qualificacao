import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'statistics_screen.dart';

class _Spark {
  Offset pos;
  Offset vel;
  double life;
  final Color color;
  final double size;

  _Spark({required this.pos, required this.vel, required this.color, required this.size})
      : life = 1.0;
}

const _sparkColors = [
  Color(0xFFFF8C00),
  Color(0xFFFFCC00),
  Color(0xFFFF4500),
  Color(0xFFFFFFCC),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _fade;
  late Animation<double> _slideLogo;
  late Animation<double> _slideGreeting;
  late Animation<double> _slideButtons;

  String _playerName = '';

  final List<Map<String, dynamic>> _examTypes = [
    {'name': 'Teórica Geral',        'icon': Icons.school_outlined},
    {'name': 'Documentos Técnicos',  'icon': Icons.description_outlined},
    {'name': 'Tratamento Térmico',   'icon': Icons.local_fire_department_outlined},
    {'name': 'Dureza',               'icon': Icons.hardware_outlined},
  ];
  int _selectedExam = 0;
  bool _slideFromRight = true;

  final _rng = Random();
  final List<_Spark> _sparks = [];
  late Ticker _sparkTicker;
  Duration _lastTickTime = Duration.zero;
  Timer? _burstTimer;
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0, 0.5, curve: Curves.easeOut)),
    );
    _slideLogo = Tween<double>(begin: -24, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _slideGreeting = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.2, 0.75, curve: Curves.easeOut)),
    );
    _slideButtons = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.4, 1, curve: Curves.easeOut)),
    );

    _sparkTicker = createTicker(_onSparkTick)..start();
    _scheduleBurst();
    _loadName();
  }

  void _scheduleBurst() {
    final delay = 2500 + _rng.nextInt(3000);
    _burstTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        _spawnBurst();
        _scheduleBurst();
      }
    });
  }

  void _spawnBurst() {
    if (_screenSize == Size.zero) return;
    final side = _rng.nextInt(3);
    final Offset origin;
    switch (side) {
      case 0:
        origin = Offset(
          _rng.nextDouble() * _screenSize.width * 0.25,
          _screenSize.height * (0.55 + _rng.nextDouble() * 0.3),
        );
        break;
      case 1:
        origin = Offset(
          _screenSize.width * 0.75 + _rng.nextDouble() * _screenSize.width * 0.25,
          _screenSize.height * (0.55 + _rng.nextDouble() * 0.3),
        );
        break;
      default:
        origin = Offset(
          _screenSize.width * 0.3 + _rng.nextDouble() * _screenSize.width * 0.4,
          _screenSize.height * (0.72 + _rng.nextDouble() * 0.15),
        );
    }

    final count = 6 + _rng.nextInt(8);
    for (int i = 0; i < count; i++) {
      final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * pi * 1.3;
      final speed = 70.0 + _rng.nextDouble() * 200;
      _sparks.add(_Spark(
        pos: origin,
        vel: Offset(cos(angle) * speed, sin(angle) * speed),
        color: _sparkColors[_rng.nextInt(_sparkColors.length)],
        size: 1.5 + _rng.nextDouble() * 2.5,
      ));
    }
  }

  void _onSparkTick(Duration elapsed) {
    if (_lastTickTime == Duration.zero) {
      _lastTickTime = elapsed;
      return;
    }
    final dt = (elapsed - _lastTickTime).inMicroseconds / 1000000.0;
    _lastTickTime = elapsed;

    const gravity = 130.0;
    _sparks.removeWhere((s) => s.life <= 0);
    for (final s in _sparks) {
      s.vel = Offset(s.vel.dx * 0.985, s.vel.dy + gravity * dt);
      s.pos += s.vel * dt;
      s.life -= dt * 0.85;
    }
    if (mounted && _sparks.isNotEmpty) setState(() {});
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _playerName = prefs.getString('player_name') ?? '');
      _entranceCtrl.forward();
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _sparkTicker.dispose();
    _burstTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF161616), Color(0xFF0A0A0A)],
              ),
            ),
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _entranceCtrl,
                builder: (context, child) => Opacity(opacity: _fade.value, child: child),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _entranceCtrl,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _slideLogo.value),
                        child: child,
                      ),
                      child: _buildLogo(),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _entranceCtrl,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _slideGreeting.value),
                        child: child,
                      ),
                      child: _buildGreeting(),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _entranceCtrl,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _slideGreeting.value),
                        child: child,
                      ),
                      child: _buildExamSelector(),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _entranceCtrl,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _slideButtons.value),
                        child: child,
                      ),
                      child: _buildMenu(context),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              size: _screenSize,
              painter: _HomeSparksPainter(_sparks),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 52),
      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
    );
  }

  Widget _buildGreeting() {
    return Column(
      children: [
        const Text(
          'Bem-vindo de volta,',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _playerName.isEmpty ? 'Inspetor' : _playerName,
          style: const TextStyle(
            color: Color(0xFFC8870A),
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  void _changeExam(int direction) {
    setState(() {
      _slideFromRight = direction > 0;
      _selectedExam = (_selectedExam + direction) % _examTypes.length;
      if (_selectedExam < 0) _selectedExam = _examTypes.length - 1;
    });
  }

  Widget _buildExamSelector() {
    final exam = _examTypes[_selectedExam];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Text(
            'SELECIONE A PROVA',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildArrow(Icons.chevron_left_rounded, () => _changeExam(-1)),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(_slideFromRight ? 0.25 : -0.25, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(_selectedExam),
                    children: [
                      const SizedBox(height: 24),
                      Icon(exam['icon'] as IconData, color: const Color(0xFFC8870A), size: 48),
                      const SizedBox(height: 14),
                      Text(
                        exam['name'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_examTypes.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _selectedExam ? 22 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i == _selectedExam
                                ? const Color(0xFFC8870A)
                                : const Color(0xFF333333),
                          ),
                        )),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildArrow(Icons.chevron_right_rounded, () => _changeExam(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
        child: Icon(icon, color: const Color(0xFF888888), size: 36),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _buildPlayButton(context),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildSecondaryButton(
                Icons.bar_chart_rounded,
                'ESTATÍSTICAS',
                () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, _) => const StatisticsScreen(),
                      transitionsBuilder: (context, animation, _, child) =>
                          FadeTransition(opacity: animation, child: child),
                      transitionDuration: const Duration(milliseconds: 350),
                    ),
                  );
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildSecondaryButton(Icons.menu_book_outlined, 'REGRAS', () {})),
              const SizedBox(width: 10),
              Expanded(child: _buildSecondaryButton(Icons.person_outline, 'PERFIL', _onEditName)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return _PressableButton(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDFA030), Color(0xFFC8870A), Color(0xFF8A5E06)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC8870A).withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Color(0xFF0A0A0A), size: 30),
            SizedBox(width: 10),
            Text(
              'JOGAR',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0A0A0A),
                letterSpacing: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF1C1C1C),
          border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFC8870A), size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
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

class _HomeSparksPainter extends CustomPainter {
  final List<_Spark> sparks;
  _HomeSparksPainter(this.sparks);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final life = s.life.clamp(0.0, 1.0);
      if (life <= 0) continue;
      final color = s.color.withValues(alpha: life);
      final tailEnd = s.pos - s.vel * 0.032;
      canvas.drawLine(
        tailEnd,
        s.pos,
        Paint()
          ..color = color
          ..strokeWidth = s.size * 0.6
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        s.pos,
        s.size * 0.55,
        Paint()..color = Colors.white.withValues(alpha: life * 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_HomeSparksPainter old) => true;
}

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
