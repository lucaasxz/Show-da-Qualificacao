import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class PlayerNameScreen extends StatefulWidget {
  const PlayerNameScreen({super.key});

  @override
  State<PlayerNameScreen> createState() => _PlayerNameScreenState();
}

class _PlayerNameScreenState extends State<PlayerNameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _fade;
  late Animation<double> _slideTitle;
  late Animation<double> _slideForm;

  final TextEditingController _nameCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _slideTitle = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)),
    );
    _slideForm = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.2, 1, curve: Curves.easeOut)),
    );

    _entranceCtrl.forward();

    _nameCtrl.addListener(() {
      final hasName = _nameCtrl.text.trim().isNotEmpty;
      if (hasName != _canContinue) setState(() => _canContinue = hasName);
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _nameCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onContinue() async {
    if (!_canContinue) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_name', _nameCtrl.text.trim());
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const HomeScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF0A0A0A),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _entranceCtrl,
            builder: (context, child) => Opacity(opacity: _fade.value, child: child),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 52),
                  AnimatedBuilder(
                    animation: _entranceCtrl,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _slideTitle.value),
                      child: child,
                    ),
                    child: _buildHeader(),
                  ),
                  const SizedBox(height: 48),
                  AnimatedBuilder(
                    animation: _entranceCtrl,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _slideForm.value),
                      child: child,
                    ),
                    child: _buildForm(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', height: 140, fit: BoxFit.contain),
        const SizedBox(height: 28),
        Container(
          width: 48,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [Color(0xFFDFA030), Color(0xFFC8870A)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC8870A).withValues(alpha: 0.50),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'COMO PODEMOS TE CHAMAR?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFC8870A),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Digite seu nome para entrar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildTextField(),
        const SizedBox(height: 24),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1C1C1C),
        border: Border.all(
          color: const Color(0xFFC8870A).withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _nameCtrl,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.words,
        maxLength: 20,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        decoration: const InputDecoration(
          hintText: 'Seu nome aqui',
          hintStyle: TextStyle(
            color: Color(0xFF444444),
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        onSubmitted: (_) => _onContinue(),
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: _onContinue,
      child: AnimatedOpacity(
        opacity: _canContinue ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 250),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _canContinue
                  ? const [Color(0xFFDFA030), Color(0xFFC8870A), Color(0xFF8A5E06)]
                  : const [Color(0xFF2A2A2A), Color(0xFF222222)],
            ),
            boxShadow: _canContinue
                ? [
                    BoxShadow(
                      color: const Color(0xFFC8870A).withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_forward_rounded,
                color: _canContinue ? const Color(0xFF0A0A0A) : const Color(0xFF555555),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'CONTINUAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _canContinue ? const Color(0xFF0A0A0A) : const Color(0xFF555555),
                  letterSpacing: 3.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
