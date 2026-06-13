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
import '../../repositories/user_health_profile_repository.dart';
import 'widgets/auth_input_field.dart';
import 'widgets/auth_social_button.dart';
import 'widgets/auth_divider.dart';
import 'widgets/password_strength_bar.dart';
import 'widgets/kvkk_modal.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;
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

    // Listen for password changes to update strength bar
    _passCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _authStateSub.cancel();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      _showSnackbar('Lütfen kullanım koşullarını kabul edin.', isError: true);
      return;
    }
    setState(() => _isLoading = true);

    final result = await SupabaseAuthService.instance.signUpWithEmail(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      displayName: _nameCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (result.session != null) {
        // Email confirmation is off — user is signed in immediately.
        // Navigate to health profile setup so they complete onboarding.
        if (!mounted) return;
        await UserHealthProfileRepository.instance.isProfileSetupCompleted();
        if (!mounted) return;
        context.go('/health-profile-setup');
      } else {
        // Email confirmation required — stay on register screen and inform.
        if (!mounted) return;
        _showEmailVerificationDialog();
      }
    } else {
      _showSnackbar(result.errorMessage ?? 'Kayıt başarısız.', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFFF4D6A).withValues(alpha: 0.95)
            : const Color(0xFF2DFF88).withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text('E-postanı Doğrula', style: AppTextStyles.h2),
                const SizedBox(height: 10),
                Text(
                  'Hesabın oluşturuldu! Giriş yapmadan önce e-posta adresine '
                  'gönderilen doğrulama bağlantısına tıklaman gerekiyor.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Giriş Sayfasına Git',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.go('/auth');
                    },
                    trailingIcon: Icons.arrow_forward_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      _showSnackbar(
        result.errorMessage ?? '$provider girişi başarısız.',
        isError: true,
      );
    }
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
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 32),

                          // ── Back button + Logo row ─────────────────────
                          Row(
                            children: [
                              _BackButton(onTap: () => context.go('/auth')),
                              const Spacer(),
                              const AppLogo(size: 40, showText: false),
                              const Spacer(),
                              const SizedBox(width: 40),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // ── Hero text ──────────────────────────────────
                          _HeroTextBlock(
                            title: 'Hesap Oluştur',
                            subtitle:
                                'AI destekli kişisel mutfağına katıl.\nKan testi & beslenme analizin başlasın.',
                          ),
                          const SizedBox(height: 32),

                          // ── Step indicator ─────────────────────────────
                          const _StepIndicator(currentStep: 1, totalSteps: 2),
                          const SizedBox(height: 28),

                          // ── Form Fields ────────────────────────────────
                          AuthInputField(
                            controller: _nameCtrl,
                            hint: 'Ad Soyad',
                            icon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: _validateName,
                          ),
                          const SizedBox(height: 14),
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
                            textInputAction: TextInputAction.next,
                            validator: _validatePassword,
                            suffixWidget: _VisibilityToggle(
                              isObscured: _obscurePass,
                              onTap: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),

                          // ── Password strength ──────────────────────────
                          if (_passCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            PasswordStrengthBar(password: _passCtrl.text),
                          ],
                          const SizedBox(height: 14),

                          AuthInputField(
                            controller: _passConfirmCtrl,
                            hint: 'Şifreyi Onayla',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            validator: _validateConfirmPassword,
                            suffixWidget: _VisibilityToggle(
                              isObscured: _obscureConfirm,
                              onTap: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                            onFieldSubmitted: (_) => _handleRegister(),
                          ),
                          const SizedBox(height: 20),

                          // ── Terms checkbox ─────────────────────────────
                          _TermsRow(
                            value: _acceptedTerms,
                            onChanged: (v) =>
                                setState(() => _acceptedTerms = v),
                          ),
                          const SizedBox(height: 24),

                          // ── Primary CTA ────────────────────────────────
                          PrimaryButton(
                            text: 'Hesap Oluştur',
                            onPressed: _handleRegister,
                            isLoading: _isLoading,
                            trailingIcon: Icons.arrow_forward_rounded,
                          ),
                          const SizedBox(height: 24),

                          // ── Divider ────────────────────────────────────
                          const AuthDivider(),
                          const SizedBox(height: 20),

                          // ── Social Buttons ─────────────────────────────
                          AuthSocialButton(
                            label: 'Google ile kayıt ol',
                            iconAsset: 'google',
                            isLoading: _socialLoading == 'google',
                            onTap: () => _handleSocialLogin('Google'),
                          ),
                          const SizedBox(height: 12),
                          AuthSocialButton(
                            label: 'Apple ile kayıt ol',
                            iconAsset: 'apple',
                            isLoading: _socialLoading == 'apple',
                            onTap: () => _handleSocialLogin('Apple'),
                          ),
                          const SizedBox(height: 28),

                          // ── Switch to Login ────────────────────────────
                          _AuthSwitchRow(
                            question: 'Zaten hesabın var mı? ',
                            actionText: 'Giriş Yap',
                            onTap: () => context.go('/auth'),
                          ),
                          const SizedBox(height: 36),
                        ]),
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

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ad soyad gerekli';
    if (v.trim().length < 3) return 'En az 3 karakter olmalı';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
    final regex = RegExp(r'^[\w\-.]+@[\w\-]+\.\w+$');
    if (!regex.hasMatch(v.trim())) return 'Geçerli bir e-posta gir';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Şifre gerekli';
    if (v.length < 8) return 'En az 8 karakter olmalı';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Şifreyi onayla';
    if (v != _passCtrl.text) return 'Şifreler eşleşmiyor';
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
        Text(title, style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTextStyles.bodyLarge.copyWith(height: 1.6)),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Adım $currentStep / $totalSteps',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentStep / totalSteps,
              minHeight: 4,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _TermsRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated checkbox
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AnimatedContainer(
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
          ),
        ),
        const SizedBox(width: 10),
        // Rich text with tappable links
        Expanded(child: _TermsRichText(onToggle: () => onChanged(!value))),
      ],
    );
  }
}

/// Rich text block: plain text + tappable KVKK + tappable Gizlilik links.
class _TermsRichText extends StatelessWidget {
  final VoidCallback onToggle;
  const _TermsRichText({required this.onToggle});

  @override
  Widget build(BuildContext context) {
    // Use separate Text widgets for simplicity — avoids TapGestureRecognizer
    // memory management complexity inside a StatelessWidget.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Text(
            'Okudum ve kabul ediyorum: ',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => KvkkModal.showKvkk(context),
              child: Text(
                'KVKK Aydınlatma Metni',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                  height: 1.5,
                ),
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: Text(
                ' ve ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => KvkkModal.showPrivacy(context),
              child: Text(
                'Gizlilik Politikası',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
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
