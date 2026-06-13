import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AnalysisReadyCard extends StatelessWidget {
  final bool isAnalysisReady;
  final VoidCallback onCreateDietPlan;
  final VoidCallback onUploadTap;
  final VoidCallback onSummaryTap;

  const AnalysisReadyCard({
    super.key,
    required this.isAnalysisReady,
    required this.onCreateDietPlan,
    required this.onUploadTap,
    required this.onSummaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sol alan (Görsel %32-36)
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 14,
                  top: 20,
                  bottom: 20,
                  right: 8,
                ),
                child: Image.asset(
                  'assets/analiz.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.analytics_rounded,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),

            // Sağ alan
            Expanded(
              flex: 65,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isAnalysisReady
                          ? 'Analizlerin hazır'
                          : 'Henüz analiz yapılmadı',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        fontFamily: 'SF Pro Display',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAnalysisReady
                          ? 'Kan değerlerin ve beslenme tercihlerin analiz edildi. Sana uygun planı oluşturabilirsin.'
                          : 'Diyet listeni ve kan tahlilini yükleyerek kişisel önerilerini oluşturabilirsin.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                        fontSize: 12.5,
                        fontFamily: 'SF Pro Display',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    if (isAnalysisReady) ...[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            _AnalysisChip(
                              icon: Icons.water_drop_rounded,
                              label: 'Kan Analizi',
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(width: 4),
                            _AnalysisChip(
                              icon: Icons.person_rounded,
                              label: 'Diyet Profili',
                              color: Colors.green.shade500,
                            ),
                            const SizedBox(width: 4),
                            _AnalysisChip(
                              icon: Icons.favorite_rounded,
                              label: 'Tercihler',
                              color: Colors.purple.shade400,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Ana buton
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: ElevatedButton(
                          onPressed: isAnalysisReady
                              ? onCreateDietPlan
                              : onUploadTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isAnalysisReady
                                        ? 'Kişisel Diyet Listesi Oluştur'
                                        : 'Hemen Yükle',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (isAnalysisReady) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: onSummaryTap,
                          child: Text(
                            'Analiz Özeti  >',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AnalysisChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
