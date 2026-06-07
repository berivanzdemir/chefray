import 'dart:math';

enum RayMessageType {
  welcome,
  uploadDietReminder,
  uploadBloodReminder,
  recipeSuggestion,
  hydrationTip,
  balancedMealTip,
  safetyWarning,
}

class RaySuggestion {
  final String title;
  final String message;
  final RayMessageType type;
  final String? actionLabel;
  final String? actionRoute;

  const RaySuggestion({
    required this.title,
    required this.message,
    required this.type,
    this.actionLabel,
    this.actionRoute,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'type': type.name,
        'action_label': actionLabel,
        'action_route': actionRoute,
      };
}

class RayMascotSuggestionService {
  static final RayMascotSuggestionService _instance =
      RayMascotSuggestionService._();
  factory RayMascotSuggestionService() => _instance;
  RayMascotSuggestionService._();

  final _random = Random();
  String? _lastMessageText;

  // ── Pre-approved safe message pool ─────────────────────────

  static const _generalTips = [
    RaySuggestion(
      title: "Ray'den öneri",
      message: 'Bugün öğünlerini daha dengeli planlamaya ne dersin?',
      type: RayMessageType.balancedMealTip,
    ),
    RaySuggestion(
      title: "Ray'den öneri",
      message: 'Bugün bol su içmeyi unutma. Küçük alışkanlıklar büyük fark yaratır.',
      type: RayMessageType.hydrationTip,
    ),
    RaySuggestion(
      title: "Ray'den öneri",
      message: 'Bugün lif oranı yüksek tariflere göz atmak iyi bir fikir olabilir.',
      type: RayMessageType.recipeSuggestion,
      actionLabel: 'Tarifleri keşfet',
      actionRoute: '/recipe-list',
    ),
    RaySuggestion(
      title: "Ray'den öneri",
      message: 'Kızartmalar yerine fırın veya haşlama alternatiflerini denemeye ne dersin?',
      type: RayMessageType.balancedMealTip,
    ),
    RaySuggestion(
      title: "Ray'den öneri",
      message: 'Bugün tabağında sebzelere biraz daha yer açabilirsin.',
      type: RayMessageType.balancedMealTip,
    ),
    RaySuggestion(
      title: "Ray'den öneri",
      message: 'Öğünlerinde protein, karbonhidrat ve sağlıklı yağ dengesine dikkat etmek uzun vadede fark yaratır.',
      type: RayMessageType.balancedMealTip,
    ),
    RaySuggestion(
      title: "Ray'den öneri",
      message: 'Yemeklerini yavaş yemek ve iyi çiğnemek sindirimine yardımcı olabilir.',
      type: RayMessageType.balancedMealTip,
    ),
    RaySuggestion(
      title: "Ray'den öneri",
      message: 'Haftada en az 2 gün balık tüketmek omega-3 alımına katkı sağlayabilir.',
      type: RayMessageType.recipeSuggestion,
    ),
    RaySuggestion(
      title: "Ray'den öneri",
      message: 'Mevsim sebzeleriyle hazırlanmış bir salata her öğüne renk katar.',
      type: RayMessageType.recipeSuggestion,
    ),
  ];

  static const _uploadDietReminders = [
    RaySuggestion(
      title: 'Diyetini yükle 🥗',
      message: 'Diyet listeni yüklersen sana daha uygun tarifler önerebilirim.',
      type: RayMessageType.uploadDietReminder,
      actionLabel: 'Diyet listesi yükle',
      actionRoute: '/diet-upload?uploadType=dietPdf',
    ),
    RaySuggestion(
      title: 'Diyet listesi yükle 📋',
      message: 'Diyet listesine göre tarifleri kişiselleştirmemi ister misin? Hemen yükle.',
      type: RayMessageType.uploadDietReminder,
      actionLabel: 'Diyet listesi yükle',
      actionRoute: '/diet-upload?uploadType=dietPdf',
    ),
  ];

