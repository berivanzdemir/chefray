import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class AnalysisCard extends StatelessWidget {
  final bool hasAnalysis;

  const AnalysisCard({
    super.key,
    required this.hasAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Image
            Expanded(
              flex: 4,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 20, bottom: 20, right: 4),
                  child: Image.asset(
                    'assets/analiz.jpeg',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(Icons.analytics_rounded,
                          color: Theme.of(context).colorScheme.primary, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            
            // Right Content
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hasAnalysis
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
                      hasAnalysis
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

                    if (hasAnalysis) ...[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            _Chip(
                                icon: Icons.water_drop_rounded,
                                label: 'Kan Analizi',
                                color: Colors.red.shade400),
                            const SizedBox(width: 6),
                            _Chip(
                                icon: Icons.person_rounded,
                                label: 'Diyet Profili',
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            _Chip(
                                icon: Icons.favorite_rounded,
                                label: 'Tercihler',
                                color: Colors.purple.shade400),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (hasAnalysis) {
                              context.push('/personal-diet');
                            } else {
                              context.push(
                                  '/diet-upload?uploadType=dietPdf');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    hasAnalysis
                                        ? 'Kişisel Diyet Listesi Oluştur'
                                        : 'Hemen Yükle',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: Theme.of(context).colorScheme.surface),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (hasAnalysis) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/analysis-history'),
                          child: Text(
                            'Analiz Özeti  >',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
