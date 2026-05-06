import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class _Spark {
  Offset pos;
  Offset vel;
  double life;
  final Color color;
  final double size;
  _Spark({required this.pos, required this.vel, required this.color, required this.size})
      : life = 1.0;
}

const _kSparkColors = [
  Color(0xFFFF8C00),
  Color(0xFFFFCC00),
  Color(0xFFFF4500),
  Color(0xFFFFFFCC),
];

/// Wraps [child] and overlays ambient industrial sparks.
/// Sparks burst from random positions near the bottom/sides of the screen
/// with IgnorePointer so they never block touches.
class AmbientSparks extends StatefulWidget {
  const AmbientSparks({super.key, required this.child});
  final Widget child;

  @override
  State<AmbientSparks> createState() => _AmbientSparksState();
}

class _AmbientSparksState extends State<AmbientSparks>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  final List<_Spark> _sparks = [];
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Timer? _burstTimer;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _scheduleBurst();
  }

  void _scheduleBurst() {
    _burstTimer = Timer(Duration(milliseconds: 2500 + _rng.nextInt(3000)), () {
      if (mounted) {
        _spawnBurst();
        _scheduleBurst();
      }
    });
  }

  void _spawnBurst() {
    if (_size.width == 0) return;
    final side = _rng.nextInt(3);
    final Offset origin;
    if (side == 0) {
      origin = Offset(
        _rng.nextDouble() * _size.width * 0.22,
        _size.height * (0.55 + _rng.nextDouble() * 0.3),
      );
    } else if (side == 1) {
      origin = Offset(
        _size.width * 0.78 + _rng.nextDouble() * _size.width * 0.22,
        _size.height * (0.55 + _rng.nextDouble() * 0.3),
      );
    } else {
      origin = Offset(
        _size.width * 0.28 + _rng.nextDouble() * _size.width * 0.44,
        _size.height * (0.72 + _rng.nextDouble() * 0.15),
      );
    }
    final count = 6 + _rng.nextInt(8);
    for (int i = 0; i < count; i++) {
      final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * pi * 1.3;
      final speed = 70.0 + _rng.nextDouble() * 210;
      _sparks.add(_Spark(
        pos: origin,
        vel: Offset(cos(angle) * speed, sin(angle) * speed),
        color: _kSparkColors[_rng.nextInt(_kSparkColors.length)],
        size: 1.5 + _rng.nextDouble() * 2.5,
      ));
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _sparks.removeWhere((s) => s.life <= 0);
    for (final s in _sparks) {
      s.vel = Offset(s.vel.dx * 0.985, s.vel.dy + 130 * dt);
      s.pos += s.vel * dt;
      s.life -= dt * 0.85;
    }
    if (mounted && _sparks.isNotEmpty) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    _burstTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: CustomPaint(
            size: _size,
            painter: _AmbientSparksPainter(_sparks),
          ),
        ),
      ],
    );
  }
}

class _AmbientSparksPainter extends CustomPainter {
  final List<_Spark> sparks;
  const _AmbientSparksPainter(this.sparks);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final life = s.life.clamp(0.0, 1.0);
      if (life <= 0) continue;
      final tailEnd = s.pos - s.vel * 0.030;
      canvas.drawLine(
        tailEnd,
        s.pos,
        Paint()
          ..color = s.color.withValues(alpha: life)
          ..strokeWidth = s.size * 0.6
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        s.pos,
        s.size * 0.50,
        Paint()..color = Colors.white.withValues(alpha: life * 0.80),
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientSparksPainter _) => true;
}
