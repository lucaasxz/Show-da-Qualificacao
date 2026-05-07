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
  Color(0xFFFFBB00),
  Color(0xFFFFCC00),
  Color(0xFFFF4500),
  Color(0xFFFFFFCC),
  Color(0xFFFFEE88),
  Color(0xFFFF6600),
];

/// Wraps [child] and overlays dense ambient industrial sparks.
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

  // Spawn points: [left-side, right-side, bottom-center, bottom-left, bottom-right]
  final List<_BurstZone> _zones = const [
    _BurstZone(xFrac: 0.05, yMin: 0.50, yMax: 0.85),
    _BurstZone(xFrac: 0.95, yMin: 0.50, yMax: 0.85),
    _BurstZone(xFrac: 0.50, yMin: 0.78, yMax: 0.95),
    _BurstZone(xFrac: 0.20, yMin: 0.70, yMax: 0.92),
    _BurstZone(xFrac: 0.80, yMin: 0.70, yMax: 0.92),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _scheduleBurst();
  }

  void _scheduleBurst() {
    // Burst every 700–1600 ms — much more frequent than before
    _burstTimer = Timer(Duration(milliseconds: 700 + _rng.nextInt(900)), () {
      if (mounted) {
        _spawnBurst();
        // 40 % chance of a second simultaneous burst from a different zone
        if (_rng.nextDouble() < 0.40) _spawnBurst();
        _scheduleBurst();
      }
    });
  }

  void _spawnBurst() {
    if (_size.width == 0) return;
    final zone = _zones[_rng.nextInt(_zones.length)];
    final ox = _size.width * zone.xFrac + (_rng.nextDouble() - 0.5) * _size.width * 0.12;
    final oy = _size.height * (zone.yMin + _rng.nextDouble() * (zone.yMax - zone.yMin));
    final origin = Offset(ox, oy);

    // 16–28 sparks per burst
    final count = 16 + _rng.nextInt(13);
    for (int i = 0; i < count; i++) {
      final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * pi * 1.5;
      final speed = 90.0 + _rng.nextDouble() * 280;
      _sparks.add(_Spark(
        pos: origin,
        vel: Offset(cos(angle) * speed, sin(angle) * speed),
        color: _kSparkColors[_rng.nextInt(_kSparkColors.length)],
        size: 1.2 + _rng.nextDouble() * 3.0,
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
      s.vel = Offset(s.vel.dx * 0.982, s.vel.dy + 140 * dt);
      s.pos += s.vel * dt;
      s.life -= dt * 0.90;
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

class _BurstZone {
  final double xFrac;
  final double yMin;
  final double yMax;
  const _BurstZone({required this.xFrac, required this.yMin, required this.yMax});
}

class _AmbientSparksPainter extends CustomPainter {
  final List<_Spark> sparks;
  const _AmbientSparksPainter(this.sparks);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final life = s.life.clamp(0.0, 1.0);
      if (life <= 0) continue;

      final speed = s.vel.distance.clamp(1.0, 800.0);
      final tailLen = (speed * 0.014).clamp(2.0, 14.0);
      final dir = s.vel / speed;
      final tail = s.pos - dir * tailLen;

      canvas.drawLine(
        tail, s.pos,
        Paint()
          ..color = s.color.withValues(alpha: life)
          ..strokeWidth = s.size * 0.65
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        s.pos, s.size * 0.52,
        Paint()..color = Colors.white.withValues(alpha: life * 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientSparksPainter _) => true;
}
