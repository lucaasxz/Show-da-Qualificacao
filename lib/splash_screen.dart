import 'dart:math';
import 'package:flutter/material.dart';
import 'loading_screen.dart';

// ── Spark particle ─────────────────────────────────────────────────────────────
class _Spark {
  double x, y, vx, vy, life, size;
  Color color;
  _Spark({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.size, required this.color,
  }) : life = 1.0;
}

// ── SplashScreen ──────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _welderCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _exitCtrl;
  late final AnimationController _buttonCtrl;
  late final AnimationController _sparkTick;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _welderSlide;
  late final Animation<double> _textReveal;
  late final Animation<double> _welderExit;
  late final Animation<double> _buttonFade;
  late final Animation<double> _buttonSlide;

  final _sparks = <_Spark>[];
  final _rng = Random();
  Offset _torchTip = Offset.zero;
  bool _welding = false;

  static const _fullText = 'O jogo da inspeção';
  static const _textStyle = TextStyle(
    color: Color(0xFFC8870A),
    fontSize: 21,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );
  static const _sparkColors = [
    Color(0xFFFF8C00), Color(0xFFFFCC00),
    Color(0xFFFF4500), Color(0xFFFFFFCC),
  ];

  @override
  void initState() {
    super.initState();
    _logoCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _welderCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _textCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 2700));
    _exitCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _buttonCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _sparkTick  = AnimationController(vsync: this, duration: const Duration(seconds: 100))..repeat();

    _logoFade    = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _logoScale   = Tween<double>(begin: 0.82, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _welderSlide = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _welderCtrl, curve: Curves.easeOut));
    _textReveal  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.linear));
    _welderExit  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
    _buttonFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeOut));
    _buttonSlide = Tween<double>(begin: 24, end: 0).animate(CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeOut));

    _sparkTick.addListener(_tickSparks);
    _startSequence();
  }

  Future<void> _startSequence() async {
    await _logoCtrl.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _welderCtrl.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _welding = true);
    await _textCtrl.forward();
    if (!mounted) return;
    setState(() => _welding = false);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _exitCtrl.forward();
    if (!mounted) return;
    _buttonCtrl.forward();
  }

  void _tickSparks() {
    const dt = 0.016;
    for (final s in _sparks) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vy += 480 * dt;
      s.life -= dt * 3.2;
    }
    _sparks.removeWhere((s) => s.life <= 0);

    if (_welding && _sparks.length < 80) {
      final count = 2 + _rng.nextInt(3);
      for (int i = 0; i < count; i++) {
        final angle = -pi * 0.85 + _rng.nextDouble() * pi * 1.2;
        final speed = 55.0 + _rng.nextDouble() * 150;
        _sparks.add(_Spark(
          x: _torchTip.dx,
          y: _torchTip.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 1.3 + _rng.nextDouble() * 2.4,
          color: _sparkColors[_rng.nextInt(_sparkColors.length)],
        ));
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _logoCtrl.dispose(); _welderCtrl.dispose(); _textCtrl.dispose();
    _exitCtrl.dispose(); _buttonCtrl.dispose(); _sparkTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF161616), Color(0xFF0A0A0A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo ──────────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _logoCtrl,
                builder: (context, child) => Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(scale: _logoScale.value, child: child),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 24),
              // ── Welding text section ───────────────────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge([_welderCtrl, _textCtrl, _exitCtrl]),
                builder: (context, _) {
                  final chars = (_textReveal.value * _fullText.length)
                      .floor()
                      .clamp(0, _fullText.length);
                  final welderOpacity = (1.0 - _welderExit.value).clamp(0.0, 1.0);
                  return _WeldingSection(
                    fullText: _fullText,
                    revealedText: _fullText.substring(0, chars),
                    textStyle: _textStyle,
                    sparks: List.of(_sparks),
                    isWelding: _welding,
                    welderOffset: _welderSlide.value + _welderExit.value,
                    welderOpacity: welderOpacity,
                    welderVisible: _welderCtrl.value > 0 && welderOpacity > 0.01,
                    onTorchMoved: (offset) { _torchTip = offset; },
                  );
                },
              ),
              const SizedBox(height: 44),
              // ── Button ────────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _buttonCtrl,
                builder: (context, child) => Opacity(
                  opacity: _buttonFade.value,
                  child: Transform.translate(
                    offset: Offset(0, _buttonSlide.value),
                    child: child,
                  ),
                ),
                child: _buildButton(context),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _buttonCtrl,
                builder: (context, _) => Opacity(
                  opacity: _buttonFade.value * 0.4,
                  child: const Text('v1.0.0',
                      style: TextStyle(color: Color(0xFF555555), fontSize: 11, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return _PressableButton(
      onTap: () => Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoadingScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: Color(0xFF0A0A0A), size: 28),
            SizedBox(width: 10),
            Text('INICIAR',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0A), letterSpacing: 4)),
          ],
        ),
      ),
    );
  }
}

