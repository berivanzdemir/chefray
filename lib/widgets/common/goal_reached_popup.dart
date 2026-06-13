import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:confetti/confetti.dart';

class GoalReachedPopup extends StatefulWidget {
  final VoidCallback onNewGoalTap;

  const GoalReachedPopup({super.key, required this.onNewGoalTap});

  static void show(BuildContext context, {required VoidCallback onNewGoalTap}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: GoalReachedPopup(onNewGoalTap: onNewGoalTap),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GoalReachedPopup> createState() => _GoalReachedPopupState();
}

class _GoalReachedPopupState extends State<GoalReachedPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) debugPrint('Goal success popup opened');

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    if (kDebugMode) {
      debugPrint('Confetti:');
      debugPrint('- confettiControllerCreated');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _confettiController.play();
        if (kDebugMode) debugPrint('- confettiPlayCalled');
        if (kDebugMode) debugPrint('- blastMode: explosive_center');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _confettiController.stop();
            if (kDebugMode) debugPrint('- confettiStopCalled');
          }
        });
      }
    });

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confettiController.stop();
    if (kDebugMode) debugPrint('- confettiStopCalled');
    _confettiController.dispose();
    if (kDebugMode) debugPrint('- confettiDisposed');
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Ana Kart
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 40),
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHighest : Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Statik konfeti arka planı (Kart sınırları içine kilitlendi, taşmaz)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/confeti.png',
                      height: 120,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),

                  // İçerik
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Başarı Rozeti
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE8F5E9,
                              ), // Açık yeşil / mint
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF81C784),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '%100 tamamlandı',
                                  style: TextStyle(
                                    color: Color(0xFF388E3C), // Koyu yeşil
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Başlık
                          Text(
                            'Tebrikler! Hedefine ulaştın!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(
                                      0xFF1B2A22,
                                    ), // Koyu başlık rengi
                              fontFamily: 'SF Pro Display',
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Açıklama
                          Text(
                            'Harika iş çıkardın. Bu başarıyı hak ettin!\nKendine küçük bir ödül ver ve bu güzel anın tadını çıkar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Kalpli İnce Çizgi Ayırıcı
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: const Color(0xFFC8E6C9),
                                  thickness: 1.5,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: Color(0xFFA5D6A7),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: const Color(0xFFC8E6C9),
                                  thickness: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Ödül Önerisi Alanı
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cupcake ikonu
                              Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.cake_outlined,
                                  size: 28,
                                  color: Color(0xFF81C784),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Bugün sevdiğin bir tatlı ya da keyifli bir öğünle kendini kutlayabilirsin.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF4B5563),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Ana Buton
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onNewGoalTap();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF10B981,
                                ), // ChefRay yeşiline yakın canlı yeşil
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Yeni hedef ekle',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 18,
                                  ), // ✨ ikonu yerine
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Zıplayan Yıldız Görseli
          Positioned(
            top: -20, // Kartın üstünden taşıyor
            child: ScaleTransition(
              scale: _bounceAnimation,
              child: Image.asset(
                'assets/yildiz.png',
                width: 110,
                height: 110,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.star_rounded,
                  size: 110,
                  color: Color(0xFFFFC107),
                ),
              ),
            ),
          ),

          // Kapatma Butonu (X)
          Positioned(
            top: 52, // Kart margin top'ına göre ayarlandı
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),

          // Merkezden Patlayan Konfeti Overlay (YENİ)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 100,
                  ), // Yıldızın hemen altı/kartın üst ortası gibi bir nokta
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    emissionFrequency: 0.05,
                    numberOfParticles: 25,
                    gravity: 0.25,
                    colors: const [
                      Color(0xFF10B981),
                      Color(0xFFF59E0B),
                      Color(0xFF3B82F6),
                      Color(0xFFEC4899),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
