import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:healthplate/features/metabolic/presentation/providers/glucose_provider.dart';
import 'package:healthplate/features/metabolic/domain/models/metabolic_data_model.dart';

class MetabolicScreen extends ConsumerWidget {
  const MetabolicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metabolicAsync = ref.watch(glucoseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      body: metabolicAsync.when(
        data: (data) => _MetabolicContent(data: data),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
        error: (err, _) => Center(child: Text("common.error".tr())),
      ),
    );
  }
}

class _MetabolicContent extends StatelessWidget {
  final MetabolicData data;
  const _MetabolicContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Text(
            "metabolic.title".tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "metabolic.subtitle".tr(),
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // ── Pulse Gauge ────────────────────────────────────────
          _PulseGauge(score: data.score, spike: data.glucoseSpike),
          const SizedBox(height: 24),

          // ── Indicators Row ──────────────────────────────────────
          Row(
            children: [
              _InteractiveMetricCard(
                title: "metabolic.glucoseRisk".tr(),
                value: data.glucoseSpike,
                color: _getSpikeColor(data.glucoseSpike),
                icon: Icons.trending_up_rounded,
                desc: "metabolic.predictedSpike".tr(),
              ),
              const SizedBox(width: 12),
              _InteractiveMetricCard(
                title: "metabolic.stressIndex".tr(),
                value: data.stressLevel,
                color: _getStressColor(data.stressLevel),
                icon: Icons.favorite_rounded,
                desc: "metabolic.basedOnHR".tr(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Interactive Chart ───────────────────────────────────
          _ChartContainer(curve: data.glucoseCurve),
          const SizedBox(height: 24),

          // ── Insight Section ─────────────────────────────────────
          _AnimatedInsightCard(
            reason: data.reason,
            suggestion: data.suggestion,
            isHigh: data.glucoseSpike == "HIGH",
          ),
          const SizedBox(height: 24),

          // ── Quick Tips ──────────────────────────────────────────
          Text(
            "metabolic.healthTips".tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _HealthTipsList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Color _getSpikeColor(String spike) {
    if (spike == "HIGH") return const Color(0xFFE53935);
    if (spike == "MEDIUM") return const Color(0xFFFFB300);
    return const Color(0xFF43A047);
  }

  Color _getStressColor(String stress) {
    if (stress == "High") return const Color(0xFFE53935);
    if (stress == "Normal") return const Color(0xFF1E88E5);
    return const Color(0xFF43A047);
  }
}

class _PulseGauge extends StatefulWidget {
  final int score;
  final String spike;
  const _PulseGauge({required this.score, required this.spike});

  @override
  State<_PulseGauge> createState() => _PulseGaugeState();
}

class _PulseGaugeState extends State<_PulseGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.spike == "HIGH"
        ? Colors.red
        : (widget.spike == "MEDIUM" ? Colors.orange : Colors.green);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulse,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: widget.score / 10,
                    strokeWidth: 14,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "${widget.score}",
                      style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: -2),
                    ),
                    Text("metabolic.score".tr(),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey,
                            letterSpacing: 2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              "${widget.spike} ${"metabolic.risk".tr()}",
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final String desc;

  const _InteractiveMetricCard(
      {required this.title,
      required this.value,
      required this.color,
      required this.icon,
      required this.desc});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700)),
            Text(desc, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _ChartContainer extends StatelessWidget {
  final List<double> curve;
  const _ChartContainer({required this.curve});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("metabolic.projection".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text("metabolic.projectionDesc".tr(),
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => const Color(0xFF1B5E20),
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        "${s.y.toInt()} mg/dL",
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: curve
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF4CAF50),
                    barWidth: 6,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50).withValues(alpha: 0.4),
                          const Color(0xFF4CAF50).withValues(alpha: 0.0)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedInsightCard extends StatelessWidget {
  final String reason;
  final String suggestion;
  final bool isHigh;

  const _AnimatedInsightCard(
      {required this.reason, required this.suggestion, required this.isHigh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHigh
              ? [const Color(0xFFB71C1C), const Color(0xFFEF5350)]
              : [const Color(0xFF1B5E20), const Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: (isHigh ? Colors.red : Colors.green).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: Icon(isHigh ? Icons.warning_rounded : Icons.auto_awesome,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text("metabolic.recommendation".tr(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 20),
          _InsightRow(icon: Icons.info_outline, text: "${"metabolic.reasonLabel".tr()} $reason"),
          const SizedBox(height: 12),
          _InsightRow(icon: Icons.bolt_rounded, text: "${"metabolic.suggestionLabel".tr()} $suggestion", isBold: true),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isBold;
  const _InsightRow({required this.icon, required this.text, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _HealthTipsList extends StatelessWidget {
  final tips = [
    {
      "icon": Icons.water_drop_rounded,
      "title": "metabolic.tip1Title",
      "subtitle": "metabolic.tip1Desc"
    },
    {
      "icon": Icons.directions_walk_rounded,
      "title": "metabolic.tip2Title",
      "subtitle": "metabolic.tip2Desc"
    },
    {
      "icon": Icons.nights_stay_rounded,
      "title": "metabolic.tip3Title",
      "subtitle": "metabolic.tip3Desc"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final tip = tips[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tip["icon"] as IconData,
                    color: const Color(0xFF4CAF50)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((tip["title"] as String).tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text((tip["subtitle"] as String).tr(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
