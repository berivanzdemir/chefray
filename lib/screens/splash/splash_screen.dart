import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/app_logo.dart';
import '../../repositories/user_health_profile_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  double _progress = 0.0;
  String _statusText = "Hazırlanıyor...";

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));

    _animCtrl.forward();
    _runStartupSequence();
  }

  Future<void> _updateStatus(double progress, String text) async {
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _statusText = text;
    });
    // Animasyon ve okunabilirlik için küçük bir bekleme
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _runStartupSequence() async {
    final stopwatch = Stopwatch()..start();

    // 1. Başlangıç gecikmesi (Animasyonun rahat görülmesi için)
    await Future.delayed(const Duration(milliseconds: 400));
    await _updateStatus(0.2, "Bağlantı kontrol ediliyor...");

    // 2. Oturum (Auth) Kontrolü
    await _updateStatus(0.4, "Oturum durumu kontrol ediliyor...");
    final session = Supabase.instance.client.auth.currentSession;
    final hasSession = session != null;

    // 3. E-posta doğrulama kontrolü
    // Supabase'de e-posta doğrulanmadan login olunabiliyorsa emailConfirmedAt check edilebilir.
    // Not: ChefRay'de genelde magic link veya email configine göre bu durum değişir.
    // O yüzden şimdilik asıl odak hasSession üzerinde.

    // 4. Profil Kontrolü (Eğer giriş yapıldıysa)
    await _updateStatus(0.7, "Profil bilgileri alınıyor...");
    bool isSetupComplete = false;
    if (hasSession) {
      try {
        isSetupComplete = await UserHealthProfileRepository.instance
            .isProfileSetupCompleted();
      } catch (e) {
        debugPrint("Profil kontrol hatası: $e");
      }
    }

    await _updateStatus(0.9, "Sana özel öneriler hazırlanıyor...");

    // 5. Minimum Splash süresi kontrolü (Çok hızlı geçmemesi için)
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 1800) {
      await Future.delayed(Duration(milliseconds: 1800 - elapsed));
    }

    await _updateStatus(1.0, "Uygulama başlatılıyor...");
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    // Yönlendirme Mantığı
    if (!hasSession) {
      context.go('/onboarding');
    } else {
      // E-posta onayı (emailConfirmedAt) zorunluysa burada check edip /auth'a atabilirsiniz.
      // Ancak app_router mantığıyla uyumlu ilerliyoruz.
      if (isSetupComplete) {
        context.go('/home');
      } else {
        context.go('/health-profile-setup');
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Widget _buildBackgroundIcons(bool isDark) {
    // Çok silik arka plan ikonları
    final color = isDark
        ? Colors.white.withValues(alpha: 0.02)
        : AppColors.primary.withValues(alpha: 0.03);
    return Stack(
      children: [
        Positioned(
          top: 80,
          left: -20,
          child: Icon(Icons.eco_rounded, size: 140, color: color),
        ),
        Positioned(
          top: 220,
          right: -40,
          child: Icon(Icons.local_dining_rounded, size: 160, color: color),
        ),
        Positioned(
          bottom: 250,
          left: 30,
          child: Icon(Icons.egg_rounded, size: 110, color: color),
        ),
        Positioned(
          bottom: 80,
          right: 10,
          child: Icon(Icons.set_meal_rounded, size: 140, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Açık temada mint gradient (merkez beyaz, dışlar çok açık mint)
    // Koyu temada ChefRay'e uygun koyu yeşil degrade
    final bgColor1 = isDark ? const Color(0xFF0F241E) : Colors.white;
    final bgColor2 = isDark ? const Color(0xFF081410) : const Color(0xFFF2FAF6);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [bgColor1, bgColor2],
            radius: 1.2,
            center: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundIcons(isDark),
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Hafif yeşil glow efekti
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: isDark ? 0.2 : 0.08,
                                  ),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          const AppLogo(size: 140, showText: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Sağlıklı tarifler • Akıllı öneriler",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? const Color(0xFFB7CCC5)
                              : AppColors.textMedium,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Alt Kısım - Progress Bar
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      width: 180,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E3A31)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        height: 4,
                        width: 180 * _progress,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusText,
                        key: ValueKey<String>(_statusText),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? const Color(0xFFB7CCC5)
                              : AppColors.textMedium,
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
    );
  }
}
