import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_goals_model.dart';
import '../models/user_health_profile.dart';
import 'notification_service.dart';

/// Bildirim aday tipi ve önceliği
enum _NotifType {
  water,        // priority 1
  calorieHigh,  // priority 2
  proteinLow,   // priority 3
  proteinHigh,  // priority 4
  calorieLow,   // priority 5
  activity,     // priority 6
  weight,       // priority 7
}

class _NotifCandidate {
  final _NotifType type;
  final String title;
  final String body;
  final String prefsKey;
  final String payloadType;

  const _NotifCandidate({
    required this.type,
    required this.title,
    required this.body,
    required this.prefsKey,
    required this.payloadType,
  });
}

class SmartNotificationService {
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  bool _isCheckingSmartNotifications = false;
  DateTime? _lastCheckTime;

  // ═══════════════════════════════════════════════════════════════════════════
  //  SABITLER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Aktif bildirim saat aralığı
  static const int _allowedStartHour = 9;
  static const int _allowedEndHour = 22;

  /// Global minimum bildirim aralığı (dakika)
  static const int _globalCooldownMinutes = 60;

  /// Türe özel minimum bildirim aralıkları (saat)
  static const Map<_NotifType, int> _typeIntervalHours = {
    _NotifType.water: 2,
    _NotifType.calorieHigh: 4,
    _NotifType.calorieLow: 4,
    _NotifType.proteinLow: 3,
    _NotifType.proteinHigh: 3,
    _NotifType.activity: 5,
    _NotifType.weight: 168, // 7 gün = 168 saat
  };

  /// SharedPreferences key'leri
  static const Map<_NotifType, String> _typePrefsKeys = {
    _NotifType.water: 'last_water_notification_at',
    _NotifType.calorieHigh: 'last_high_calorie_notification_at',
    _NotifType.calorieLow: 'last_low_calorie_notification_at',
    _NotifType.proteinLow: 'last_low_protein_notification_at',
    _NotifType.proteinHigh: 'last_high_protein_notification_at',
    _NotifType.activity: 'last_activity_notification_at',
    _NotifType.weight: 'last_weight_notification_at',
  };

  static const String _globalLastNotifKey = 'last_any_notification_at';

