import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'player_name_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _fade;
  late Animation<double> _progress;

  int _loadingStep = 0;
  final List<String> _loadingMessages = [
    'Preparando as perguntas...',
    'Carregando o estúdio...',
    'Chamando os especialistas...',
    'Quase lá...',
    'Tudo pronto!',
  ];

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _progress = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut);

    _entranceCtrl.forward();
    _startLoading();
  }

  void _startLoading() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _progressCtrl.forward();

    const stepDuration = Duration(milliseconds: 640);
    for (int i = 0; i < _loadingMessages.length; i++) {
      await Future.delayed(stepDuration);
      if (mounted) setState(() => _loadingStep = i);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('player_name') ?? '';

    if (!mounted) return;

    if (savedName.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => const HomeScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => const PlayerNameScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF0A0A0A),
        child: AnimatedBuilder(
          animation: _fade,
          builder: (context, child) => Opacity(opacity: _fade.value, child: child),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _buildLogo(),
                const SizedBox(height: 40),
                _buildProgressSection(),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              _loadingMessages[_loadingStep],
              key: ValueKey(_loadingStep),
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressBar(),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _progress,
            builder: (context, _) => Text(
              '${(_progress.value * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFFC8870A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF1E1E1E),
      ),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: constraints.maxWidth * _progress.value,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFFDFA030), Color(0xFFC8870A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC8870A).withValues(alpha: 0.55),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
