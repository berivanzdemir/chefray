import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      step: '1 / 3',
      title: 'Diyetini ',
      titleHighlight: 'Tara',
      subtitle: 'Diyet listeni fotoğrafla veya yükle,\nanında analiz edelim.',
      bottomIcon: Icons.restaurant_menu_rounded,
      bottomText: 'Listeyi yükle, ',
      bottomHighlight: 'gerisini bize bırak.',
      visualType: _VisualType.scan,
    ),
    _OnboardingData(
      step: '2 / 3',
      title: 'Akıllı ',
      titleHighlight: 'Analiz',
      subtitle: 'Kalori, makro, kısıtlar ve hedeflerin\nsenin için analiz edilir.',
      bottomIcon: Icons.bar_chart_rounded,
      bottomText: 'Verilere dayalı önerilerle\n',
      bottomHighlight: 'en doğru tarifleri',
      bottomSuffix: ' sunarız.',
      visualType: _VisualType.analysis,
    ),
    _OnboardingData(
      step: '3 / 3',
      title: 'Yemeğini ',
      titleHighlight: 'Gör',
      subtitle: 'Tariflerinin her bileşenini keşfet,\nne yediğini gerçekten öğren.',
      bottomIcon: Icons.restaurant_rounded,
      bottomText: 'Daha bilinçli seçimler yap,\n',
      bottomHighlight: 'hedeflerine',
      bottomSuffix: ' daha hızlı ulaş.',
      visualType: _VisualType.exploded,
    ),
  ];

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      context.go('/auth');
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),
            // Bottom controls
            if (_currentPage == 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    PrimaryButton(
                      text: 'Başla',
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: () => context.go('/auth'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/auth'),
                      child: Text('Şimdi değil',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight)),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button (hide on first page)
                    _currentPage == 0
                        ? const SizedBox(width: 52)
                        : _CircleNavButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: _prevPage,
                          ),
                    // Dots
                    Row(
                      children: List.generate(3, (i) => _Dot(isActive: i == _currentPage)),
                    ),
                    // Forward button
                    _CircleNavButton(
                      icon: Icons.arrow_forward_rounded,
                      onTap: _nextPage,
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────
enum _VisualType { scan, analysis, exploded }

class _OnboardingData {
  final String step, title, titleHighlight, subtitle;
  final IconData bottomIcon;
  final String bottomText, bottomHighlight;
  final String? bottomSuffix;
  final _VisualType visualType;

  const _OnboardingData({
    required this.step,
    required this.title,
    required this.titleHighlight,
    required this.subtitle,
    required this.bottomIcon,
    required this.bottomText,
    required this.bottomHighlight,
    this.bottomSuffix,
    required this.visualType,
  });
}

// ── Page widget ────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(data.step,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          // Title
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(text: data.title, style: AppTextStyles.onboardingTitle),
              TextSpan(
                  text: data.titleHighlight,
                  style: AppTextStyles.onboardingTitle.copyWith(color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 12),
          Text(data.subtitle, textAlign: TextAlign.center, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 32),
          // Visual area
          _buildVisual(data.visualType),
          const SizedBox(height: 28),
          // Bottom icon + text
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(data.bottomIcon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMedium),
              children: [
                TextSpan(text: data.bottomText),
                TextSpan(
                    text: data.bottomHighlight,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                if (data.bottomSuffix != null) TextSpan(text: data.bottomSuffix),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVisual(_VisualType type) {
    switch (type) {
      case _VisualType.scan:
        return _ScanVisual();
      case _VisualType.analysis:
        return _AnalysisVisual();
      case _VisualType.exploded:
        return _ExplodedVisual();
    }
  }
}

// ── Visual: Scan (Page 1) ──────────────────────────────────
class _ScanVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background card (tilted)
          Positioned(
            left: 40, right: 40, top: 10,
            child: Transform.rotate(
              angle: 0.04,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
              ),
            ),
          ),
          // Main diet card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('DİYET LİSTESİ', style: AppTextStyles.labelMedium.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                _mealSection('🔥', 'KAHVALTI', ['2 dilim tam buğday ekmeği', '1 haşlanmış yumurta', '5 adet zeytin']),
                const SizedBox(height: 12),
                _mealSection('🍽️', 'ÖĞLE YEMEĞİ', ['150g ızgara tavuk', '4 yemek kaşığı bulgur pilavı', 'Salata']),
                const SizedBox(height: 12),
                _mealSection('🌙', 'AKŞAM YEMEĞİ', ['150g somon', '1 kase yeşil salata']),
              ],
            ),
          ),
          // Scan corners
          Positioned(top: 15, left: 30, child: _ScanCorner(isTop: true, isLeft: true)),
          Positioned(top: 15, right: 30, child: _ScanCorner(isTop: true, isLeft: false)),
          Positioned(bottom: 5, left: 30, child: _ScanCorner(isTop: false, isLeft: true)),
          Positioned(bottom: 5, right: 30, child: _ScanCorner(isTop: false, isLeft: false)),
          // Green scan line
          Positioned(
            left: 36, right: 36, top: 100,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withValues(alpha: 0),
                  AppColors.primary.withValues(alpha: 0.6),
                  AppColors.primary.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _mealSection(String emoji, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(title, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text('• $item', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
            )),
      ],
    );
  }
}

