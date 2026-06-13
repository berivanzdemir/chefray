import 'package:flutter/material.dart';
import '../../services/ray_assistant_service.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;
  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
  });
}

class RayAssistantScreen extends StatefulWidget {
  const RayAssistantScreen({super.key});

  @override
  State<RayAssistantScreen> createState() => _RayAssistantScreenState();
}

class _RayAssistantScreenState extends State<RayAssistantScreen> {
  String? _expandedCategory;
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  // Categories and their questions
  final Map<String, List<Map<String, String>>> _categories = {
    'Günlük Takip': [
      {
        'q': 'Bugünkü durumum nasıl?',
        'a':
            'Bugünkü su, kalori, protein ve hareket durumunu kontrol ederek sana kısa bir özet sunacağım.',
      },
      {
        'q': 'Su durumum nasıl?',
        'a':
            'Günlük su hedefini ve içtiğin miktarı karşılaştırarak sana öneri vereceğim.',
      },
      {
        'q': 'Kalorim nasıl gidiyor?',
        'a':
            'Kalori hedefinle bugünkü ilerlemeni karşılaştırarak sana bilgi vereceğim.',
      },
      {
        'q': 'Proteinim yeterli mi?',
        'a':
            'Protein hedefinle bugünkü protein alımını karşılaştırarak sana öneri sunacağım.',
      },
      {
        'q': 'Hareket durumum nasıl?',
        'a':
            'Günlük hareket hedefin ile bugünkü aktivite süreni değerlendirip sana geri dönüş yapacağım.',
      },
    ],
    'Tarif Önerileri': [
      {
        'q': 'Bugün ne yemeliyim?',
        'a': 'Hedeflerine göre sana uygun tarif önerileri sunacağım.',
      },
      {
        'q': 'Kahvaltı öner',
        'a':
            'Güne zinde başlaman için sağlıklı ve pratik kahvaltı tarifleri önerebilirim.',
      },
      {
        'q': 'Öğle yemeği öner',
        'a':
            'Öğlen enerjini yüksek tutacak, besleyici öğle yemeği seçenekleri sunabilirim.',
      },
      {
        'q': 'Akşam yemeği öner',
        'a':
            'Akşamları seni yormayacak ama doyurucu hafif tarifler tavsiye edebilirim.',
      },
      {
        'q': 'Ara öğün öner',
        'a':
            'Ana öğünler arasında açlığını bastıracak sağlıklı atıştırmalıklar önerebilirim.',
      },
      {
        'q': 'Protein ağırlıklı tarif öner',
        'a':
            'Kas gelişimini destekleyecek ve tok tutacak yüksek proteinli tarifler sunacağım.',
      },
      {
        'q': 'Düşük kalorili tarif öner',
        'a':
            'Kalori açığını korumanı sağlayacak hafif ve düşük kalorili tarifler bulabilirim.',
      },
    ],
    'Uygulama Yardımı': [
      {
        'q': 'Bildirimlerim açık mı?',
        'a':
            'Profil sayfasındaki bildirim ayarlarından su, kalori ve hareket hatırlatıcılarını kontrol edebilirsin.',
      },
      {
        'q': 'Günlük hedeflerimi nasıl düzenlerim?',
        'a':
            'Profil sayfasındaki Günlük Hedefler alanından kalori, protein, su ve aktivite hedeflerini düzenleyebilirsin.',
      },
      {
        'q': 'Tarifi tamamlayınca ne olur?',
        'a':
            'Bir tarifi tamamladığında tarifin kalori, protein, karbonhidrat ve yağ değerleri günlük ilerlemene otomatik olarak eklenir.',
      },
      {
        'q': 'Su eklemeyi nasıl yaparım?',
        'a':
            'Ana sayfadaki su tüketimi kartından +250 ml veya +500 ml seçenekleriyle pratik şekilde su ekleyebilirsin.',
      },
    ],
  };

