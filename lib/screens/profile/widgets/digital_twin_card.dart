import 'package:flutter/material.dart';

import 'twin_avatar_section.dart';
import 'twin_legend_row.dart';
import 'health_score_summary_card.dart';
import 'twin_metric_grid.dart';
import 'twin_suggestion_card.dart';
import 'daily_suggestion_button.dart';

class DigitalTwinCard extends StatelessWidget {
  final String selectedGender;
  final double waterPercent;
  final double caloriePercent;
  final double proteinPercent;
  final double activityPercent;
  final int healthScore;
  final String healthStatusText;
  final VoidCallback onSuggestionTap;

  final String waterCurrentStr;
  final String waterGoalStr;
  final String calorieCurrentStr;
  final String calorieGoalStr;
  final String proteinCurrentStr;
  final String proteinGoalStr;
  final String activityCurrentStr;
  final String activityGoalStr;

  const DigitalTwinCard({
    super.key,
    required this.selectedGender,
    required this.waterPercent,
    required this.caloriePercent,
    required this.proteinPercent,
    required this.activityPercent,
    required this.healthScore,
    required this.healthStatusText,
    required this.onSuggestionTap,
    required this.waterCurrentStr,
    required this.waterGoalStr,
    required this.calorieCurrentStr,
    required this.calorieGoalStr,
    required this.proteinCurrentStr,
    required this.proteinGoalStr,
    required this.activityCurrentStr,
    required this.activityGoalStr,
  });

  // ── Avatar path from gender ──────────────────────────────
  String _getAvatarPath() {
    final g = selectedGender.toLowerCase();
    if (g == 'male' || g == 'erkek' || g == 'e') {
      return 'assets/erkek.png';
    }
    return 'assets/kadin.png';
  }

  // ── Aura status ──────────────────────────────────────────
  String _getAuraStatus() {
    if (waterPercent < 0.50) return 'lowWater';
    if (caloriePercent < 0.45) return 'lowCalories';
    if (activityPercent < 0.50) return 'lowActivity';
    if (proteinPercent < 0.55) return 'lowProtein';
    return 'balanced';
  }

  Color _getAuraColor(String status) {
    switch (status) {
      case 'lowWater':
        return const Color(0xFF2D9CDB);
      case 'lowCalories':
        return const Color(0xFFFF8A00);
      case 'lowActivity':
        return const Color(0xFF7B61FF);
      case 'lowProtein':
        return const Color(0xFF2ECC71);
      case 'balanced':
      default:
        return const Color(0xFF22C55E);
    }
  }

  // Short suggestion messages that fit in 2 lines max
  String _getSuggestion(String status) {
    switch (status) {
      case 'lowWater':
        return 'Biraz daha su içmeyi hedefleyebilirsin.';
      case 'lowCalories':
        return 'Dengeli bir ara öğün ekleyebilirsin.';
      case 'lowActivity':
        return '15 dk hafif yürüyüş iyi olabilir.';
      case 'lowProtein':
        return 'Protein ağırlıklı bir öğün tercih edebilirsin.';
      case 'balanced':
      default:
        return 'Bugün dengeli ilerliyorsun.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getAuraStatus();
    final auraColor = _getAuraColor(status);
    final suggestion = _getSuggestion(status);
    final avatarPath = _getAvatarPath();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Dijital Beslenme İkizim',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Two-column layout ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left column: Avatar + Legend ───────────────
              Expanded(
                flex: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TwinAvatarSection(
                      avatarPath: avatarPath,
                      auraColor: auraColor,
                    ),
                    const SizedBox(height: 8),
                    const TwinLegendRow(),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Right column: Score + Grid + Suggestion + Button ──
              Expanded(
                flex: 11,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Health Score
                    HealthScoreSummaryCard(
                      score: healthScore,
                      maxScore: 100,
                      statusText: healthStatusText,
                    ),

                    const SizedBox(height: 8),

                    // 2×2 Metric Grid
                    TwinMetricGrid(
                      waterPercent: waterPercent,
                      caloriePercent: caloriePercent,
                      proteinPercent: proteinPercent,
                      activityPercent: activityPercent,
                      waterCurrentStr: waterCurrentStr,
                      waterGoalStr: waterGoalStr,
                      calorieCurrentStr: calorieCurrentStr,
                      calorieGoalStr: calorieGoalStr,
                      proteinCurrentStr: proteinCurrentStr,
                      proteinGoalStr: proteinGoalStr,
                      activityCurrentStr: activityCurrentStr,
                      activityGoalStr: activityGoalStr,
                    ),

                    const SizedBox(height: 8),

                    // Suggestion Card
                    TwinSuggestionCard(suggestionText: suggestion),

                    const SizedBox(height: 8),

                    // CTA Button
                    DailySuggestionButton(onTap: onSuggestionTap),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