class _ScanCorner extends StatelessWidget {
  final bool isTop, isLeft;
  const _ScanCorner({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20, height: 20,
      child: CustomPaint(painter: _CornerPainter(isTop: isTop, isLeft: isLeft)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop, isLeft;
  _CornerPainter({required this.isTop, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Visual: Analysis (Page 2) ──────────────────────────────
class _AnalysisVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _miniCard('🔥', 'Günlük Kalori', '1500', 'kcal', 'Hedefe uygun')),
              const SizedBox(width: 12),
              Expanded(child: _macroCard()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _listCard('🎯', 'Hedefler', ['Yüksek Protein', 'Glutensiz', 'Düşük Şeker'])),
              const SizedBox(width: 12),
              Expanded(child: _listCard('⚠️', 'Yasaklı / Alerjenler', ['Gluten', 'Fındık', 'Laktoz'])),
            ],
          ),
          const SizedBox(height: 12),
          _mealDistribution(),
        ],
      ),
    );
  }

  static Widget _miniCard(String emoji, String title, String value, String unit, String badge) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(child: Text(title, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark))),
          ]),
          const SizedBox(height: 8),
          RichText(text: TextSpan(children: [
            TextSpan(text: value, style: AppTextStyles.h1.copyWith(fontSize: 28)),
            TextSpan(text: ' $unit', style: AppTextStyles.bodySmall),
          ])),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.check_circle, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(badge, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontSize: 10)),
          ]),
        ],
      ),
    );
  }

  static Widget _macroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Makro Dağılımı', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 44, height: 44,
                child: CustomPaint(painter: _DonutPainter()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _macroRow('Protein', '%35', AppColors.protein),
                    _macroRow('Karbonhidrat', '%40', AppColors.carbs),
                    _macroRow('Yağ', '%25', AppColors.fat),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _macroRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 9), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 4),
          Text(value, style: AppTextStyles.labelSmall.copyWith(fontSize: 9, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  static Widget _listCard(String emoji, String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(child: Text(title, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 11))),
          ]),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(children: [
                  Container(width: 5, height: 5, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(item, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                ]),
              )),
        ],
      ),
    );
  }

  static Widget _mealDistribution() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Text('🍽️', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text('Öğün Dağılımı', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const Spacer(),
          _mealDot('Kahvaltı', '%25'),
          const SizedBox(width: 12),
          _mealDot('Öğle', '%30'),
          const SizedBox(width: 12),
          _mealDot('Akşam', '%30'),
          const SizedBox(width: 12),
          _mealDot('Ara Öğün', '%15'),
        ],
      ),
    );
  }

  static Widget _mealDot(String label, String pct) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
        Text(pct, style: AppTextStyles.labelSmall.copyWith(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    const sw = 6.0;
    final bg = Paint()..color = AppColors.divider..style = PaintingStyle.stroke..strokeWidth = sw;
    canvas.drawCircle(center, r, bg);
    final rect = Rect.fromCircle(center: center, radius: r);
    // Protein 35%
    canvas.drawArc(rect, -1.57, 2.2, false, Paint()..color = AppColors.protein..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
    // Carbs 40%
    canvas.drawArc(rect, 0.63, 2.51, false, Paint()..color = AppColors.carbs..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
    // Fat 25%
    canvas.drawArc(rect, 3.14, 1.57, false, Paint()..color = AppColors.fat..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Visual: Exploded (Page 3) ──────────────────────────────
class _ExplodedVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final double hPadding = w * 0.02;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Center food icon (Centered vertically and horizontally)
              Positioned(
                top: 108, // (320 - 104) / 2
                child: Container(
                  width: 104, 
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04), 
                        blurRadius: 10, 
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Center(child: Text('🥗', style: TextStyle(fontSize: 48))),
                ),
              ),

              // Floating ingredient chips (Top Left)
              Positioned(
                left: hPadding,
                top: 30,
                child: _ingredientChip('🐟', '150g Somon', '306 kcal'),
              ),
              // Floating ingredient chips (Top Right)
              Positioned(
                right: hPadding,
                top: 30,
                child: _ingredientChip('🥬', '50g Ispanak', '11 kcal'),
              ),
              // Floating ingredient chips (Bottom Left)
              Positioned(
                left: hPadding,
                bottom: 30,
                child: _ingredientChip('🥑', '50g Avokado', '80 kcal'),
              ),
              // Floating ingredient chips (Bottom Right)
              Positioned(
                right: hPadding,
                bottom: 30,
                child: _ingredientChip('🌾', '100g Kinoa', '120 kcal'),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _ingredientChip(String emoji, String name, String kcal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 11)),
              Text(kcal, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dot indicator ──────────────────────────────────────────
class _Dot extends StatelessWidget {
  final bool isActive;
  const _Dot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 10 : 8,
      height: isActive ? 10 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Circle nav button ──────────────────────────────────────
class _CircleNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _CircleNavButton({required this.icon, this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: isPrimary && enabled ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? AppColors.divider : AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: enabled ? AppColors.textDark : AppColors.textHint, size: 22),
      ),
    );
  }
}
