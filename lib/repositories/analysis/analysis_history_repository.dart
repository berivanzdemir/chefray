import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/ai/analysis_results.dart';
import '../../models/analysis/analysis_history_item.dart';

/// SQL Schema TODO for developer reference:
/// 
/// ```sql
/// -- TODO: SQL Table Setup in Supabase
/// CREATE TABLE IF NOT EXISTS combined_analysis_results (
///   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
///   user_id UUID NOT NULL,
///   created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
///   summary TEXT NOT NULL,
///   nutrition_priorities JSONB NOT NULL DEFAULT '[]'::jsonb,
///   safety_notes JSONB NOT NULL DEFAULT '[]'::jsonb,
///   diet_analysis JSONB,
///   blood_analysis JSONB,
///   combined_analysis JSONB
/// );
/// 
/// -- Enable RLS
/// ALTER TABLE combined_analysis_results ENABLE ROW LEVEL SECURITY;
/// 
/// -- Select Policy
/// CREATE POLICY "Users can read own analysis history" ON combined_analysis_results
///   FOR SELECT USING (auth.uid() = user_id);
/// 
/// -- Insert Policy
/// CREATE POLICY "Users can insert own analysis history" ON combined_analysis_results
///   FOR INSERT WITH CHECK (auth.uid() = user_id);
/// ```
class AnalysisHistoryRepository {
  AnalysisHistoryRepository._();
  static final AnalysisHistoryRepository instance = AnalysisHistoryRepository._();

  static const String _localPrefsKey = 'chefray_local_analysis_history';

  // ── Retrieve User's Current ID ──────────────────────────
  String? _getUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  // ── Read History from local SharedPreferences ─────────────
  Future<List<AnalysisHistoryItem>> _getLocalHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawList = prefs.getString('${_localPrefsKey}_$userId');
      if (rawList == null || rawList.isEmpty) return [];

      final List decoded = jsonDecode(rawList);
      return decoded.map((j) => AnalysisHistoryItem.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Local history reading exception: $e');
      return [];
    }
  }

  // ── Write History to local SharedPreferences ──────────────
  Future<void> _saveLocalHistory(String userId, List<AnalysisHistoryItem> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = list.map((item) => item.toJson()).toList();
      await prefs.setString('${_localPrefsKey}_$userId', jsonEncode(encoded));
    } catch (e) {
      debugPrint('Local history saving exception: $e');
    }
  }

  // ── Get User Analysis History ────────────────────────────
  Future<List<AnalysisHistoryItem>> getUserAnalysisHistory() async {
    final userId = _getUserId();
    if (userId == null) {
      debugPrint('Warning: getUserAnalysisHistory called with no signed in user.');
      return [];
    }

    try {
      // First try to fetch from Supabase
      final response = await Supabase.instance.client
          .from('combined_analysis_results')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<AnalysisHistoryItem> remoteItems = (response as List)
          .map((r) => AnalysisHistoryItem.fromJson(r))
          .toList();

      // Mirror remotely fetched items in local storage for offline resiliency
      await _saveLocalHistory(userId, remoteItems);
      return remoteItems;
    } catch (e) {
      debugPrint('Supabase history fetch failed (database table likely missing or offline). Falling back to local storage. Error: $e');
      // Fallback to SharedPreferences
      final localItems = await _getLocalHistory(userId);
      // Sort by date descending
      localItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return localItems;
    }
  }

  // ── Save New Analysis ───────────────────────────────────
  Future<void> saveAnalysisHistory({
    required DietAnalysisResult dietAnalysis,
    required BloodAnalysisResult bloodAnalysis,
    required CombinedHealthAnalysis combinedAnalysis,
  }) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('Analiz sonucunun kaydedilebilmesi için oturum açmış olmanız gerekmektedir.');
    }

    final newItem = AnalysisHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      createdAt: DateTime.now(),
      dietAnalysis: dietAnalysis,
      bloodAnalysis: bloodAnalysis,
      combinedAnalysis: combinedAnalysis,
      summary: combinedAnalysis.combinedSummary.isNotEmpty
          ? combinedAnalysis.combinedSummary
          : (dietAnalysis.dietSummary.isNotEmpty ? dietAnalysis.dietSummary : 'Diyet ve kan tahlili analizi tamamlandı.'),
      nutritionPriorities: combinedAnalysis.nutritionPriorities,
      safetyNotes: combinedAnalysis.safetyNotes,
    );

    // 1. Save Locally (Guarantees local persistence no matter what)
    final localList = await _getLocalHistory(userId);
    localList.insert(0, newItem);
    await _saveLocalHistory(userId, localList);

    // 2. Try to Save to Supabase
    try {
      await Supabase.instance.client
          .from('combined_analysis_results')
          .insert(newItem.toJson());
      debugPrint('Successfully saved analysis result to Supabase.');
    } catch (e) {
      debugPrint('Supabase insert failed. Kept locally in SharedPreferences fallback. SQL error detail: $e');
      // Graceful notification: throw a custom exception with user message that gets caught smoothly by downstream handlers
      throw Exception('Analiz sonucu kaydedilemedi, ancak analiz tamamlandı.');
    }
  }

  // ── Get Latest Blood Analysis ───────────────────────────
  Future<BloodAnalysisResult?> getLatestBloodAnalysis() async {
    final userId = _getUserId();
    if (userId == null) return null;

    try {
      // Try fetching the latest item from Supabase with valid blood_analysis
      final response = await Supabase.instance.client
          .from('combined_analysis_results')
          .select()
          .eq('user_id', userId)
          .not('blood_analysis', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final item = AnalysisHistoryItem.fromJson(response);
        if (item.bloodAnalysis != null) {
          return item.bloodAnalysis;
        }
      }
    } catch (e) {
      debugPrint('Supabase latest blood analysis fetch failed, checking local storage. Error: $e');
    }

    // Local fallback
    final localList = await _getLocalHistory(userId);
    for (final item in localList) {
      if (item.bloodAnalysis != null && item.bloodAnalysis!.markers.isNotEmpty) {
        return item.bloodAnalysis;
      }
    }
    return null;
  }

  // ── Get Latest Diet Analysis ────────────────────────────
  Future<DietAnalysisResult?> getLatestDietAnalysis() async {
    final userId = _getUserId();
    if (userId == null) return null;

    try {
      final response = await Supabase.instance.client
          .from('combined_analysis_results')
          .select()
          .eq('user_id', userId)
          .not('diet_analysis', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final item = AnalysisHistoryItem.fromJson(response);
        if (item.dietAnalysis != null) {
          return item.dietAnalysis;
        }
      }
    } catch (e) {
      debugPrint('Supabase latest diet analysis fetch failed, checking local storage. Error: $e');
    }

    // Local fallback
    final localList = await _getLocalHistory(userId);
    for (final item in localList) {
      if (item.dietAnalysis != null) {
        return item.dietAnalysis;
      }
    }
    return null;
  }
}