  static const _uploadBloodReminders = [
    RaySuggestion(
      title: 'Kan değerlerini yükle 🩸',
      message: 'Kan değerlerini yüklersen tarif önerilerini daha bilinçli kişiselleştirebilirim.',
      type: RayMessageType.uploadBloodReminder,
      actionLabel: 'Kan değerlerini yükle',
      actionRoute: '/diet-upload?uploadType=bloodPdf',
    ),
    RaySuggestion(
      title: 'Tahlilini yükle 🔬',
      message: 'Kan değerlerini düzenli takip etmek, beslenme planını daha bilinçli yönetmene yardımcı olabilir.',
      type: RayMessageType.uploadBloodReminder,
      actionLabel: 'Kan değerlerini yükle',
      actionRoute: '/diet-upload?uploadType=bloodPdf',
    ),
  ];

  static const _bothUploadedTips = [
    RaySuggestion(
      title: "Ray'den öneri",
      message: 'Diyet listen ve kan değerlerin hazır. Birlikte analiz ederek sana en uygun tarifleri bulabiliriz!',
      type: RayMessageType.recipeSuggestion,
      actionLabel: 'Birlikte analiz et',
    ),
    RaySuggestion(
      title: "Ray'den öneri",
      message: 'Belgelerin tamam! Şimdi sana özel tarif önerilerine göz atabilirsin.',
      type: RayMessageType.recipeSuggestion,
      actionLabel: 'Tarifleri keşfet',
      actionRoute: '/recipe-list',
    ),
  ];

  static const _welcomeMessages = [
    RaySuggestion(
      title: 'Hoş geldin! 👋',
      message: 'Merhaba, ben Ray! Bugün sağlıklı tarifler keşfetmeye ne dersin?',
      type: RayMessageType.welcome,
    ),
    RaySuggestion(
      title: 'Hoş geldin! 🌟',
      message: 'Merhaba, ben Ray! Beslenme yolculuğunda sana eşlik etmek için buradayım.',
      type: RayMessageType.welcome,
    ),
  ];

  static const _safetyWarning = RaySuggestion(
    title: 'Hatırlatma ⚠️',
    message: 'Beslenme önerilerim genel bilgilendirme amaçlıdır. Özel durumlarda uzmana danışmayı unutma.',
    type: RayMessageType.safetyWarning,
  );

  // ── Context-aware suggestion logic ─────────────────────────

  /// Selects a suggestion based on user state.
  /// [hasDietPlan] — diet plan uploaded and validated
  /// [hasBloodValues] — blood values uploaded and validated
  /// [hasRecipeTags] — recipe tags generated from rule engine
  RaySuggestion getSuggestion({
    bool hasDietPlan = false,
    bool hasBloodValues = false,
    bool hasRecipeTags = false,
  }) {
    // Safety warning is shown occasionally (15% chance)
    if (_random.nextDouble() < 0.15) {
      _lastMessageText = _safetyWarning.message;
      return _safetyWarning;
    }

    // No documents uploaded
    if (!hasDietPlan && !hasBloodValues) {
      final pool = [..._welcomeMessages, ..._uploadDietReminders];
      return _pickFrom(pool);
    }

    // Only diet uploaded
    if (hasDietPlan && !hasBloodValues) {
      // 40% chance of reminding about blood upload
      if (_random.nextDouble() < 0.4) {
        return _pickFrom(_uploadBloodReminders);
      }
      return _pickFrom(_generalTips);
    }

    // Only blood uploaded
    if (!hasDietPlan && hasBloodValues) {
      if (_random.nextDouble() < 0.4) {
        return _pickFrom(_uploadDietReminders);
      }
      return _pickFrom(_generalTips);
    }

    // Both uploaded, with recipe tags
    if (hasDietPlan && hasBloodValues && hasRecipeTags) {
      return _pickFrom([..._bothUploadedTips, ..._generalTips]);
    }

    // Both uploaded, without recipe tags
    return _pickFrom([..._bothUploadedTips, ..._generalTips]);
  }

  /// Returns a welcome message for app startup
  RaySuggestion getWelcomeMessage() {
    return _pickFrom(_welcomeMessages);
  }

  /// Returns a general tip
  RaySuggestion getGeneralTip() {
    return _pickFrom(_generalTips);
  }

  // ── Internal helpers ───────────────────────────────────────

  RaySuggestion _pickFrom(List<RaySuggestion> pool) {
    // Avoid showing the same message consecutively
    RaySuggestion pick;
    int attempts = 0;
    do {
      pick = pool[_random.nextInt(pool.length)];
      attempts++;
    } while (pick.message == _lastMessageText && attempts < pool.length);

    _lastMessageText = pick.message;
    return pick;
  }
}
