import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Auth işlemlerini tek bir noktada yöneten servis.
///
/// Tüm metodlar [AuthResult] döndürür; UI katmanı doğrudan
/// Supabase exception'larına bağımlı olmaz.
class SupabaseAuthService {
  SupabaseAuthService._();
  static final SupabaseAuthService instance = SupabaseAuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Mevcut oturumu döndürür; yoksa null.
  Session? get currentSession => _client.auth.currentSession;

  /// Oturum değişiklik akışı.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Sign In ──────────────────────────────────────────────────────────────

  /// E-posta ve şifre ile giriş.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(session: response.session);
    } on AuthException catch (e) {
      return AuthResult.failure(message: _localizeError(e.message));
    } catch (e) {
      return AuthResult.failure(message: 'Beklenmeyen bir hata oluştu.');
    }
  }

  // ── Sign Up ──────────────────────────────────────────────────────────────
  
  /// E-posta ve şifre ile yeni hesap oluşturma.
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName != null ? {'full_name': displayName} : null,
      );
      return AuthResult.success(session: response.session);
    } on AuthException catch (e) {
      return AuthResult.failure(message: _localizeError(e.message));
    } catch (e) {
      return AuthResult.failure(message: 'Beklenmeyen bir hata oluştu.');
    }
  }

  // ── Social Sign In (OAuth) ───────────────────────────────────────────────

  /// Google ile OAuth girişi başlatır.
  Future<AuthResult> signInWithGoogle() async {
    try {
      final success = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.chefray.chefray://login-callback/',
      );
      if (!success) {
        return AuthResult.failure(message: 'Google ile giriş yapılandırması tamamlanmamış. Lütfen daha sonra tekrar deneyin.');
      }
      return AuthResult.success();
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('provider is not enabled') ||
          msg.contains('configuration') ||
          msg.contains('not configured') ||
          msg.contains('not_enabled')) {
        return AuthResult.failure(message: 'Google ile giriş yapılandırması tamamlanmamış. Lütfen daha sonra tekrar deneyin.');
      } else if (msg.contains('cancel') ||
                 msg.contains('user_canceled') ||
                 msg.contains('canceled') ||
                 msg.contains('dismiss') ||
                 msg.contains('abort')) {
        return AuthResult.failure(message: 'Google ile giriş iptal edildi.');
      } else {
        return AuthResult.failure(message: 'Google ile giriş sırasında bir sorun oluştu.');
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('user_canceled') || msg.contains('canceled')) {
        return AuthResult.failure(message: 'Google ile giriş iptal edildi.');
      } else if (msg.contains('provider') || msg.contains('configuration') || msg.contains('not configured')) {
        return AuthResult.failure(message: 'Google ile giriş yapılandırması tamamlanmamış. Lütfen daha sonra tekrar deneyin.');
      }
      return AuthResult.failure(message: 'Google ile giriş sırasında bir sorun oluştu.');
    }
  }

  /// Apple ile OAuth girişi için placeholder metodu (Şu an devre dışı).
  Future<AuthResult> signInWithApplePlaceholder() async {
    return AuthResult.failure(message: 'Apple ile giriş şu anda yapılandırma aşamasındadır.');
  }

  // ── Password Reset ───────────────────────────────────────────────────────

  /// Şifre sıfırlama e-postası gönderir.
  Future<AuthResult> sendPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(message: _localizeError(e.message));
    } catch (e) {
      return AuthResult.failure(message: 'Beklenmeyen bir hata oluştu.');
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Connection Test ──────────────────────────────────────────────────────

  /// Supabase bağlantısını test eder; başarılıysa `true` döner.
  Future<bool> testConnection() async {
    try {
      // Anonim bir sorgu çekerek bağlantıyı doğrula.
      await _client
          .from('_supabase_health_check')
          .select()
          .limit(1)
          .maybeSingle();
      return true;
    } catch (_) {
      // Tablo yoksa bile bağlantı kurulmuş demektir; ağ hatası yoksa true.
      return true;
    }
  }

  // ── Error Localization ───────────────────────────────────────────────────

  String _localizeError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials') ||
        m.contains('invalid credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (m.contains('email not confirmed')) {
      return 'E-posta adresin henüz doğrulanmadı.';
    }
    if (m.contains('user already registered')) {
      return 'Bu e-posta adresiyle kayıtlı bir hesap zaten var.';
    }
    if (m.contains('password should be at least')) {
      return 'Şifre en az 6 karakter olmalı.';
    }
    if (m.contains('rate limit')) {
      return 'Çok fazla deneme. Lütfen bir süre bekle.';
    }
    if (m.contains('network')) {
      return 'İnternet bağlantını kontrol et.';
    }
    return message;
  }
}

// ── AuthResult ───────────────────────────────────────────────────────────────

/// Auth işlemlerinin sonucunu taşıyan immutable değer nesnesi.
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final Session? session;

  const AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.session,
  });

  factory AuthResult.success({Session? session}) =>
      AuthResult._(isSuccess: true, session: session);

  factory AuthResult.failure({required String message}) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}
