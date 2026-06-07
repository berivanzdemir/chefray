import 'package:flutter/material.dart';
import 'dart:math' as math;

enum CookingStepVisualType {
  washing,
  cutting,
  grating,
  shredding,
  tearing,
  foldingCutting,
  adding,
  mixing,
  sauceMixing,
  kneading,
  shaping,
  filling,
  coating,
  resting,
  panHeating,
  panCooking,
  potCooking,
  boiling,
  straining,
  roasting,
  ovenCooking,
  blending,
  serving,
  genericCooking
}

class CookingStepAnimation extends StatefulWidget {
  final String stepText;
  final int stepIndex;
  final bool isLastStep;
  final Color primaryColor;
  final Color accentColor;

  const CookingStepAnimation({
    super.key,
    required this.stepText,
    required this.stepIndex,
    this.isLastStep = false,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<CookingStepAnimation> createState() => _CookingStepAnimationState();
}

class _CookingStepAnimationState extends State<CookingStepAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CookingStepVisualType _getStepVisualType(String text, bool isLast) {
    // 1. Normalize
    String t = text.toLowerCase()
        .replaceAll('i̇', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ç', 'c')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[.,!?();:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 2. Stop phrases and exclusions
    t = t.replaceAll('süzme yoğurt', 'malzeme_yogurt')
         .replaceAll('suzme yogurt', 'malzeme_yogurt')
         .replaceAll('yoğurdu', 'malzeme_yogurt')
         .replaceAll('yogurdu', 'malzeme_yogurt')
         .replaceAll('yoğurtlu', 'malzeme_yogurt')
         .replaceAll('yogurtlu', 'malzeme_yogurt')
         .replaceAll('yoğurtla', 'malzeme_yogurt')
         .replaceAll('yogurtla', 'malzeme_yogurt')
         .replaceAll('yoğurda', 'malzeme_yogurt')
         .replaceAll('yogurda', 'malzeme_yogurt')
         .replaceAll('yoğurdun', 'malzeme_yogurt')
         .replaceAll('yogurdun', 'malzeme_yogurt')
         .replaceAll('yoğurt', 'malzeme_yogurt')
         .replaceAll('yogurt', 'malzeme_yogurt')
         .replaceAll('kestane', 'malzeme_kestane');

    t = t.replaceAll('suyunu çek', 'suyunu_cekme_islemi')
         .replaceAll('suyunu cek', 'suyunu_cekme_islemi');

    t = t.replaceAll('bıçak değmeden', 'bicaksiz_islem')
         .replaceAll('bicak degmeden', 'bicaksiz_islem');

    t = t.replaceAll('tavaya yağ', 'tavaya_yag_alma')
         .replaceAll('tavaya yag', 'tavaya_yag_alma');

    if (t.contains('yufka') && t.contains('katla')) {
      t += ' yufka_katlama_kesme_islemi ';
    }
    if (t.contains('katlanır ve ikiye kesilir') || t.contains('katlanir ve ikiye kesilir')) {
      t += ' yufka_katlama_kesme_islemi ';
    }

    int calcScore(String pattern) {
      return RegExp(pattern).allMatches(t).length;
    }

    bool hasWord(List<String> words) {
      for (var w in words) {
        if (t.contains(w)) return true;
      }
      return false;
    }

    int getSauceMixingScore() {
      bool hasSauceIng = hasWord(['malzeme_yogurt', 'mayonez', 'hardal', 'sos', 'limon', 'zeytinyağ', 'zeytinyag', 'nar ekşisi', 'nar eksisi', 'sirke', 'baharat', 'tuz', 'karabiber', 'pul biber']);
      bool hasMix = hasWord(['karıştır', 'karistir', 'çırp', 'cirp']);
      return (hasSauceIng && hasMix) ? 1 : 0;
    }

    Map<CookingStepVisualType, int> scores = {
      CookingStepVisualType.serving: calcScore(r'\b(servis|afiyet|sunum|tabaga al|sicak servis|soguk servis)'),
      CookingStepVisualType.blending: calcScore(r'\b(blender|rondo|robot|robottan|pure|puruzsuz|mikser|ezici)'),
      CookingStepVisualType.kneading: calcScore(r'\b(yogur)'),
      CookingStepVisualType.grating: calcScore(r'\b(rende)'),
      CookingStepVisualType.shredding: calcScore(r'\b(didik|lif lif|kucuk parcalara)'),
      CookingStepVisualType.tearing: calcScore(r'\b(elle parcala|elle kopar|bicaksiz_islem|yapraklarina ayir|iri parcalara)'),
      CookingStepVisualType.foldingCutting: calcScore(r'\b(yufka_katlama_kesme_islemi|ikiye kes|rulo yapilip kes|katlayip kes)'),
      CookingStepVisualType.filling: calcScore(r'\b(doldur|ic harc|iclerine paylastir|icini|dolmalik)'),
      CookingStepVisualType.coating: calcScore(r'\b(una bula|yumurtaya batir|galeta|pane|kapla|bulayin|sosa)'),
      CookingStepVisualType.roasting: calcScore(r'\b(kozle|izgara|mangal)'),
      CookingStepVisualType.ovenCooking: calcScore(r'\b(firin|tepsi|pisirme kagidi|yagli kagit|derece|onceden isitilmis)'),
      CookingStepVisualType.panHeating: calcScore(r'\b(tavaya_yag_alma|tavaya yag koy|tavaya zeytinyagi|tavaya tereyagi|tavayi isit|yag kizdir|alti acilir|altini ac|tava isininca)'),
      CookingStepVisualType.panCooking: calcScore(r'\b(tavada|tavaya alip|kavur|sotele|kizart|kizar|arkali onlu|muhurle|az yagda)'),
      CookingStepVisualType.boiling: calcScore(r'\b(hasla|kaynat|kaynama|kaynar|fokurda)'),
      CookingStepVisualType.potCooking: calcScore(r'\b(tencere|kisik ates|suyunu_cekme_islemi|kapagi kapali|pilav gibi|kivam alana|renk alana)'),
      CookingStepVisualType.cutting: calcScore(r'\b(dogra|kes|dilim|kup kup|ince ince|julyen|minik minik)'),
      CookingStepVisualType.washing: calcScore(r'\b(yika|yikama|durula)'),
      CookingStepVisualType.straining: calcScore(r'\b(suz|suzun|suzulur|suzdur|suzgec)'),
      CookingStepVisualType.sauceMixing: getSauceMixingScore(),
      CookingStepVisualType.mixing: calcScore(r'\b(karistir|cirp|harmanla|homojen|guzelce karistir)'),
      CookingStepVisualType.shaping: calcScore(r'\b(sekil|yuvarla|beze|rulo|sar\b|sarin\b|sarip\b|durum|top haline)'),
      CookingStepVisualType.resting: calcScore(r'\b(dinlendir|beklet|buzdolabi|mayalan|sogu|oda sicakliginda)'),
      CookingStepVisualType.adding: calcScore(r'\b(ekle|ilave|uzerine|icine al|icerisine ekle)'),
      CookingStepVisualType.genericCooking: calcScore(r'\b(al\b|alin\b|alip\b|koy\b|koyun\b|koyup\b|hazir|pis)'),
    };

    bool hasStrongCooking = hasWord(['kavur', 'sotele', 'kizart', 'pisir', 'renk alana', 'kisik ateste', 'tencerede', 'tavada', 'az yagda']);
    if (hasStrongCooking) {
      if ((scores[CookingStepVisualType.panCooking] ?? 0) > 0) scores[CookingStepVisualType.panCooking] = scores[CookingStepVisualType.panCooking]! + 10;
      if ((scores[CookingStepVisualType.potCooking] ?? 0) > 0) scores[CookingStepVisualType.potCooking] = scores[CookingStepVisualType.potCooking]! + 10;
      if ((scores[CookingStepVisualType.panHeating] ?? 0) > 0) scores[CookingStepVisualType.panHeating] = scores[CookingStepVisualType.panHeating]! + 10;
      if ((scores[CookingStepVisualType.boiling] ?? 0) > 0) scores[CookingStepVisualType.boiling] = scores[CookingStepVisualType.boiling]! + 10;
      if ((scores[CookingStepVisualType.ovenCooking] ?? 0) > 0) scores[CookingStepVisualType.ovenCooking] = scores[CookingStepVisualType.ovenCooking]! + 10;
    }

    int maxScore = 0;
    CookingStepVisualType bestMatch = CookingStepVisualType.genericCooking;

    final priority = [
      CookingStepVisualType.serving,
      CookingStepVisualType.blending,
      CookingStepVisualType.kneading,
      CookingStepVisualType.filling,
      CookingStepVisualType.coating,
      CookingStepVisualType.grating,
      CookingStepVisualType.shredding,
      CookingStepVisualType.tearing,
      CookingStepVisualType.foldingCutting,
      CookingStepVisualType.straining,
      CookingStepVisualType.roasting,
      CookingStepVisualType.ovenCooking,
      CookingStepVisualType.panHeating,
      CookingStepVisualType.panCooking,
      CookingStepVisualType.potCooking,
      CookingStepVisualType.boiling,
      CookingStepVisualType.washing,
      CookingStepVisualType.cutting,
      CookingStepVisualType.sauceMixing,
      CookingStepVisualType.mixing,
      CookingStepVisualType.shaping,
      CookingStepVisualType.resting,
      CookingStepVisualType.adding,
      CookingStepVisualType.genericCooking,
    ];

    for (var type in priority) {
      if (scores[type] != null && scores[type]! > 0 && scores[type]! > maxScore) {
        maxScore = scores[type]!;
        bestMatch = type;
      }
    }

    if (isLast) {
      bestMatch = CookingStepVisualType.serving;
    }

    debugPrint('[ChefRayAnimation] stepText: $text');
    debugPrint('[ChefRayAnimation] selectedType: ${bestMatch.name}');
    
    // Matched keywords debug
    List<String> matchedCategories = [];
    scores.forEach((key, value) {
      if (value > 0) matchedCategories.add('${key.name}($value)');
    });
    debugPrint('[ChefRayAnimation] matchedCategories: ${matchedCategories.join(', ')}');
    debugPrint('[ChefRayAnimation] hasMappedWidget: true'); // We guarantee this via exhaustive switch

    return bestMatch;
  }

  @override
  Widget build(BuildContext context) {
    final type = _getStepVisualType(widget.stepText, widget.isLastStep);
    
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280, maxHeight: 320),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0),
                    radius: 0.8,
                    colors: [
                      widget.primaryColor.withValues(alpha: 0.1),
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: AnimatedBuilder(
                key: ValueKey<CookingStepVisualType>(type),
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(double.infinity, 320),
                    painter: _Modern2DIllustrationPainter(
                      type: type,
                      progress: _controller.value,
                      primary: widget.primaryColor,
                      accent: widget.accentColor,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Modern2DIllustrationPainter extends CustomPainter {
  final CookingStepVisualType type;
  final double progress;
  final Color primary;
  final Color accent;

  _Modern2DIllustrationPainter({
    required this.type,
    required this.progress,
    required this.primary,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    switch (type) {
      case CookingStepVisualType.washing: 
      case CookingStepVisualType.straining: _drawWashing(canvas, center); break;
      case CookingStepVisualType.cutting: _drawCutting(canvas, center); break;
      case CookingStepVisualType.grating: _drawGrating(canvas, center); break;
      case CookingStepVisualType.shredding: _drawShredding(canvas, center); break;
      case CookingStepVisualType.tearing: _drawTearing(canvas, center); break;
      case CookingStepVisualType.foldingCutting: _drawFoldingCutting(canvas, center); break;
      case CookingStepVisualType.adding: _drawAdding(canvas, center); break;
      case CookingStepVisualType.mixing: _drawMixing(canvas, center); break;
      case CookingStepVisualType.sauceMixing: _drawSauceMixing(canvas, center); break;
      case CookingStepVisualType.kneading: _drawKneading(canvas, center); break;
      case CookingStepVisualType.shaping: _drawShaping(canvas, center); break;
      case CookingStepVisualType.filling: _drawFilling(canvas, center); break;
      case CookingStepVisualType.coating: _drawCoating(canvas, center); break;
      case CookingStepVisualType.resting: _drawResting(canvas, center); break;
      case CookingStepVisualType.panHeating: _drawPanHeating(canvas, center); break;
      case CookingStepVisualType.panCooking: _drawPanCooking(canvas, center); break;
      case CookingStepVisualType.potCooking: 
      case CookingStepVisualType.boiling: _drawPotCooking(canvas, center); break;
      case CookingStepVisualType.roasting: _drawRoasting(canvas, center); break;
      case CookingStepVisualType.ovenCooking: _drawOvenCooking(canvas, center); break;
      case CookingStepVisualType.blending: _drawBlending(canvas, center); break;
      case CookingStepVisualType.serving: _drawServing(canvas, center); break;
      case CookingStepVisualType.genericCooking: _drawGeneric(canvas, center); break;
    }

    canvas.restore();
  }

  void _drawFlatShape(Canvas canvas, Path path, Color color) {
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawRoundedRect(Canvas canvas, Rect rect, double radius, Color color) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawCircle(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color..style = PaintingStyle.fill);
  }

  Color _darken(Color c, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
  
  Color _lighten(Color c, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  void _drawSteam(Canvas canvas, Offset base) {
    for (int i = -1; i <= 1; i++) {
      final pPhase = (progress * 1.5 + (i * 0.3)) % 1.0;
      final yOffset = -pPhase * 60;
      final xOffset = i * 20.0 + math.sin(pPhase * math.pi * 2) * 10;
      final opacity = math.sin(pPhase * math.pi);
      
      final p = Path();
      p.moveTo(base.dx + xOffset, base.dy + yOffset);
      p.quadraticBezierTo(
        base.dx + xOffset - 15, base.dy + yOffset - 15,
        base.dx + xOffset + 5, base.dy + yOffset - 30,
      );
      
      canvas.drawPath(
        p, 
        Paint()
          ..color = Colors.grey.withValues(alpha: opacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
      );
    }
  }

  void _drawWashing(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final colanderColor = const Color(0xFFD1D5DB);
    final vegColor = primary;

    _drawCircle(canvas, const Offset(-15, -15), 25, vegColor);
    _drawCircle(canvas, const Offset(15, -5), 20, accent);
    _drawCircle(canvas, const Offset(0, -25), 22, _lighten(primary));

    final cPath = Path()
      ..moveTo(-70, 0)
      ..lineTo(70, 0)
      ..quadraticBezierTo(70, 50, 40, 50)
      ..lineTo(-40, 50)
      ..quadraticBezierTo(-70, 50, -70, 0)
      ..close();
    _drawFlatShape(canvas, cPath, colanderColor);
    
    for(int i=0; i<3; i++) {
      for(int j=0; j<4; j++) {
        _drawCircle(canvas, Offset(-30.0 + j*20, 15.0 + i*12), 3, _darken(colanderColor));
      }
    }
    
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 55), width: 50, height: 10), 4, _darken(colanderColor));

    for(int i=0; i<5; i++) {
      final pPhase = (progress * 2 + (i * 0.2)) % 1.0;
      final y = -90 + (pPhase * 100);
      final x = (i - 2) * 20.0;
      final op = math.sin(pPhase * math.pi);
      
      final dropPath = Path()
        ..moveTo(x, y-5)
        ..quadraticBezierTo(x+5, y+5, x, y+10)
        ..quadraticBezierTo(x-5, y+5, x, y-5);
      
      canvas.drawPath(dropPath, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: op)..style = PaintingStyle.fill);
    }

    canvas.restore();
  }

  void _drawCutting(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final boardColor = const Color(0xFFE5E7EB);
    final boardTop = const Color(0xFFF3F4F6);
    final vegColor = accent;

    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 20), width: 180, height: 25), 8, boardColor);
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 15), width: 180, height: 25), 8, boardTop);