// ── Welding section ────────────────────────────────────────────────────────────
class _WeldingSection extends StatelessWidget {
  const _WeldingSection({
    required this.fullText,
    required this.revealedText,
    required this.textStyle,
    required this.sparks,
    required this.isWelding,
    required this.welderOffset,
    required this.welderOpacity,
    required this.welderVisible,
    required this.onTorchMoved,
  });

  final String fullText;
  final String revealedText;
  final TextStyle textStyle;
  final List<_Spark> sparks;
  final bool isWelding;
  final double welderOffset; // 0=on screen, >0=off right
  final double welderOpacity;
  final bool welderVisible;
  final void Function(Offset) onTorchMoved;

  static const _welderW = 54.0;
  static const _welderH = 60.0;
  static const _hPad = 36.0;
  static const _topSpace = 58.0;
  static const _botSpace = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final availW = constraints.maxWidth - _hPad * 2;

      final fullTP = TextPainter(
        text: TextSpan(text: fullText, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: availW);

      final revTP = TextPainter(
        text: TextSpan(text: revealedText, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: availW);

      final fullW = fullTP.width;
      final textH = fullTP.height;
      final revW = revTP.width;

      final textLeft = _hPad + (availW - fullW) / 2;
      final cursorX = textLeft + revW;
      final torchY = _topSpace + textH * 0.5;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        onTorchMoved(Offset(cursorX, torchY));
      });

      final welderLeft = cursorX + welderOffset * 160;
      final welderTop = torchY - _welderH / 2;

      return SizedBox(
        width: constraints.maxWidth,
        height: _topSpace + textH + _botSpace,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Ghost text
            Positioned(
              top: _topSpace,
              left: textLeft,
              child: Text(fullText,
                  style: textStyle.copyWith(color: const Color(0xFF282828))),
            ),
            // Revealed text
            Positioned(
              top: _topSpace,
              left: textLeft,
              child: Text(revealedText, style: textStyle),
            ),
            // Sparks
            Positioned.fill(
              child: CustomPaint(painter: _SparksPainter(sparks)),
            ),
            // Welder figure
            if (welderVisible)
              Positioned(
                left: welderLeft,
                top: welderTop,
                child: Opacity(
                  opacity: welderOpacity.clamp(0.0, 1.0),
                  child: SizedBox(
                    width: _welderW,
                    height: _welderH,
                    child: CustomPaint(painter: _WelderPainter(isWelding)),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ── Welder CustomPainter ──────────────────────────────────────────────────────
// Torch tip = (0, height/2) — body drawn to the right
class _WelderPainter extends CustomPainter {
  final bool active;
  const _WelderPainter(this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tipY = h * 0.5;

    // Torch arm
    canvas.drawLine(
      Offset(0, tipY),
      Offset(w * 0.44, h * 0.65),
      Paint()
        ..color = const Color(0xFF999999)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.42, w * 0.58, h * 0.43),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF383838),
    );

    // Welding helmet
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.06, w * 0.65, h * 0.37),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF222222),
    );

    // Visor slit
    canvas.drawRect(
      Rect.fromLTWH(w * 0.40, h * 0.18, w * 0.50, h * 0.12),
      Paint()..color = const Color(0xFFC8870A).withValues(alpha: active ? 0.95 : 0.50),
    );

    // Arc flash glow at torch tip
    if (active) {
      canvas.drawCircle(
        Offset(0, tipY),
        7,
        Paint()
          ..color = const Color(0xFF55CCFF).withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(Offset(0, tipY), 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_WelderPainter old) => old.active != active;
}

// ── Sparks CustomPainter ──────────────────────────────────────────────────────
class _SparksPainter extends CustomPainter {
  final List<_Spark> sparks;
  const _SparksPainter(this.sparks);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      if (s.life <= 0) continue;
      final alpha = (s.life * 1.4).clamp(0.0, 1.0);
      final speed = sqrt(s.vx * s.vx + s.vy * s.vy).clamp(1.0, 1000.0);
      final tailLen = (speed * 0.011).clamp(2.0, 9.0);
      final nx = s.vx / speed;
      final ny = s.vy / speed;

      canvas.drawLine(
        Offset(s.x, s.y),
        Offset(s.x - nx * tailLen, s.y - ny * tailLen),
        Paint()
          ..color = s.color.withValues(alpha: alpha)
          ..strokeWidth = s.size
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(s.x, s.y),
        s.size * 0.5,
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.65),
      );
    }
  }

  @override
  bool shouldRepaint(_SparksPainter _) => true;
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
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
