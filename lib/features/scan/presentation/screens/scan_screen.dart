import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/food_analysis_provider.dart';
import '../../domain/models/food_analysis_model.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String get _language {
    final code = context.locale.languageCode;
    if (code == 'hi') return 'Hindi';
    if (code == 'or') return 'Odia';
    return 'English';
  }

  void _triggerResultAnimation() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(foodAnalysisProvider);

    // Animate when results arrive
    ref.listen<FoodAnalysisState>(foodAnalysisProvider, (prev, next) {
      final wasLoading = prev?.result is AsyncLoading;
      final hasData = next.result is AsyncData &&
          ((next.result.asData?.value?.calories ?? 0) > 0);
      if (wasLoading && hasData) {
        _triggerResultAnimation();
      }
    });

    final hasImage = scanState.imagePath != null;
    final hasIngredients = scanState.detectedIngredients.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Scan Button ────────────────────────────────────────
          GestureDetector(
            onTap: () => ref
                .read(foodAnalysisProvider.notifier)
                .pickAndAnalyze(_language),
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'scan.title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'scan.subtitle'.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Image Preview ───────────────────────────────────────────
          if (hasImage) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(scanState.imagePath!),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ],

          // ── Detecting Shimmer / Ingredients ────────────────────────
          if (scanState.isDetecting) ...[
            const SizedBox(height: 20),
            _ShimmerCard(label: 'scan.detecting'.tr()),
          ],

          if (hasIngredients && !scanState.isDetecting) ...[
            const SizedBox(height: 20),
            Text(
              'scan.detected'.tr(),
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: scanState.detectedIngredients
                  .map((ing) => Chip(
                        label: Text(
                          ing.tr(),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: const Color(0xFFE8F5E9),
                        side: const BorderSide(color: Color(0xFFA5D6A7)),
                        avatar: const Icon(Icons.eco_rounded,
                            color: Color(0xFF4CAF50), size: 16),
                      ))
                  .toList(),
            ),
          ],

          // ── AI Analysis Results ─────────────────────────────────────
          const SizedBox(height: 20),
          scanState.result.when(
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF4CAF50)),
                    const SizedBox(height: 12),
                    Text('scan.analyzing'.tr(),
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            error: (err, _) => _ErrorCard(
              onRetry: () => ref
                  .read(foodAnalysisProvider.notifier)
                  .pickAndAnalyze(_language),
            ),
            data: (result) {
              if (result == null || result.calories == 0) return const SizedBox();
              return FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _ResultSection(result: result),
                ),
              );
            },
          ),

          // ── Reset ───────────────────────────────────────────────────
          if (hasImage) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded,
                    color: Color(0xFF4CAF50)),
                label: Text('scan.reset'.tr(),
                    style: const TextStyle(color: Color(0xFF4CAF50))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () =>
                    ref.read(foodAnalysisProvider.notifier).reset(),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Shimmer loading card ───────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  final String label;
  const _ShimmerCard({required this.label});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircularProgressIndicator(
                color: Color(0xFF4CAF50), strokeWidth: 2),
            const SizedBox(width: 16),
            Text(widget.label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
          ],
        ),
      ),
    );
  }
}

// ── Full results section ──────────────────────────────────────────────────────
class _ResultSection extends StatelessWidget {
  final FoodAnalysisModel result;
  const _ResultSection({required this.result});

  @override
  Widget build(BuildContext context) {
    final spikeColor = result.glucoseSpike.toLowerCase() == 'high'
        ? Colors.red
        : result.glucoseSpike.toLowerCase() == 'medium'
            ? Colors.orange
            : Colors.green;

    final spikeIcon = result.glucoseSpike.toLowerCase() == 'high'
        ? Icons.warning_amber_rounded
        : result.glucoseSpike.toLowerCase() == 'medium'
            ? Icons.info_rounded
            : Icons.check_circle_rounded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nutrition Card
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('scan.nutrition'.tr(),
                  style:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _NutriTile('🔥', '${result.calories}', 'kcal'),
                  _NutriTile('🍞', '${result.carbs}g', 'scan.carbs'.tr()),
                  _NutriTile('💪', '${result.protein}g', 'scan.protein'.tr()),
                  _NutriTile('🫧', '${result.fat}g', 'scan.fat'.tr()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Glucose Spike Indicator
        _SectionCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: spikeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(spikeIcon, color: spikeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('scan.glucose'.tr(),
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: spikeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      result.glucoseSpike.toUpperCase(),
                      style: TextStyle(
                          color: spikeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Warning Banner
        if (result.warning.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: result.glucoseSpike.toLowerCase() == 'high'
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFFFFDE7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: result.glucoseSpike.toLowerCase() == 'high'
                    ? Colors.red.shade200
                    : Colors.amber.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                    result.glucoseSpike.toLowerCase() == 'high'
                        ? Icons.warning_rounded
                        : Icons.lightbulb_outline_rounded,
                    color: result.glucoseSpike.toLowerCase() == 'high'
                        ? Colors.red
                        : Colors.amber.shade700,
                    size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.warning,
                    style: TextStyle(
                        fontSize: 13,
                        color: result.glucoseSpike.toLowerCase() == 'high'
                            ? Colors.red.shade700
                            : Colors.amber.shade900,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Suggestion Card
        if (result.suggestion.isNotEmpty)
          _SectionCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_walk_rounded,
                      color: Color(0xFF1976D2), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('scan.suggestion'.tr(),
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        result.suggestion,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

class _NutriTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _NutriTile(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A))),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text('scan.failed'.tr(),
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('common.retry'.tr()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