    for (int i = 0; i < 4; i++) {
      final x = -40.0 + (i * 25);
      _drawRoundedRect(canvas, Rect.fromCenter(center: Offset(x, -5), width: 18, height: 18), 4, vegColor);
    }

    final chopPhase = (progress * 8) % 1.0; 
    final knifeY = math.sin(chopPhase * math.pi) * 15;
    
    canvas.save();
    canvas.translate(45, -35 + knifeY);
    
    final blade = Path()
      ..moveTo(50, 15)
      ..lineTo(-40, 15)
      ..quadraticBezierTo(-60, 15, -60, 0)
      ..lineTo(50, -5)
      ..close();
    _drawFlatShape(canvas, blade, const Color(0xFFD1D5DB));
    
    _drawRoundedRect(canvas, const Rect.fromLTWH(50, -5, 45, 20), 4, const Color(0xFF374151));
    canvas.restore();

    canvas.restore();
  }

  void _drawGrating(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final boardColor = const Color(0xFFE5E7EB);
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 40), width: 180, height: 20), 8, boardColor);

    final gratePhase = math.sin(progress * math.pi * 6).abs();
    
    // Grater
    final grater = Path()..moveTo(-30, 30)..lineTo(30, 30)..lineTo(20, -50)..lineTo(-20, -50)..close();
    _drawFlatShape(canvas, grater, const Color(0xFF9CA3AF));
    // Holes
    for(int i=0; i<4; i++) {
      for(int j=0; j<2; j++) {
        _drawCircle(canvas, Offset(-10.0 + j*20, -30.0 + i*15), 3, const Color(0xFF4B5563));
      }
    }
    // Handle
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, -60), width: 30, height: 15), 5, const Color(0xFF374151));

    // Carrot
    canvas.save();
    canvas.translate(0, -10 + gratePhase * 30);
    canvas.rotate(0.5);
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(30, 0), width: 60, height: 20), 10, const Color(0xFFF97316));
    canvas.restore();

    // Shavings
    for(int i=0; i<4; i++) {
      _drawRoundedRect(canvas, Rect.fromCenter(center: Offset(-40.0 + i*10, 25.0 + (i%2)*5), width: 10, height: 4), 2, const Color(0xFFF97316));
    }

    canvas.restore();
  }

  void _drawShredding(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final meatColor = const Color(0xFFFDE68A);

    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 0), width: 80, height: 50), 15, meatColor);

    final pullPhase = math.sin(progress * math.pi * 4);
    
    // Fork 1
    canvas.save();
    canvas.translate(-20 - pullPhase*15, -20);
    canvas.rotate(-0.3);
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, -30), width: 8, height: 50), 4, const Color(0xFFD1D5DB));
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 5), width: 30, height: 8), 2, const Color(0xFF9CA3AF));
    for(int i=0; i<3; i++) {
      _drawRoundedRect(canvas, Rect.fromCenter(center: Offset(-10.0 + i*10, 15), width: 4, height: 20), 2, const Color(0xFF9CA3AF));
    }
    canvas.restore();

    // Fork 2
    canvas.save();
    canvas.translate(20 + pullPhase*15, -20);
    canvas.rotate(0.3);
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, -30), width: 8, height: 50), 4, const Color(0xFFD1D5DB));
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 5), width: 30, height: 8), 2, const Color(0xFF9CA3AF));
    for(int i=0; i<3; i++) {
      _drawRoundedRect(canvas, Rect.fromCenter(center: Offset(-10.0 + i*10, 15), width: 4, height: 20), 2, const Color(0xFF9CA3AF));
    }
    canvas.restore();

    canvas.restore();
  }

  void _drawTearing(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final pullPhase = math.sin(progress * math.pi * 4).abs();
    
    // Left leaf & hand
    canvas.save();
    canvas.translate(-10 - pullPhase*15, 0);
    _drawCircle(canvas, const Offset(0,0), 20, accent); // Leaf piece
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(-20, -10), width: 30, height: 20), 10, const Color(0xFFFDBA74)); // Hand
    canvas.restore();

    // Right leaf & hand
    canvas.save();
    canvas.translate(10 + pullPhase*15, 0);
    _drawCircle(canvas, const Offset(0,0), 20, accent);
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(20, -10), width: 30, height: 20), 10, const Color(0xFFFDBA74));
    canvas.restore();

    // Falling pieces
    _drawCircle(canvas, Offset(0, 30 + pullPhase*20), 8, accent);

    canvas.restore();
  }

  void _drawFoldingCutting(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final boardColor = const Color(0xFFE5E7EB);
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 30), width: 180, height: 20), 8, boardColor);

    // Folded dough
    final foldPhase = math.cos(progress * math.pi * 2).abs();
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(-20, 10), width: 100, height: 20), 5, const Color(0xFFFDE68A));
    _drawRoundedRect(canvas, Rect.fromCenter(center: Offset(-20 + foldPhase*10, 5), width: 90, height: 10), 5, const Color(0xFFFCD34D));

    // Knife
    final chopPhase = math.sin(progress * math.pi * 8).abs();
    canvas.save();
    canvas.translate(30, -20 + chopPhase*15);
    final blade = Path()..moveTo(10, 20)..lineTo(-30, 20)..lineTo(-30, 0)..lineTo(10, 0)..close();
    _drawFlatShape(canvas, blade, const Color(0xFFD1D5DB));
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(25, 10), width: 30, height: 15), 4, const Color(0xFF374151));
    canvas.restore();

    canvas.restore();
  }

  void _drawSauceMixing(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final bowlColor = const Color(0xFFF3F4F6); // White bowl
    final innerColor = const Color(0xFFD1D5DB);
    final sauceColor = const Color(0xFFFDE047); // Yellowish sauce (mayo/mustard)

    final bowl = Path()..moveTo(-50, 0)..lineTo(50, 0)..quadraticBezierTo(50, 40, 0, 40)..quadraticBezierTo(-50, 40, -50, 0)..close();
    _drawFlatShape(canvas, bowl, bowlColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 100, height: 20), Paint()..color = innerColor..style = PaintingStyle.fill);

    final wavePhase = progress * math.pi * 4;
    final sauce = Path()..moveTo(-40, 0)..quadraticBezierTo(0, math.sin(wavePhase)*10, 40, 0)..quadraticBezierTo(0, 15, -40, 0)..close();
    _drawFlatShape(canvas, sauce, sauceColor);

    // Small Whisk
    final stirPhase = progress * math.pi * 8;
    canvas.save();
    canvas.translate(math.cos(stirPhase)*10, -10 + math.sin(stirPhase)*5);
    canvas.rotate(0.3 + math.cos(stirPhase)*0.1);
    
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, -30), width: 6, height: 40), 3, const Color(0xFF9CA3AF));
    _drawCircle(canvas, const Offset(0, 5), 10, const Color(0xFFD1D5DB),);
    _drawCircle(canvas, const Offset(0, 5), 8, const Color(0xFF9CA3AF));
    
    canvas.restore();

    canvas.restore();
  }

  void _drawMixing(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final bowlColor = primary;
    final innerColor = _darken(primary);
    final liqColor = accent;

    final stirPhase = progress * math.pi * 4;
    canvas.save();
    canvas.translate(math.cos(stirPhase) * 20, -10 + math.sin(stirPhase) * 10);
    canvas.rotate(math.cos(stirPhase) * 0.2);
    
    final spoon = Path()
      ..moveTo(-50, -80)
      ..lineTo(-5, -5)
      ..quadraticBezierTo(10, 15, 10, 30)
      ..quadraticBezierTo(25, 15, 30, 0)
      ..quadraticBezierTo(5, -5, -30, -80)
      ..close();
    _drawFlatShape(canvas, spoon, const Color(0xFFD1D5DB));
    canvas.restore();

    final bowl = Path()
      ..moveTo(-80, 0)
      ..lineTo(80, 0)
      ..quadraticBezierTo(80, 70, 0, 70)
      ..quadraticBezierTo(-80, 70, -80, 0)
      ..close();
    _drawFlatShape(canvas, bowl, bowlColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 160, height: 30), Paint()..color = innerColor..style = PaintingStyle.fill);

    final wavePhase = progress * math.pi * 2;
    final liqPath = Path()..moveTo(-70, 0);
    liqPath.quadraticBezierTo(-35, 0 - math.sin(wavePhase)*10, 0, 0);
    liqPath.quadraticBezierTo(35, 0 + math.sin(wavePhase)*10, 70, 0);
    liqPath.quadraticBezierTo(0, 20, -70, 0);
    _drawFlatShape(canvas, liqPath, liqColor);

    canvas.restore();
  }

  void _drawKneading(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final bowlColor = const Color(0xFFE5E7EB);
    final innerColor = const Color(0xFFD1D5DB);
    final doughColor = const Color(0xFFFDE68A);

    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 160, height: 30), Paint()..color = innerColor..style = PaintingStyle.fill);

    final pressPhase = math.sin(progress * math.pi * 8).abs();
    
    final doughW = 80 + pressPhase * 20;
    final doughH = 40 - pressPhase * 10;
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -10 + (pressPhase * 5)), width: doughW, height: doughH), Paint()..color = doughColor..style = PaintingStyle.fill);

    canvas.save();
    canvas.translate(0, -30 + pressPhase * 15);
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(-20, -10), width: 20, height: 35), 10, const Color(0xFFFDBA74));
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(20, -10), width: 20, height: 35), 10, const Color(0xFFFDBA74));
    canvas.restore();

    final bowl = Path()
      ..moveTo(-80, 0)
      ..lineTo(80, 0)
      ..quadraticBezierTo(80, 70, 0, 70)
      ..quadraticBezierTo(-80, 70, -80, 0)
      ..close();
    
    canvas.drawPath(bowl, Paint()..color = bowlColor..style = PaintingStyle.stroke..strokeWidth=8);

    canvas.restore();
  }

  void _drawShaping(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final boardColor = const Color(0xFFE5E7EB);
    final boardTop = const Color(0xFFF3F4F6);
    final doughColor = const Color(0xFFFDE68A);

    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 20), width: 180, height: 25), 8, boardColor);
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 15), width: 180, height: 25), 8, boardTop);

    _drawCircle(canvas, const Offset(-40, 5), 15, doughColor);
    _drawCircle(canvas, const Offset(-70, 0), 12, doughColor);

    final rollPhase = progress * math.pi * 4;
    final rx = math.sin(rollPhase) * 20;
    final ry = math.cos(rollPhase) * 5;

    _drawCircle(canvas, Offset(20 + rx, -5 + ry), 16, doughColor);

    final hPhase = math.sin(progress * math.pi * 8).abs();
    _drawRoundedRect(canvas, Rect.fromCenter(center: Offset(20 + rx, -25 + hPhase*5), width: 40, height: 20), 10, const Color(0xFFFDBA74));

    canvas.restore();
  }

  void _drawFilling(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final vegColor = const Color(0xFF6B21A8); 
    final fillingColor = accent;

    final eggplant = Path()
      ..moveTo(-40, -10)
      ..lineTo(40, -10)
      ..quadraticBezierTo(45, 60, 0, 60)
      ..quadraticBezierTo(-45, 60, -40, -10)
      ..close();
    _drawFlatShape(canvas, eggplant, vegColor);

    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -10), width: 80, height: 20), Paint()..color = _darken(vegColor)..style = PaintingStyle.fill);

    for(int i=0; i<4; i++) {
      final pPhase = (progress * 2 + (i * 0.25)) % 1.0;
      final y = -60 + (pPhase * 60);
      final x = math.sin(i * 10) * 10;
      _drawCircle(canvas, Offset(x, y), 5, fillingColor.withValues(alpha: math.sin(pPhase * math.pi)));
    }

    final scoopPhase = math.sin(progress * math.pi * 2);
    canvas.save();
    canvas.translate(20, -50 + scoopPhase*10);
    canvas.rotate(-0.5 + scoopPhase*0.2);
    final spoon = Path()
      ..moveTo(30, -30)
      ..lineTo(5, -5)
      ..quadraticBezierTo(-10, 10, -20, 0)
      ..quadraticBezierTo(-10, -10, 5, 5)
      ..close();
    _drawFlatShape(canvas, spoon, const Color(0xFFD1D5DB));
    canvas.restore();

    canvas.restore();
  }

  void _drawOvenCooking(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final ovenColor = const Color(0xFF374151);
    final windowColor = const Color(0xFF9CA3AF);

    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 0), width: 140, height: 120), 12, ovenColor);
    
    _drawCircle(canvas, const Offset(-45, -40), 8, _lighten(ovenColor));
    _drawCircle(canvas, const Offset(45, -40), 8, _lighten(ovenColor));
    
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 15), width: 100, height: 60), 8, windowColor);

    final glow = (math.sin(progress * math.pi * 4) + 1) / 2;
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 15), width: 90, height: 50), 6, const Color(0xFFF59E0B).withValues(alpha: 0.3 + glow * 0.3));

    canvas.restore();
  }

  void _drawRoasting(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final grillColor = const Color(0xFF374151);
    
    // Fire
    for (int i = -2; i <= 2; i++) {
      final fPhase = (progress * 6 + i * 0.5) % 1.0;
      final fx = i * 25.0;
      final fy = 30 - math.sin(fPhase * math.pi) * 10;
      final flame = Path()
        ..moveTo(fx, fy)
        ..quadraticBezierTo(fx+10, fy+10, fx+5, fy+25)
        ..quadraticBezierTo(fx, fy+15, fx-5, fy+25)
        ..quadraticBezierTo(fx-10, fy+10, fx, fy)
        ..close();
      _drawFlatShape(canvas, flame, const Color(0xFFEF4444));
      _drawFlatShape(canvas, flame, const Color(0xFFF59E0B).withValues(alpha: 0.5));
    }

    // Grill Rack
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 10), width: 160, height: 5), 2, grillColor);
    for(int i=-3; i<=3; i++) {
      _drawRoundedRect(canvas, Rect.fromCenter(center: Offset(i*20.0, 10), width: 5, height: 20), 2, grillColor);
    }

    // Eggplant / Veggie
    final roastPhase = math.sin(progress * math.pi * 2).abs();
    canvas.save();
    canvas.translate(0, -10 - roastPhase*5);
    final veg = Path()..moveTo(-40, 0)..quadraticBezierTo(0, -30, 40, 0)..quadraticBezierTo(0, 20, -40, 0)..close();
    _drawFlatShape(canvas, veg, const Color(0xFF6B21A8)); // Purple
    canvas.restore();

    canvas.restore();
  }

  void _drawResting(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final bowlColor = const Color(0xFFE5E7EB);
    final towelColor = primary;

    final bowl = Path()
      ..moveTo(-80, 0)
      ..lineTo(80, 0)
      ..quadraticBezierTo(80, 70, 0, 70)
      ..quadraticBezierTo(-80, 70, -80, 0)
      ..close();
    _drawFlatShape(canvas, bowl, bowlColor);

    final towel = Path()
      ..moveTo(-90, 10)
      ..quadraticBezierTo(-40, -40, 0, -40)
      ..quadraticBezierTo(40, -40, 90, 10)
      ..quadraticBezierTo(50, 0, 0, 0)
      ..quadraticBezierTo(-50, 0, -90, 10)
      ..close();
    _drawFlatShape(canvas, towel, towelColor);

    final tickPhase = (progress * 8) % 1.0;
    canvas.save();
    canvas.translate(0, -60);
    if(tickPhase < 0.1) canvas.rotate(0.1);
    _drawCircle(canvas, const Offset(0,0), 15, Colors.white);
    canvas.drawCircle(const Offset(0,0), 15, Paint()..color = const Color(0xFF9CA3AF)..style = PaintingStyle.stroke..strokeWidth = 3);
    
    canvas.drawLine(const Offset(0,0), Offset(math.cos(progress * math.pi * 4) * 8, math.sin(progress * math.pi * 4) * 8), Paint()..color=const Color(0xFF374151)..strokeWidth=2);
    canvas.restore();

    canvas.restore();
  }

  void _drawCoating(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 20), width: 100, height: 40), 20, const Color(0xFFFDE68A));

    final brushX = math.sin(progress * math.pi * 4) * 40;
    
    canvas.save();
    canvas.translate(brushX, -10);
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(20, -30), width: 10, height: 40), 5, const Color(0xFFD1D5DB));
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(20, -5), width: 20, height: 15), 2, const Color(0xFFFDBA74));
    canvas.restore();

    canvas.restore();
  }

  void _drawAdding(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final potColor = const Color(0xFFF97316); 
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 30), width: 120, height: 80), 12, potColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -10), width: 120, height: 20), Paint()..color = _darken(potColor)..style = PaintingStyle.fill);

    for(int i=0; i<6; i++) {
      final pPhase = (progress * 2 + (i * 0.16)) % 1.0;
      final y = -90 + (pPhase * 90);
      final x = math.sin(i * 10) * 20;
      final op = math.sin(pPhase * math.pi);
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(pPhase * math.pi * 4);
      final color = i % 2 == 0 ? primary : accent;
      _drawRoundedRect(canvas, const Rect.fromLTWH(-6, -6, 12, 12), 3, color.withValues(alpha: op));
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawPanHeating(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final panColor = const Color(0xFF374151);

    final handle = Path()..moveTo(60, 0)..lineTo(140, -20)..lineTo(140, -10)..lineTo(60, 10)..close();
    _drawFlatShape(canvas, handle, _darken(panColor));

    final pan = Path()
      ..moveTo(-70, -10)
      ..lineTo(70, -10)
      ..quadraticBezierTo(60, 20, 40, 20)
      ..lineTo(-40, 20)
      ..quadraticBezierTo(-60, 20, -70, -10)
      ..close();
    _drawFlatShape(canvas, pan, panColor);
    
    // Empty pan surface
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -10), width: 140, height: 15), Paint()..color = _lighten(panColor)..style = PaintingStyle.fill);

    // Liquid oil pool forming
    final oilSize = (math.sin(progress * math.pi * 2) + 1.5) * 40;
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -10), width: oilSize, height: oilSize/10), Paint()..color = const Color(0xFFFDE047).withValues(alpha: 0.8)..style = PaintingStyle.fill);

    // Flames
    for (int i = -1; i <= 1; i++) {
      final fPhase = (progress * 6 + i * 0.3) % 1.0;
      final fx = i * 20.0;
      final fy = 30 - math.sin(fPhase * math.pi) * 5;
      final flame = Path()
        ..moveTo(fx, fy)
        ..quadraticBezierTo(fx+6, fy+4, fx+4, fy+12)
        ..quadraticBezierTo(fx, fy+8, fx-4, fy+12)
        ..quadraticBezierTo(fx-6, fy+4, fx, fy)
        ..close();
      _drawFlatShape(canvas, flame, const Color(0xFFFBBF24));
    }

    canvas.restore();
  }

  void _drawPanCooking(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final panColor = const Color(0xFF374151);

    final handle = Path()..moveTo(60, 0)..lineTo(140, -20)..lineTo(140, -10)..lineTo(60, 10)..close();
    _drawFlatShape(canvas, handle, _darken(panColor));

    final pan = Path()
      ..moveTo(-70, -10)
      ..lineTo(70, -10)
      ..quadraticBezierTo(60, 20, 40, 20)
      ..lineTo(-40, 20)
      ..quadraticBezierTo(-60, 20, -70, -10)
      ..close();
    _drawFlatShape(canvas, pan, panColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -10), width: 140, height: 15), Paint()..color = _lighten(panColor)..style = PaintingStyle.fill);

    final tossPhase = (progress * 4) % 1.0;
    for(int i=0; i<3; i++) {
      final x = -20.0 + i*20;
      final y = -15 - math.sin(tossPhase * math.pi) * (20 + i*5);
      _drawRoundedRect(canvas, Rect.fromCenter(center: Offset(x, y), width: 14, height: 14), 4, i%2==0 ? accent : primary);
    }

    for (int i = -1; i <= 1; i++) {
      final fPhase = (progress * 6 + i * 0.3) % 1.0;
      final fx = i * 20.0;
      final fy = 30 - math.sin(fPhase * math.pi) * 5;
      final flame = Path()
        ..moveTo(fx, fy)
        ..quadraticBezierTo(fx+6, fy+4, fx+4, fy+12)
        ..quadraticBezierTo(fx, fy+8, fx-4, fy+12)
        ..quadraticBezierTo(fx-6, fy+4, fx, fy)
        ..close();
      _drawFlatShape(canvas, flame, const Color(0xFFFBBF24));
    }

    canvas.restore();
  }

  void _drawPotCooking(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy + 10);

    final potColor = primary;

    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(-75, 10), width: 20, height: 30), 4, _darken(potColor));
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(75, 10), width: 20, height: 30), 4, _darken(potColor));

    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 30), width: 140, height: 90), 16, potColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -15), width: 140, height: 20), Paint()..color = _darken(potColor)..style = PaintingStyle.fill);

    final bounce = math.sin(progress * math.pi * 10).abs() * 3;
    canvas.save();
    canvas.translate(0, -20 - bounce);
    final lid = Path()..moveTo(-75, 0)..lineTo(75, 0)..quadraticBezierTo(0, -30, -75, 0)..close();
    _drawFlatShape(canvas, lid, _lighten(potColor));
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, -15), width: 20, height: 10), 3, _darken(potColor));
    canvas.restore();

    for (int i = -1; i <= 1; i++) {
      final fPhase = (progress * 5 + i * 0.3) % 1.0;
      final fx = i * 30.0;
      final fy = 80 - math.sin(fPhase * math.pi) * 6;
      final flame = Path()
        ..moveTo(fx, fy)
        ..quadraticBezierTo(fx+8, fy+5, fx+5, fy+15)
        ..quadraticBezierTo(fx, fy+10, fx-5, fy+15)
        ..quadraticBezierTo(fx-8, fy+5, fx, fy)
        ..close();
      _drawFlatShape(canvas, flame, const Color(0xFFF59E0B));
    }

    _drawSteam(canvas, const Offset(0, -40));

    canvas.restore();
  }

  void _drawBlending(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final vibrateX = math.sin(progress * math.pi * 30) * 2;
    
    final potColor = const Color(0xFFE5E7EB);
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 45), width: 120, height: 70), 12, potColor);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 10), width: 120, height: 20), Paint()..color = _darken(potColor)..style = PaintingStyle.fill);

    final wave = math.sin(progress * math.pi * 6) * 5;
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 10 + wave), width: 100, height: 15), Paint()..color = accent..style = PaintingStyle.fill);

    canvas.save();
    canvas.translate(vibrateX, 0);
    
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, -20), width: 16, height: 70), 4, const Color(0xFF9CA3AF));
    final head = Path()..moveTo(-20, 20)..lineTo(20, 20)..lineTo(10, 0)..lineTo(-10, 0)..close();
    _drawFlatShape(canvas, head, const Color(0xFF6B7280));
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, -70), width: 30, height: 50), 10, primary);
    _drawCircle(canvas, const Offset(0, -65), 5, Colors.white);
    
    canvas.restore();

    for(int i=0; i<3; i++) {
      final pPhase = (progress * 6 + i*0.3) % 1.0;
      final px = (i-1) * 25.0;
      final py = 10 - math.sin(pPhase * math.pi) * 20;
      _drawCircle(canvas, Offset(px, py), 4, accent.withValues(alpha: math.sin(pPhase * math.pi)));
    }

    canvas.restore();
  }

  void _drawServing(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy + 20);

    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 15), width: 200, height: 50), Paint()..color = primary.withValues(alpha: 0.2)..style = PaintingStyle.fill);

    final bowl = Path()
      ..moveTo(-70, -10)
      ..lineTo(70, -10)
      ..quadraticBezierTo(60, 30, 0, 30)
      ..quadraticBezierTo(-60, 30, -70, -10)
      ..close();
    _drawFlatShape(canvas, bowl, Colors.white);
    
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -10), width: 140, height: 20), Paint()..color = const Color(0xFFF3F4F6)..style = PaintingStyle.fill);

    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -10), width: 110, height: 15), Paint()..color = accent..style = PaintingStyle.fill);
    
    final leaf = Path()..moveTo(0, -15)..quadraticBezierTo(5, -20, 10, -15)..quadraticBezierTo(5, -10, 0, -15)..close();
    _drawFlatShape(canvas, leaf, primary);

    _drawSteam(canvas, const Offset(0, -20));

    for(int i=0; i<4; i++) {
      final sPhase = (progress + (i * 0.25)) % 1.0;
      final x = math.cos(i * math.pi/2) * 80;
      final y = -20 + math.sin(i * math.pi/2) * 30 - (sPhase * 20);
      final opacity = math.sin(sPhase * math.pi);
      
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(opacity);
      canvas.rotate(sPhase * math.pi);
      final star = Path()
        ..moveTo(0, -8)
        ..quadraticBezierTo(2, -2, 8, 0)
        ..quadraticBezierTo(2, 2, 0, 8)
        ..quadraticBezierTo(-2, 2, -8, 0)
        ..quadraticBezierTo(-2, -2, 0, -8)
        ..close();
      _drawFlatShape(canvas, star, const Color(0xFFFBBF24));
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawGeneric(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final floatPhase = math.sin(progress * math.pi * 2) * 5;
    canvas.translate(0, floatPhase);

    final hat = Path()
      ..moveTo(-35, 10)
      ..lineTo(35, 10)
      ..lineTo(40, -15)
      ..quadraticBezierTo(50, -15, 50, -30)
      ..quadraticBezierTo(35, -45, 15, -35)
      ..quadraticBezierTo(0, -55, -15, -35)
      ..quadraticBezierTo(-35, -45, -50, -30)
      ..quadraticBezierTo(-50, -15, -40, -15)
      ..lineTo(-35, 10)
      ..close();
      
    _drawFlatShape(canvas, hat, Colors.white);
    
    _drawRoundedRect(canvas, Rect.fromCenter(center: const Offset(0, 20), width: 80, height: 20), 4, primary);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Modern2DIllustrationPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.type != type;
  }
}
