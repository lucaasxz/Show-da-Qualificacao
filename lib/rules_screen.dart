import 'package:flutter/material.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _slide = Tween<double>(begin: 24, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.8, curve: Curves.easeOut)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) => Opacity(
                  opacity: _fade.value,
                  child: Transform.translate(
                      offset: Offset(0, _slide.value), child: child),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    children: [
                      _buildHero(),
                      const SizedBox(height: 24),
                      _buildSection(
                        icon: Icons.flag_rounded,
                        color: const Color(0xFFC8870A),
                        title: 'Objetivo',
                        body: 'Responder corretamente pelo menos 80% das questões da prova para ser aprovado e desbloquear a próxima modalidade.',
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        icon: Icons.quiz_rounded,
                        color: const Color(0xFF42A5F5),
                        title: 'As Questões',
                        body: 'Cada prova contém 50 questões de múltipla escolha com 4 alternativas (A, B, C e D). As questões e as alternativas são embaralhadas a cada nova prova, então cada jogo é único.',
                      ),
                      const SizedBox(height: 12),
                      _buildLifelinesSection(),
                      const SizedBox(height: 12),
                      _buildProgressionSection(),
                      const SizedBox(height: 12),
                      _buildSection(
                        icon: Icons.military_tech_rounded,
                        color: const Color(0xFFC8870A),
                        title: 'XP e Níveis',
                        body: 'Cada resposta correta vale 1 XP. Acumule XP para subir de nível, de Novato até Mestre. Seu nível e progresso ficam visíveis na tela inicial.',
                        extra: _buildLevelsList(),
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        icon: Icons.bookmark_rounded,
                        color: const Color(0xFF66BB6A),
                        title: 'Salvar e Continuar',
                        body: 'Você pode sair de uma prova a qualquer momento sem perder o progresso. Toque em ✕ durante a prova e escolha "Salvar e Sair". Na próxima vez que entrar na mesma prova, continuará exatamente de onde parou.',
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        icon: Icons.bar_chart_rounded,
                        color: const Color(0xFF9C27B0),
                        title: 'Estatísticas',
                        body: 'Na tela inicial você acompanha em tempo real o total de provas realizadas, acertos, erros e sua precisão geral. O histórico detalhado fica registrado para acompanhar sua evolução.',
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFFFD700),
                        title: 'Conquistas',
                        body: 'Desbloqueie medalhas completando marcos específicos:\n\n'
                            '★  1ª Prova — complete sua primeira prova\n'
                            '🔥  10 Acertos — acumule 10 respostas corretas\n'
                            '🎯  Precisão 80% — mantenha 80% em 3+ provas\n'
                            '🏅  20 Provas — complete 20 provas no total\n'
                            '🏆  Mestre — alcance 800 XP',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF1C1C1C),
                border: Border.all(color: const Color(0xFF2E2E2E)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF888888), size: 16),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'REGRAS DO JOGO',
            style: TextStyle(
              color: Color(0xFFC8870A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero banner ───────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1208), Color(0xFF111111)],
        ),
        border: Border.all(
          color: const Color(0xFFC8870A).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC8870A).withValues(alpha: 0.08),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC8870A).withValues(alpha: 0.14),
              border: Border.all(
                color: const Color(0xFFC8870A).withValues(alpha: 0.40),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Color(0xFFC8870A), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Show da Qualificação',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prepare-se para o exame IS-N1 respondendo questões organizadas por matéria, com dificuldade real de prova.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Generic section card ──────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    Widget? extra,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0F0F0F),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: color.withValues(alpha: 0.13),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 13,
              height: 1.65,
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: 14),
            extra,
          ],
        ],
      ),
    );
  }

  // ── Lifelines section ─────────────────────────────────────────────────────

  Widget _buildLifelinesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0F0F0F),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: const Color(0xFFFFB300).withValues(alpha: 0.13),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFFFFB300), size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Auxiliares',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLifelineRow(
            icon: Icons.lightbulb_rounded,
            color: const Color(0xFFFFB300),
            name: 'Dica (×3 por prova)',
            description:
                'Elimina 2 alternativas erradas, deixando apenas a correta e mais uma. Use quando estiver em dúvida entre muitas opções.',
          ),
          const SizedBox(height: 12),
          _buildLifelineRow(
            icon: Icons.fast_forward_rounded,
            color: const Color(0xFF42A5F5),
            name: 'Pular (×3 por prova)',
            description:
                'Envia a questão atual para o final da fila e avança para a próxima. Cada questão só pode ser pulada uma vez.',
          ),
        ],
      ),
    );
  }

  Widget _buildLifelineRow({
    required IconData icon,
    required Color color,
    required String name,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.13),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(description,
                  style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      height: 1.55)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Progression section ───────────────────────────────────────────────────

  Widget _buildProgressionSection() {
    final exams = [
      {'name': 'Teórica Geral',       'icon': Icons.school_outlined,                   'req': 'Sempre disponível'},
      {'name': 'Documentos Técnicos', 'icon': Icons.description_outlined,              'req': '80% na Teórica Geral'},
      {'name': 'Tratamento Térmico',  'icon': Icons.local_fire_department_outlined,    'req': '80% em Documentos Técnicos'},
      {'name': 'Dureza',              'icon': Icons.hardware_outlined,                 'req': '80% em Tratamento Térmico'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0F0F0F),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.13),
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: Color(0xFF4CAF50), size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Desbloqueio Progressivo',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'As provas são desbloqueadas em sequência. Para avançar, você precisa atingir 80% na prova anterior.',
            style: TextStyle(color: Color(0xFF666666), fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),
          ...List.generate(exams.length, (i) {
            final exam = exams[i];
            final isFirst = i == 0;
            return Column(
              children: [
                Row(
                  children: [
                    // Line + circle indicator
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFirst
                                  ? const Color(0xFFC8870A).withValues(alpha: 0.18)
                                  : const Color(0xFF1A1A1A),
                              border: Border.all(
                                color: isFirst
                                    ? const Color(0xFFC8870A).withValues(alpha: 0.55)
                                    : const Color(0xFF2A2A2A),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isFirst
                                      ? const Color(0xFFC8870A)
                                      : const Color(0xFF444444),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (i < exams.length - 1)
                            Container(
                              width: 1,
                              height: 24,
                              color: const Color(0xFF1E1E1E),
                              margin: const EdgeInsets.symmetric(vertical: 3),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: i < exams.length - 1 ? 30 : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(exam['icon'] as IconData,
                                    color: isFirst
                                        ? const Color(0xFFC8870A)
                                        : const Color(0xFF555555),
                                    size: 15),
                                const SizedBox(width: 6),
                                Text(
                                  exam['name'] as String,
                                  style: TextStyle(
                                    color: isFirst
                                        ? Colors.white
                                        : const Color(0xFF888888),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              exam['req'] as String,
                              style: TextStyle(
                                color: isFirst
                                    ? const Color(0xFFC8870A).withValues(alpha: 0.70)
                                    : const Color(0xFF444444),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Levels list ───────────────────────────────────────────────────────────

  Widget _buildLevelsList() {
    const levels = [
      {'title': 'Novato',        'xp': '0 XP'},
      {'title': 'Aprendiz',      'xp': '15 XP'},
      {'title': 'Técnico',       'xp': '40 XP'},
      {'title': 'Inspetor Jr.',  'xp': '80 XP'},
      {'title': 'Inspetor',      'xp': '150 XP'},
      {'title': 'Inspetor Sr.',  'xp': '280 XP'},
      {'title': 'Especialista',  'xp': '500 XP'},
      {'title': 'Mestre',        'xp': '800 XP'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: Column(
        children: List.generate(levels.length, (i) {
          final isLast = i == levels.length - 1;
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFC8870A).withValues(alpha: 0.10),
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Color(0xFFC8870A),
                              fontSize: 9,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(levels[i]['title']!,
                        style: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text(levels[i]['xp']!,
                      style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              if (!isLast)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 7),
                  color: const Color(0xFF181818),
                ),
            ],
          );
        }),
      ),
    );
  }
}