  final Map<String, Map<String, dynamic>> _categoryProps = {
    'Günlük Takip': {
      'desc': 'Su, kalori, protein ve hareket durumunu kontrol et.',
      'icon': Icons.health_and_safety_rounded,
      'color': const Color(0xFF4DB6AC), // Teal 300
    },
    'Tarif Önerileri': {
      'desc': 'Sana uygun kahvaltı, öğle, akşam ve ara öğün tarifleri bul.',
      'icon': Icons.dinner_dining_rounded,
      'color': const Color(0xFF9575CD), // Deep Purple 300
    },
    'Uygulama Yardımı': {
      'desc': 'Bildirimler, hedefler ve uygulama kullanımı hakkında bilgi al.',
      'icon': Icons.support_agent_rounded,
      'color': const Color(0xFF4FC3F7), // Light Blue 300
    },
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 300,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  RayAssistantIntent _getIntentForQuestion(String question) {
    if (question.contains('Su durumum')) return RayAssistantIntent.water;
    if (question.contains('Kalorim')) return RayAssistantIntent.calorie;
    if (question.contains('Proteinim')) return RayAssistantIntent.protein;
    if (question.contains('Hareket durumum'))
      return RayAssistantIntent.activity;
    if (question.contains('Bugünkü durumum')) return RayAssistantIntent.general;

    if (question.contains('Bugün ne yemeliyim'))
      return RayAssistantIntent.recipeGeneral;
    if (question.contains('Kahvaltı öner'))
      return RayAssistantIntent.recipeBreakfast;
    if (question.contains('Öğle yemeği')) return RayAssistantIntent.recipeLunch;
    if (question.contains('Akşam yemeği'))
      return RayAssistantIntent.recipeDinner;
    if (question.contains('Ara öğün')) return RayAssistantIntent.recipeSnack;
    if (question.contains('Protein ağırlıklı'))
      return RayAssistantIntent.recipeHighProtein;
    if (question.contains('Düşük kalorili'))
      return RayAssistantIntent.recipeLowCalorie;

    if (question.contains('Bildirimlerim açık mı'))
      return RayAssistantIntent.notifications;

    return RayAssistantIntent.unknown;
  }

  Future<void> _onQuestionTap(String question, String answer) async {
    setState(() {
      _messages.add(_ChatMessage(text: question, isUser: true));
      _messages.add(
        _ChatMessage(
          text: 'Yanıt hazırlanıyor...',
          isUser: false,
          isLoading: true,
        ),
      );
    });

    _scrollToBottom();

    final intent = _getIntentForQuestion(question);
    final responseText = await RayAssistantService().generateResponse(
      context,
      intent,
      staticFallback: answer,
    );

    if (!mounted) return;

    setState(() {
      _messages.removeLast(); // Remove loading message
      _messages.add(_ChatMessage(text: responseText, isUser: false));
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0F241E) : colors.surface;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: Text(
          'Ray Asistan',
          style: TextStyle(
            color: isDark ? const Color(0xFFF3FFF9) : colors.onSurface,
            fontWeight: FontWeight.w700,
            fontFamily: 'SF Pro Display',
          ),
        ),
        backgroundColor: pageBg,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFF3FFF9) : colors.onSurface,
        ),
      ),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // 1. Welcome Card
            _buildWelcomeCard(context),

            // 2. Categories
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Bir konu seç',
                style: TextStyle(
                  color: isDark ? const Color(0xFFF3FFF9) : colors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
            ..._categories.keys.map(
              (category) => _buildCategoryCard(category, colors, isDark),
            ),

            // 3. Chat Messages
            if (_messages.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._messages.map((m) => _buildChatMessage(m, colors, isDark)),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF17332B) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF3FFF9) : colors.primary;
    final textColor = isDark
        ? const Color(0xFFC7D8D2)
        : colors.onSurface.withValues(alpha: 0.7);
    final subtitleColor = isDark
        ? const Color(0xFFB7CCC5)
        : colors.onSurface.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? const Color(0xFF2B4A40)
              : colors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Image.asset(
              'assets/mascot/ray_thinking.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.smart_toy_rounded,
                color: colors.primary,
                size: 40,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Merhaba, ben Ray 👋',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Beslenme hedeflerin, su takibin ve tarif seçimlerin için sana yardımcı olabilirim.',
                  style: TextStyle(color: textColor, fontSize: 14, height: 1.3),
                  maxLines: 3,
                  softWrap: true,
                ),
                const SizedBox(height: 10),
                Text(
                  'Bugün nasıl yardımcı olabilirim?',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String categoryName,
    ColorScheme colors,
    bool isDark,
  ) {
    final isExpanded = _expandedCategory == categoryName;
    final questions = _categories[categoryName]!;
    final props = _categoryProps[categoryName]!;

    final cardBg = isDark ? const Color(0xFF17332B) : Colors.white;
    final borderColor = isExpanded
        ? (isDark ? colors.primary : colors.primary.withValues(alpha: 0.5))
        : (isDark ? const Color(0xFF2B4A40) : Colors.transparent);
    final titleColor = isDark ? const Color(0xFFF3FFF9) : colors.onSurface;
    final descColor = isDark
        ? const Color(0xFFC7D8D2)
        : colors.onSurface.withValues(alpha: 0.6);
    final iconBgColor = isDark
        ? const Color(0xFF1E3A31)
        : (props['color'] as Color).withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategory = null;
                } else {
                  _expandedCategory = categoryName;
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: (props['color'] as Color).withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        if (!isDark)
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 10,
                            offset: const Offset(-2, -2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        props['icon'] as IconData,
                        color: props['color'] as Color,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: titleColor,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          props['desc'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: descColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? const Color(0xFFB7CCC5)
                        : colors.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: questions.map((qData) {
                  final qText = qData['q']!;
                  final aText = qData['a']!;

                  return InkWell(
                    onTap: () => _onQuestionTap(qText, aText),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E3A31)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2B4A40)
                              : colors.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        qText,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFDFFFEF)
                              : colors.onSurface.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(
    _ChatMessage message,
    ColorScheme colors,
    bool isDark,
  ) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8, left: 50),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(
              20,
            ).copyWith(bottomRight: Radius.zero),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } else {
      final cardBg = isDark ? const Color(0xFF1E3A31) : Colors.white;
      final titleColor = isDark ? const Color(0xFFF3FFF9) : colors.primary;
      final textColor = isDark
          ? const Color(0xFFDFFFEF)
          : colors.onSurface.withValues(alpha: 0.8);
      final loadingColor = isDark
          ? const Color(0xFFB7CCC5)
          : colors.onSurface.withValues(alpha: 0.6);
      final borderColor = isDark
          ? const Color(0xFF2B4A40)
          : colors.primary.withValues(alpha: 0.1);

      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/mascot/ray_thinking.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.smart_toy_rounded,
                    size: 20,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8, right: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(
                    20,
                  ).copyWith(bottomLeft: Radius.zero),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ray',
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (message.isLoading)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            message.text,
                            style: TextStyle(
                              color: loadingColor,
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        message.text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
