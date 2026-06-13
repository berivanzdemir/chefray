import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/primary_button.dart';
import '../../services/auth/supabase_auth_service.dart';
import '../../services/auth/auth_preferences_service.dart';
import '../../repositories/user_health_profile_repository.dart';
import 'widgets/auth_input_field.dart';
import 'widgets/auth_social_button.dart';
import 'widgets/auth_divider.dart';
import 'widgets/forgot_password_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _socialLoading; // 'google' | 'apple' | null

  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final StreamSubscription<AuthState> _authStateSub;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    final initialSessionExists =
        SupabaseAuthService.instance.currentSession != null;
    if (kDebugMode) {
      debugPrint('Session exists: $initialSessionExists');
    }

    _authStateSub = SupabaseAuthService.instance.authStateChanges.listen((
      data,
    ) async {
      if (!mounted) return;

      final sessionExists = data.session != null;
      if (kDebugMode) {
        debugPrint('Session exists: $sessionExists');
      }

      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        // Sosyal giriş tamamlandığında tetiklenir
        if (_socialLoading != null) {
          setState(() => _socialLoading = null);
        }
        final isSetupComplete = await UserHealthProfileRepository.instance
            .isProfileSetupCompleted();
        if (!mounted) return;
        if (isSetupComplete) {
          context.go('/home');
        } else {
          context.go('/health-profile-setup');
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeCtrl.forward();
        _slideCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _authStateSub.cancel();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final result = await SupabaseAuthService.instance.signInWithEmail(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      await AuthPreferencesService.instance.setRememberMe(_rememberMe);
      if (!mounted) return;
      final isSetupComplete = await UserHealthProfileRepository.instance
          .isProfileSetupCompleted();
      if (!mounted) return;
      if (isSetupComplete) {
        context.go('/home');
      } else {
        context.go('/health-profile-setup');
      }
    } else {
      _showErrorSnackbar(result.errorMessage ?? 'Giriş başarısız.');
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    if (_socialLoading != null) return;
    setState(() => _socialLoading = provider);

    if (kDebugMode) {
      debugPrint('$provider button tapped');
    }

    AuthResult? result;
    if (provider == 'Google') {
      if (kDebugMode) {
        debugPrint('Google auth started');
      }
      result = await SupabaseAuthService.instance.signInWithGoogle();
      if (result.isSuccess) {
        if (kDebugMode) {
          debugPrint('Google auth success');
        }
      } else {
        if (kDebugMode) {
          debugPrint('Google auth failure');
        }
      }
    } else if (provider == 'Apple') {
      if (kDebugMode) {
        debugPrint('Apple placeholder shown');
      }
      result = await SupabaseAuthService.instance.signInWithApplePlaceholder();
    }

    if (!mounted) return;

    // Eğer işlem başarısızsa loading'i kaldırıp hatayı göster
    if (result != null && !result.isSuccess) {
      setState(() => _socialLoading = null);
      _showErrorSnackbar(result.errorMessage ?? '$provider girişi başarısız.');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFFF4D6A).withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Form(
                key: _formKey,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),

                            // ── Logo ──────────────────────────────────────
                            Center(child: AppLogo(size: 72, showText: true)),
                            const SizedBox(height: 32),

                            // ── Hero text ─────────────────────────────────
                            _HeroTextBlock(
                              title: 'Tekrar Hoş\nGeldin 👋',
                              subtitle:
                                  'Sağlıklı tarifler seni bekliyor. Giriş yap\nve kişisel mutfağına dön.',
                            ),
                            const SizedBox(height: 36),

                            // ── Form Fields ───────────────────────────────
                            AuthInputField(
                              controller: _emailCtrl,
                              hint: 'E-posta adresi',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 14),
                            AuthInputField(
                              controller: _passCtrl,
                              hint: 'Şifre',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePass,
                              textInputAction: TextInputAction.done,
                              validator: _validatePassword,
                              suffixWidget: _VisibilityToggle(
                                isObscured: _obscurePass,
                                onTap: () => setState(
                                  () => _obscurePass = !_obscurePass,
                                ),
                              ),
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),
                            const SizedBox(height: 16),

                            // ── Remember me + Forgot ──────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _RememberMeToggle(
                                  value: _rememberMe,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      ForgotPasswordSheet.show(context),
                                  child: Text(
                                    'Şifremi Unuttum',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // ── Primary CTA ───────────────────────────────
                            PrimaryButton(
                              text: 'Giriş Yap',
                              onPressed: _handleLogin,
                              isLoading: _isLoading,
                              trailingIcon: Icons.arrow_forward_rounded,
                            ),
                            const SizedBox(height: 24),

                            // ── Divider ───────────────────────────────────
                            const AuthDivider(),
                            const SizedBox(height: 20),

                            // ── Social Buttons ────────────────────────────
                            AuthSocialButton(
                              label: 'Google ile giriş yap',
                              iconAsset: 'google',
                              isLoading: _socialLoading == 'google',
                              onTap: () => _handleSocialLogin('Google'),
                            ),
                            const SizedBox(height: 12),
                            AuthSocialButton(
                              label: 'Apple ile giriş yap',
                              iconAsset: 'apple',
                              isLoading: _socialLoading == 'apple',
                              onTap: () => _handleSocialLogin('Apple'),
                            ),

                            // ── Spacer + Register link ────────────────────
                            const Spacer(),
                            const SizedBox(height: 28),
                            _AuthSwitchRow(
                              question: 'Hesabın yok mu? ',
                              actionText: 'Kayıt Ol',
                              onTap: () => context.go('/register'),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
    final regex = RegExp(r'^[\w\-.]+@[\w\-]+\.\w+$');
    if (!regex.hasMatch(v.trim())) return 'Geçerli bir e-posta gir';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Şifre gerekli';
    if (v.length < 6) return 'Şifre en az 6 karakter olmalı';
    return null;
  }
}

// ── Internal sub-widgets ──────────────────────────────────────────────────────

class _HeroTextBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeroTextBlock({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.displayLarge),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTextStyles.bodyLarge.copyWith(height: 1.6)),
      ],
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool isObscured;
  final VoidCallback onTap;
  const _VisibilityToggle({required this.isObscured, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isObscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            key: ValueKey(isObscured),
            color: AppColors.textLight,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _RememberMeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _RememberMeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AppColors.primary : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: AppColors.textDark,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text('Beni Hatırla', style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}

class _AuthSwitchRow extends StatelessWidget {
  final String question;
  final String actionText;
  final VoidCallback onTap;
  const _AuthSwitchRow({
    required this.question,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMedium),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
