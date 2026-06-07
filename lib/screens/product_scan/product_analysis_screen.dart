import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/soft_card.dart';
import '../../models/product/product_model.dart';
import '../../models/user_health_profile.dart';
import '../../services/analysis/product_suitability_service.dart';
import '../../repositories/user_health_profile_repository.dart';

class ProductAnalysisScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductAnalysisScreen({super.key, this.product});

  @override
  State<ProductAnalysisScreen> createState() => _ProductAnalysisScreenState();
}

class _ProductAnalysisScreenState extends State<ProductAnalysisScreen> {
  final ProductSuitabilityService _suitabilityService = ProductSuitabilityService();
  UserHealthProfile? _profile;
  String _chefRayInsight = "Hesaplanıyor...";
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndAnalyze();
  }

  Future<void> _loadProfileAndAnalyze() async {
    if (widget.product == null) {
      setState(() {
        _isLoadingProfile = false;
        _chefRayInsight = "Ürün bilgisi bulunamadı.";
      });
      return;
    }

    try {
      final profile = await UserHealthProfileRepository.instance.getCurrentUserHealthProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _chefRayInsight = _suitabilityService.analyzeSuitability(widget.product!, profile: _profile);
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chefRayInsight = _suitabilityService.analyzeSuitability(widget.product!);
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ürün Analizi')),
        body: const Center(child: Text('Ürün bilgisi alınamadı.')),
      );
    }

    final hasWarning = _chefRayInsight.contains('DİKKAT') || _chefRayInsight.contains('dikkat') || _chefRayInsight.contains('kaçınmalısın');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text('Ürün İçeriği Analizi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Product Image
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: product.imageUrl != null
                        ? Image.network(product.imageUrl!, fit: BoxFit.contain)
                        : Center(
                            child: Icon(
                              Icons.fastfood_rounded,
                              size: 100,
                              color: AppColors.textLight.withValues(alpha: 0.1),
                            ),
                          ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            product.brand ?? 'Marka bilgisi yok',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.name ?? 'İsimsiz ürün',
                          style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 26),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scores Row
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreWidget(
                          title: 'Nutri-Score',
                          score: product.nutriScore ?? '?',
                          color: _getNutriScoreColor(product.nutriScore),
                          description: _getNutriScoreDesc(product.nutriScore),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ScoreWidget(
                          title: 'NOVA Grubu',
                          score: product.novaGroup ?? '?',
                          color: _getNovaColor(product.novaGroup),
                          description: _getNovaDesc(product.novaGroup),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ChefRay Analysis Card
                  SoftCard(
                    padding: const EdgeInsets.all(20),
                    hasGreenGlow: !hasWarning && !_isLoadingProfile,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isLoadingProfile 
                                    ? Colors.blue.withValues(alpha: 0.1) 
                                    : (!hasWarning ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Image.asset(
                                  _isLoadingProfile 
                                      ? 'assets/mascot/ray_scanning.png' 
                                      : (!hasWarning ? 'assets/mascot/ray_success.png' : 'assets/mascot/ray_thinking.png'),
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, err, stk) {
                                    debugPrint('Mascot asset not found, fallback icon used.');
                                    return Icon(
                                      _isLoadingProfile 
                                          ? Icons.hourglass_empty_rounded 
                                          : (!hasWarning ? Icons.verified_rounded : Icons.warning_rounded),
                                      color: _isLoadingProfile 
                                          ? Colors.blue 
                                          : (!hasWarning ? Colors.green : Colors.orange),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ChefRay Yorumu', style: AppTextStyles.h3),
                                  const SizedBox(height: 8),
                                  Text(
                                    _chefRayInsight,
                                    style: AppTextStyles.bodyMedium.copyWith(height: 1.4, color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Nutrients Header
                  Text('100g İçin Besin Değerleri', style: AppTextStyles.h2.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 16),

                  // Nutrients List
                  if (product.calories != null)
                    _NutrientItem(
                      name: 'Enerji (Kalori)',
                      amount: '${product.calories} kcal',
                      percentage: (product.calories! / 800).clamp(0.0, 1.0),
                      color: Colors.blueGrey,
                    ),
                  if (product.protein != null)
                    _NutrientItem(
                      name: 'Protein',
                      amount: '${product.protein} g',
                      percentage: (product.protein! / 30).clamp(0.0, 1.0),
                      color: Colors.blue,
                    ),
                  if (product.sugars != null)
                    _NutrientItem(
                      name: 'Şeker',
                      amount: '${product.sugars} g',
                      percentage: (product.sugars! / 30).clamp(0.0, 1.0),
                      color: (product.sugars! > 15) ? Colors.red : Colors.green,
                    ),
                  if (product.fat != null)
                    _NutrientItem(
                      name: 'Yağ',
                      amount: '${product.fat} g',
                      percentage: (product.fat! / 30).clamp(0.0, 1.0),
                      color: (product.fat! > 20) ? Colors.orange : Colors.green,
                    ),
                  if (product.saturatedFat != null)
                    _NutrientItem(
                      name: 'Doymuş Yağ',
                      amount: '${product.saturatedFat} g',
                      percentage: (product.saturatedFat! / 10).clamp(0.0, 1.0),
                      color: (product.saturatedFat! > 5) ? Colors.red : Colors.green,
                    ),
                  if (product.carbs != null)
                    _NutrientItem(
                      name: 'Karbonhidrat',
                      amount: '${product.carbs} g',
                      percentage: (product.carbs! / 60).clamp(0.0, 1.0),
                      color: Colors.indigo,
                    ),
                  if (product.fiber != null)
                    _NutrientItem(
                      name: 'Lif',
                      amount: '${product.fiber} g',
                      percentage: (product.fiber! / 10).clamp(0.0, 1.0),
                      color: Colors.teal,
                    ),
                  if (product.salt != null)
                    _NutrientItem(
                      name: 'Tuz',
                      amount: '${product.salt} g',
                      percentage: (product.salt! / 3).clamp(0.0, 1.0),
                      color: (product.salt! > 1.5) ? Colors.red : Colors.green,
                    ),
                    
                  if (product.calories == null && product.protein == null && product.fat == null)
                     Text('Besin değeri bilgisi bulunmuyor (Veri Yok).', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  
                  const SizedBox(height: 24),
                  if (product.ingredientsText != null && product.ingredientsText!.isNotEmpty) ...[
                    Text('İçindekiler', style: AppTextStyles.h2.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    Text(product.ingredientsText!, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 24),
                  ],
                  
                  if (product.allergens.isNotEmpty) ...[
                    Text('Alerjenler', style: AppTextStyles.h2.copyWith(fontSize: 18, color: Colors.redAccent)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.allergens.map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(e.toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNutriScoreColor(String? score) {
    switch (score?.toUpperCase()) {
      case 'A': return const Color(0xFF008b4c);
      case 'B': return const Color(0xFF80c14a);
      case 'C': return const Color(0xFFfecd00);
      case 'D': return const Color(0xFFee8100);
      case 'E': return const Color(0xFFe63e11);
      default: return Colors.grey;
    }
  }

  String _getNutriScoreDesc(String? score) {
    switch (score?.toUpperCase()) {
      case 'A': return 'Çok İyi';
      case 'B': return 'İyi';
      case 'C': return 'Orta';
      case 'D': return 'Zayıf';
      case 'E': return 'Çok Zayıf';
      default: return 'Bilinmiyor';
    }
  }

  Color _getNovaColor(String? nova) {
    switch (nova) {
      case '1': return Colors.green;
      case '2': return Colors.lightGreen;
      case '3': return Colors.orange;
      case '4': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getNovaDesc(String? nova) {
    switch (nova) {
      case '1': return 'İşlenmemiş';
      case '2': return 'İşlenmiş İçerik';
      case '3': return 'İşlenmiş';
      case '4': return 'Aşırı İşlenmiş';
      default: return 'Bilinmiyor';
    }
  }
}

class _ScoreWidget extends StatelessWidget {
  final String title;
  final String score;
  final Color color;
  final String description;

  const _ScoreWidget({
    required this.title,
    required this.score,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            score,
            style: AppTextStyles.displayMedium.copyWith(color: color, fontSize: 42, height: 1.0),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              description,
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientItem extends StatelessWidget {
  final String name;
  final String amount;
  final double percentage;
  final Color color;

  const _NutrientItem({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              Text(amount, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