  // ═══════════════════════════════════════════════════════════════════════════
  //  ANA GİRİŞ NOKTASI
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> checkSmartNotifications({
    DailyGoals? goals,
    UserHealthProfile? healthProfile,
    bool hasSnackInDiet = false,
    bool isTwinWaterLow = false,
    bool isTwinCalorieLow = false,
    bool isTwinActivityLow = false,
  }) async {
    if (_isCheckingSmartNotifications) return;

    final now = DateTime.now();
    if (_lastCheckTime != null && now.difference(_lastCheckTime!).inSeconds < 30) {
      return;
    }

    _isCheckingSmartNotifications = true;
    _lastCheckTime = now;

    try {
      await _evaluateAndSendSingle(
        goals: goals,
        healthProfile: healthProfile,
      );
    } finally {
      _isCheckingSmartNotifications = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  KARAR MOTORU: TEK BİLDİRİM SEÇ VE GÖNDER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _evaluateAndSendSingle({
    DailyGoals? goals,
    UserHealthProfile? healthProfile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // ── 1. Aktif saat aralığında mıyız? ──
    final withinAllowedHours = now.hour >= _allowedStartHour && now.hour < _allowedEndHour;

    // ── 2. Global cooldown kontrolü ──
    bool canSendAny = true;
    final lastAnyStr = prefs.getString(_globalLastNotifKey);
    DateTime? lastAnyNotif;
    if (lastAnyStr != null) {
      lastAnyNotif = DateTime.tryParse(lastAnyStr);
      if (lastAnyNotif != null && now.difference(lastAnyNotif).inMinutes < _globalCooldownMinutes) {
        canSendAny = false;
      }
    }

    // ── 3. Switchleri Oku ──
    final bool dailyRemindersEnabled = prefs.getBool('daily_reminders') ?? false;
    final bool waterRemindersEnabled = prefs.getBool('water_reminders') ?? false;
    final bool calorieRemindersEnabled = prefs.getBool('calorie_reminders') ?? false;
    final bool proteinRemindersEnabled = prefs.getBool('protein_reminders') ?? false;
    final bool movementRemindersEnabled = prefs.getBool('movement_reminders') ?? false;
    final bool weightRemindersEnabled = prefs.getBool('weight_reminders') ?? false;

    // ── 4. Değerleri Al ──
    final double currentWater = goals?.waterConsumed ?? 0.0;
    final double waterGoal = (goals?.waterTarget ?? 0.0) > 0 ? goals!.waterTarget.toDouble() : 2500.0;
    final double currentCalories = goals?.caloriesConsumed ?? 0.0;
    final double calorieGoal = (goals?.caloriesTarget ?? 0.0) > 0 ? goals!.caloriesTarget.toDouble() : 2000.0;
    final double currentProtein = goals?.proteinConsumed ?? 0.0;
    final double proteinGoal = (goals?.proteinTarget ?? 0.0) > 0 ? goals!.proteinTarget.toDouble() : 100.0;
    final double currentActivityMinutes = goals?.activityCompleted ?? 0.0;
    final double activityGoalMinutes = (goals?.activityTarget ?? 0.0) > 0 ? goals!.activityTarget.toDouble() : 60.0;
    final DateTime? lastWeightUpdateDate = healthProfile?.updatedAt ?? healthProfile?.createdAt;

    // ── 5. Adayları Topla (öncelik sırasıyla) ──
    final candidates = <_NotifCandidate>[];

    // Su (priority 1)
    final waterEligible = dailyRemindersEnabled && waterRemindersEnabled
        && goals != null
        && currentWater < waterGoal * 0.50
        && _typeIntervalOk(prefs, _NotifType.water, now);
    if (waterEligible) {
      candidates.add(const _NotifCandidate(
        type: _NotifType.water,
        title: 'Su Hatırlatması 💧',
        body: 'Bugün az su içtin. Bir bardak su iyi gelebilir.',
        prefsKey: 'last_water_notification_at',
        payloadType: 'water',
      ));
    }

    // Kalori Aşımı (priority 2)
    final calorieHighEligible = dailyRemindersEnabled && calorieRemindersEnabled
        && goals != null
        && currentCalories > calorieGoal
        && _typeIntervalOk(prefs, _NotifType.calorieHigh, now)
        && !_alreadySentToday(prefs, _NotifType.calorieHigh, now);
    if (calorieHighEligible) {
      candidates.add(const _NotifCandidate(
        type: _NotifType.calorieHigh,
        title: 'Kalori Hedefi Aşıldı 🔥',
        body: 'Bugünkü kalori hedefini aştın. Kalan öğünlerinde daha hafif seçimler yapabilirsin.',
        prefsKey: 'last_high_calorie_notification_at',
        payloadType: 'calorie_high',
      ));
    }

    // Protein Düşük (priority 3)
    final proteinLowEligible = dailyRemindersEnabled && proteinRemindersEnabled
        && goals != null
        && currentProtein < proteinGoal * 0.40
        && _typeIntervalOk(prefs, _NotifType.proteinLow, now);
    if (proteinLowEligible) {
      candidates.add(const _NotifCandidate(
        type: _NotifType.proteinLow,
        title: 'Protein Düşük Görünüyor 🌿',
        body: 'Bugünkü protein hedefinin gerisindesin. Protein ağırlıklı hafif bir tarif seçebilirsin.',
        prefsKey: 'last_low_protein_notification_at',
        payloadType: 'protein_low',
      ));
    }

    // Protein Aşımı (priority 4)
    final proteinHighEligible = dailyRemindersEnabled && proteinRemindersEnabled
        && goals != null
        && currentProtein > proteinGoal
        && _typeIntervalOk(prefs, _NotifType.proteinHigh, now)
        && !_alreadySentToday(prefs, _NotifType.proteinHigh, now);
    if (proteinHighEligible) {
      candidates.add(const _NotifCandidate(
        type: _NotifType.proteinHigh,
        title: 'Protein Hedefi Tamamlandı 💪',
        body: 'Bugünkü protein hedefini tamamladın. Dengeli ilerlemeye devam et.',
        prefsKey: 'last_high_protein_notification_at',
        payloadType: 'protein_high',
      ));
    }

    // Kalori Düşük (priority 5)
    final calorieLowEligible = dailyRemindersEnabled && calorieRemindersEnabled
        && goals != null
        && currentCalories < calorieGoal * 0.35
        && _typeIntervalOk(prefs, _NotifType.calorieLow, now);
    if (calorieLowEligible) {
      candidates.add(const _NotifCandidate(
        type: _NotifType.calorieLow,
        title: 'Dengeli Öğün Zamanı 🍽️',
        body: 'Bugünkü kalorin düşük görünüyor. Dengeli bir öğün ekleyebilirsin.',
        prefsKey: 'last_low_calorie_notification_at',
        payloadType: 'calorie_low',
      ));
    }

    // Hareket (priority 6)
    final activityEligible = dailyRemindersEnabled && movementRemindersEnabled
        && goals != null
        && currentActivityMinutes < activityGoalMinutes * 0.40
        && _typeIntervalOk(prefs, _NotifType.activity, now)
        && !_alreadySentToday(prefs, _NotifType.activity, now);
    if (activityEligible) {
      candidates.add(const _NotifCandidate(
        type: _NotifType.activity,
        title: 'Hareket Zamanı 🚶‍♀️',
        body: 'Bugün biraz hareketsiz kaldın. Kısa bir yürüyüş iyi gelebilir.',
        prefsKey: 'last_activity_notification_at',
        payloadType: 'activity',
      ));
    }

    // Tartı (priority 7)
    final bool weightOverdue = lastWeightUpdateDate == null || now.difference(lastWeightUpdateDate).inDays >= 7;
    final weightEligible = dailyRemindersEnabled && weightRemindersEnabled
        && weightOverdue
        && _typeIntervalOk(prefs, _NotifType.weight, now);
    if (weightEligible) {
      candidates.add(const _NotifCandidate(
        type: _NotifType.weight,
        title: 'Tartı Zamanı ⚖️',
        body: 'Bu haftaki tartı kaydını eklemeyi unutma.',
        prefsKey: 'last_weight_notification_at',
        payloadType: 'weight',
      ));
    }

    // ── 6. Debug Log ──
    debugPrint('''
Smart notification check started:
- now: ${now.toIso8601String()}
- withinAllowedHours: $withinAllowedHours (${now.hour}:${now.minute}, allowed $_allowedStartHour-$_allowedEndHour)
- lastAnyNotificationAt: ${lastAnyNotif?.toIso8601String() ?? 'never'}
- canSendAnyNotification: $canSendAny
- dailyRemindersEnabled: $dailyRemindersEnabled

Per type:
- water eligible: $waterEligible
- calorieHigh eligible: $calorieHighEligible
- proteinLow eligible: $proteinLowEligible
- proteinHigh eligible: $proteinHighEligible
- calorieLow eligible: $calorieLowEligible
- activity eligible: $activityEligible
- weight eligible: $weightEligible

Candidate result:
- candidateCount: ${candidates.length}
- candidateTypes: ${candidates.map((c) => c.type.name).toList()}
- skippedBecauseGlobalCooldown: ${!canSendAny}
- skippedBecauseOutsideHours: ${!withinAllowedHours}
''');

    // ── 7. Gönderim Kararı ──
    if (!withinAllowedHours) {
      debugPrint('Smart notification SKIPPED: outside allowed hours.');
      return;
    }

    if (!canSendAny) {
      debugPrint('Smart notification SKIPPED: global cooldown active ($_globalCooldownMinutes min).');
      return;
    }

    if (candidates.isEmpty) {
      debugPrint('Smart notification SKIPPED: no eligible candidates.');
      return;
    }

    // Adaylar zaten öncelik sırasıyla eklendi, ilkini al
    final selected = candidates.first;

    debugPrint('Smart notification SENDING: ${selected.type.name}');

    // ── 8. Gönder ──
    await _sendNotification(
      title: selected.title,
      body: selected.body,
      type: selected.payloadType,
      prefsKey: selected.prefsKey,
      prefs: prefs,
    );

    // ── 9. Global timestamp güncelle ──
    await prefs.setString(_globalLastNotifKey, now.toIso8601String());

    debugPrint('''
Send result:
- notificationType: ${selected.type.name}
- success: true
- savedToHistory: true
- globalCooldownUpdated: true
''');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ANALİZ (olay bazlı, periyodik değil)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> sendAnalysisNotification() async {
    final prefs = await SharedPreferences.getInstance();

    final bool dailyEnabled = prefs.getBool('daily_reminders') ?? false;
    if (!dailyEnabled) return;

    final bool analysisEnabled = prefs.getBool('analysis_reminders') ?? false;
    if (!analysisEnabled) return;

    final lastNotifStr = prefs.getString('last_analysis_notification_at');
    if (lastNotifStr != null) {
      final lastNotif = DateTime.tryParse(lastNotifStr);
      if (lastNotif != null && _isSameDay(DateTime.now(), lastNotif)) {
        return;
      }
    }

    await _sendNotification(
      title: 'Analizlerin Hazır ✨',
      body: 'Sana özel öneriler hazır. İncelemek ister misin?',
      type: 'analysis',
      prefsKey: 'last_analysis_notification_at',
      prefs: prefs,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  YARDIMCI FONKSİYONLAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Türe özel interval kontrolü: son bildirimden yeterli süre geçti mi?
  bool _typeIntervalOk(SharedPreferences prefs, _NotifType type, DateTime now) {
    final key = _typePrefsKeys[type];
    if (key == null) return true;

    final lastStr = prefs.getString(key);
    if (lastStr == null) return true;

    final last = DateTime.tryParse(lastStr);
    if (last == null) return true;

    final requiredHours = _typeIntervalHours[type] ?? 2;
    return now.difference(last).inHours >= requiredHours;
  }

  /// Bugün zaten gönderilmiş mi? (günde max 1 kez olan tipler için)
  bool _alreadySentToday(SharedPreferences prefs, _NotifType type, DateTime now) {
    final key = _typePrefsKeys[type];
    if (key == null) return false;

    final lastStr = prefs.getString(key);
    if (lastStr == null) return false;

    final last = DateTime.tryParse(lastStr);
    if (last == null) return false;

    return _isSameDay(now, last);
  }

  Future<void> _sendNotification({
    required String title,
    required String body,
    required String type,
    required String prefsKey,
    required SharedPreferences prefs,
  }) async {
    await NotificationService().showLocalNotification(title, body, payload: type, type: type);
    await prefs.setString(prefsKey, DateTime.now().toIso8601String());
    debugPrint('Smart notification sent: $type');
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DEBUG / TEST SİMÜLASYONLARI
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> simulateLowWaterNotification() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await _sendNotification(title: 'Su Hatırlatması 💧', body: 'Bugün az su içtin. Bir bardak su iyi gelebilir.', type: 'water', prefsKey: 'last_water_notification_at', prefs: prefs);
  }

  Future<void> simulateLowActivityNotification() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await _sendNotification(title: 'Hareket Zamanı 🚶‍♀️', body: 'Bugün biraz hareketsiz kaldın. Kısa bir yürüyüş iyi gelebilir.', type: 'activity', prefsKey: 'last_activity_notification_at', prefs: prefs);
  }

  Future<void> simulateLowCalorieNotification() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await _sendNotification(title: 'Dengeli Öğün Zamanı 🍽️', body: 'Bugünkü kalorin düşük görünüyor. Dengeli bir öğün ekleyebilirsin.', type: 'calorie_low', prefsKey: 'last_low_calorie_notification_at', prefs: prefs);
  }

  Future<void> simulateWeightReminderNotification() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await _sendNotification(title: 'Tartı Zamanı ⚖️', body: 'Bu haftaki tartı kaydını eklemeyi unutma.', type: 'weight', prefsKey: 'last_weight_notification_at', prefs: prefs);
  }
}
