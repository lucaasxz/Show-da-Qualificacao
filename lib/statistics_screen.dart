import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _fade;
  late Animation<double> _slide;

  int _totalCorrect = 0;
  int _totalWrong = 0;
  int _totalGames = 0;
  List<int> _correctHistory = [];
  List<int> _wrongHistory = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _slide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)),
    );

    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _totalCorrect = prefs.getInt('total_correct') ?? 0;
      _totalWrong = prefs.getInt('total_wrong') ?? 0;
      _totalGames = prefs.getInt('total_games') ?? 0;
      _correctHistory = (prefs.getStringList('correct_history') ?? [])
          .map(int.parse)
          .toList();
      _wrongHistory = (prefs.getStringList('wrong_history') ?? [])
          .map(int.parse)
          .toList();
      _loaded = true;
    });
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  double get _accuracy {
    final total = _totalCorrect + _totalWrong;
    if (total == 0) return 0;
    return _totalCorrect / total * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF0A0A0A),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _loaded
                    ? AnimatedBuilder(
                        animation: _entranceCtrl,
                        builder: (context, child) => Opacity(
                          opacity: _fade.value,
                          child: Transform.translate(
                            offset: Offset(0, _slide.value),
                            child: child,
                          ),
                        ),
                        child: _buildContent(),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFC8870A),
                          strokeWidth: 2,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF888888), size: 16),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'ESTATÍSTICAS',
            style: TextStyle(
              color: Color(0xFFC8870A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildSummaryCards(),
          const SizedBox(height: 20),
          _buildDonutChart(),
          const SizedBox(height: 20),
          if (_correctHistory.isNotEmpty) ...[
            _buildBarChart(),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('ACERTOS', '$_totalCorrect', const Color(0xFF4CAF50))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('ERROS', '$_totalWrong', const Color(0xFFE53935))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('PROVAS', '$_totalGames', const Color(0xFFC8870A))),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.08),
            const Color(0xFF111111),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.40), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.50), blurRadius: 10),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart() {
    final total = _totalCorrect + _totalWrong;
    final hasData = total > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1C1C1C),
        border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'APROVEITAMENTO GERAL',
              style: TextStyle(
                color: Color(0xFFC8870A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 62,
                    sections: hasData
                        ? [
                            PieChartSectionData(
                              value: _totalCorrect.toDouble(),
                              color: const Color(0xFF4CAF50),
                              radius: 26,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: _totalWrong.toDouble(),
                              color: const Color(0xFFE53935),
                              radius: 26,
                              showTitle: false,
                            ),
                          ]
                        : [
                            PieChartSectionData(
                              value: 1,
                              color: const Color(0xFF2E2E2E),
                              radius: 26,
                              showTitle: false,
                            ),
                          ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_accuracy.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: _accuracy >= 60
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.70)
                                : const Color(0xFFE53935).withValues(alpha: 0.70),
                            blurRadius: 16,
                          ),
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'de acerto',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(const Color(0xFF4CAF50), 'Acertos'),
              const SizedBox(width: 24),
              _buildLegend(const Color(0xFFE53935), 'Erros'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final count = _correctHistory.length;
    final barGroups = List.generate(count, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: _correctHistory[i].toDouble(),
            color: const Color(0xFF4CAF50),
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: _wrongHistory[i].toDouble(),
            color: const Color(0xFFE53935),
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });

    final maxY = [..._correctHistory, ..._wrongHistory].fold(0, max).toDouble();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1C1C1C),
        border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HISTÓRICO POR PROVA',
            style: TextStyle(
              color: Color(0xFFC8870A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY + 2,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFF2A2A2A),
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        'P${v.toInt() + 1}',
                        style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(const Color(0xFF4CAF50), 'Acertos'),
              const SizedBox(width: 24),
              _buildLegend(const Color(0xFFE53935), 'Erros'),
            ],
          ),
        ],
      ),
    );
  }
}
