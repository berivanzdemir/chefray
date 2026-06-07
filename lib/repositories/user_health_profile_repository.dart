import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_health_profile.dart';

/// Repository for reading/writing user health profiles and the
/// profile_setup_completed flag in Supabase.
class UserHealthProfileRepository {
  UserHealthProfileRepository._();
  static final UserHealthProfileRepository instance =
      UserHealthProfileRepository._();

  final SupabaseClient _client = Supabase.instance.client;

  /// In-memory cache so GoRouter's synchronous redirect can check
  /// profile_setup_completed without an async DB call.
  bool? cachedProfileSetupCompleted;

  /// Returns the current authenticated user ID, or throws a user-friendly
  /// exception if no session exists.
  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    return id;
  }

  // ── Health profile CRUD ───────────────────────────────────────────────

  Future<UserHealthProfile?> getCurrentUserHealthProfile() async {
    final uid = _currentUserId;
    final data = await _client
        .from('user_health_profiles')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (data == null) return null;
    return UserHealthProfile.fromJson(data);
  }

  Future<void> upsertCurrentUserHealthProfile(
      UserHealthProfile profile) async {
    final uid = _currentUserId;
    final json = profile.copyWith(userId: uid).toJson();
    await _client
        .from('user_health_profiles')
        .upsert(json, onConflict: 'user_id');
  }

  // ── Profile setup flag ────────────────────────────────────────────────

  Future<bool> isProfileSetupCompleted() async {
    try {
      final uid = _currentUserId;
      final data = await _client
          .from('profiles')
          .select('profile_setup_completed')
          .eq('id', uid)
          .maybeSingle();
      final result = data?['profile_setup_completed'] == true;
      cachedProfileSetupCompleted = result;
      return result;
    } catch (_) {
      cachedProfileSetupCompleted = false;
      return false;
    }
  }

  Future<void> markProfileSetupCompleted() async {
    final uid = _currentUserId;
    await _client
        .from('profiles')
        .upsert({
          'id': uid,
          'profile_setup_completed': true,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
    cachedProfileSetupCompleted = true;
  }
}
