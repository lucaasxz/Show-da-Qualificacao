import 'package:flutter/material.dart';
import 'loading_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _buttonCtrl;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _buttonFade;
  late final Animation<double> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _logoCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _buttonCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _logoFade   = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _logoScale  = Tween<double>(begin: 0.85, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeOut));
    _buttonSlide = Tween<double>(begin: 24, end: 0).animate(CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeOut));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await _logoCtrl.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _buttonCtrl.forward();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _buttonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoCtrl,
              builder: (context, child) => Opacity(
                opacity: _logoFade.value,
                child: Transform.scale(scale: _logoScale.value, child: child),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 52),
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
                child: const Text(
                  'v1.0.0',
                  style: TextStyle(color: Color(0xFF555555), fontSize: 11, letterSpacing: 2),
                ),
              ),
            ),
          ],
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
            Text(
              'INICIAR',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0A0A0A),
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
