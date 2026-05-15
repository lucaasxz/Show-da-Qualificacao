import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

// ── Particle model ────────────────────────────────────────────────────────────

class _Particle {
  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double delay;   // stagger 0–0.25
  final bool isRect;    // confetti rectangle vs circle
  final double spin;    // initial rotation for rects

  const _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.delay,
    required this.isRect,
    required this.spin,
  });
}

List<_Particle> _buildParticles(Color accent) {
  final rng = Random();
  const palette = [
    Color(0xFFFFD700), Color(0xFFFFB300), Color(0xFFDFA030),
    Color(0xFFFFFFFF), Color(0xFFFF6B35), Color(0xFFFFF176),
  ];
  return List.generate(48, (i) => _Particle(
    angle:  rng.nextDouble() * pi * 2,
    speed:  60 + rng.nextDouble() * 180,
    color:  i % 5 == 0 ? accent : palette[rng.nextInt(palette.length)],
    size:   2.5 + rng.nextDouble() * 6,
    delay:  rng.nextDouble() * 0.25,
    isRect: rng.nextBool(),
    spin:   rng.nextDouble() * pi * 2,
  ));
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _BurstPainter extends CustomPainter {
  final List<_Particle> particles;
  final double burstT;    // 0–1: particle spread progress
  final double ringT;     // 0–1: ring expand (repeating)
  final Offset center;
  final Color ringColor;

  const _BurstPainter({
    required this.particles,
    required this.burstT,
    required this.ringT,
    required this.center,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Expanding rings (3 staggered)
    for (int r = 0; r < 3; r++) {
      final t = ((ringT + r / 3) % 1.0);
      final opacity = (1.0 - t) * 0.22;
      if (opacity <= 0) continue;
      canvas.drawCircle(
        center,
        44 + t * 220,
        Paint()
          ..color = ringColor.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Particles
    for (final p in particles) {
      final raw = burstT - p.delay;
      if (raw <= 0) continue;
      final t = (raw / (1 - p.delay)).clamp(0.0, 1.0);
      final opacity = (1.0 - t * t) * 0.92;
      final x = center.dx + cos(p.angle) * p.speed * t;
      final y = center.dy + sin(p.angle) * p.speed * t + 55 * t * t; // gravity

      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      if (p.isRect) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(p.spin + t * pi * 2);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero,
              width: p.size * 1.8, height: p.size * 0.55),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(x, y), p.size * (1 - t * 0.35), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) =>
      old.burstT != burstT || old.ringT != ringT;
}

// ── Overlay widget ────────────────────────────────────────────────────────────

class AchievementOverlay extends StatefulWidget {
  final Map<String, dynamic> achievement;

  const AchievementOverlay({super.key, required this.achievement});

  static Future<void> show(
      BuildContext context, Map<String, dynamic> achievement) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) =>
          AchievementOverlay(achievement: achievement),
    );
  }

  @override
  State<AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<AchievementOverlay>
    with TickerProviderStateMixin {
  // Entrance (one-shot)
  late AnimationController _entranceCtrl;
  // Burst (one-shot)
  late AnimationController _burstCtrl;
  // Idle loop
  late AnimationController _loopCtrl;

  late Animation<double> _bgFade;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;
  late Animation<double> _burstProgress;
  late Animation<double> _ringProgress;
  late Animation<double> _pulse;
  late Animation<double> _shimmer;
  late Animation<double> _sparkleFloat;

  late List<_Particle> _particles;

  Color get _color => widget.achievement['color'] as Color;

  @override
  void initState() {
    super.initState();
    _particles = _buildParticles(_color);
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _loopCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();

    // Entrance animations
    _bgFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0, 0.35, curve: Curves.easeOut)));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.20, 0.55, curve: Curves.easeOut)));
    _cardScale = Tween<double>(begin: 0.25, end: 1.0).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.20, 0.85, curve: Curves.elasticOut)));

    // Burst animations
    _burstProgress = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut));
    _ringProgress = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _burstCtrl, curve: Curves.linear));

    // Loop animations
    _pulse = Tween<double>(begin: 1.0, end: 1.14).animate(
        CurvedAnimation(parent: _loopCtrl, curve: Curves.easeInOut));
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _loopCtrl, curve: Curves.easeInOut));
    _sparkleFloat = Tween<double>(begin: -5, end: 5).animate(
        CurvedAnimation(parent: _loopCtrl, curve: Curves.easeInOut));

    // Sequence
    HapticFeedback.heavyImpact();
    _entranceCtrl.forward();
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _burstCtrl.forward();
      _playSound();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) HapticFeedback.mediumImpact();
    });
  }

  Future<void> _playSound() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/achievement.mp3'));
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (_) {}
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _burstCtrl.dispose();
    _loopCtrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _dismiss,
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_entranceCtrl, _burstCtrl, _loopCtrl]),
          builder: (_, __) {
            return Stack(
              children: [
                // ── Dark background
                Opacity(
                  opacity: _bgFade.value * 0.88,
                  child: Container(color: const Color(0xFF050505)),
                ),

                // ── Burst painter (rings + particles)
                CustomPaint(
                  painter: _BurstPainter(
                    particles: _particles,
                    burstT: _burstProgress.value,
                    ringT: _ringProgress.value,
                    center: center,
                    ringColor: _color,
                  ),
                  child: const SizedBox.expand(),
                ),

                // ── Floating sparkle stars
                ..._buildSparkles(center),

                // ── Card
                Center(
                  child: Opacity(
                    opacity: _cardFade.value,
                    child: Transform.scale(
                      scale: _cardScale.value,
                      child: _buildCard(),
                    ),
                  ),
                ),

                // ── Dismiss hint
                Positioned(
                  bottom: 52,
                  left: 0, right: 0,
                  child: Opacity(
                    opacity: _cardFade.value * 0.5,
                    child: const Text(
                      'Toque para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Sparkle dots ───────────────────────────────────────────────────────────

  List<Widget> _buildSparkles(Offset center) {
    const count = 8;
    return List.generate(count, (i) {
      final baseAngle = i * (pi * 2 / count);
      final radius = 148.0;
      final phase = i / count;
      final floatY = _sparkleFloat.value * (i.isEven ? 1 : -1);
      final opacity = (sin(_loopCtrl.value * pi * 2 + phase * pi * 2) * 0.4 + 0.6)
          .clamp(0.0, 1.0) * _cardFade.value;

      final x = center.dx + cos(baseAngle) * radius;
      final y = center.dy + sin(baseAngle) * radius + floatY;

      return Positioned(
        left: x - 8,
        top: y - 8,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            i % 3 == 0 ? Icons.auto_awesome_rounded : Icons.star_rounded,
            color: _color,
            size: i % 2 == 0 ? 14 : 10,
          ),
        ),
      );
    });
  }

  // ── Card ──────────────────────────────────────────────────────────────────

  Widget _buildCard() {
    final color  = _color;
    final icon   = widget.achievement['icon'] as IconData;
    final label  = widget.achievement['label'] as String;

    return Container(
      width: 288,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: const Color(0xFF111111),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 48,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 90,
            spreadRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Shimmer sweep
            Positioned.fill(
              child: IgnorePointer(
                child: Transform.translate(
                  offset: Offset(_shimmer.value * 300, -40),
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.38)),
                  ),
                  child: Text(
                    'CONQUISTA DESBLOQUEADA',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // Pulsing icon badge
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: _pulse.value,
                    child: child,
                  ),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.14),
                      border: Border.all(
                          color: color.withValues(alpha: 0.65), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.55),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 44),
                  ),
                ),
                const SizedBox(height: 22),

                // Achievement name
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nova conquista adicionada\nao seu perfil!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.30),
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
