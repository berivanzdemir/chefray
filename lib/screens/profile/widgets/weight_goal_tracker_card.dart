import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeightGoalTrackerCard extends StatefulWidget {
  final double fallbackWeight;

  const WeightGoalTrackerCard({
    super.key,
    required this.fallbackWeight,
  });

  @override
  State<WeightGoalTrackerCard> createState() => _WeightGoalTrackerCardState();
}

class _WeightGoalTrackerCardState extends State<WeightGoalTrackerCard> {
  double? _startWeight;
  double? _currentWeight;
  double? _targetWeight;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _startWeight = prefs.getDouble('wgt_startWeight');
      _currentWeight = prefs.getDouble('wgt_currentWeight');
      _targetWeight = prefs.getDouble('wgt_targetWeight');
      _isInitialized = true;
    });
  }

  Future<void> _saveData(double start, double current, double target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('wgt_startWeight', start);
    await prefs.setDouble('wgt_currentWeight', current);
    await prefs.setDouble('wgt_targetWeight', target);
    await prefs.setString('wgt_lastUpdatedDate', DateTime.now().toIso8601String());
    setState(() {
      _startWeight = start;
      _currentWeight = current;
      _targetWeight = target;
    });
  }

  Future<void> _saveCurrentWeightOnly(double current) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('wgt_currentWeight', current);
    await prefs.setString('wgt_lastUpdatedDate', DateTime.now().toIso8601String());
    setState(() {
      _currentWeight = current;
    });
  }

  bool get _hasData => _startWeight != null && _currentWeight != null && _targetWeight != null;

  double get startWeight => _startWeight ?? widget.fallbackWeight;
  double get currentWeight => _currentWeight ?? widget.fallbackWeight;
  double get targetWeight => _targetWeight ?? (widget.fallbackWeight - 5.0);

  double get _diff => currentWeight - startWeight;
  double get _totalGoal => (startWeight - targetWeight).abs();
  double get _remainingWeight => (currentWeight - targetWeight).abs();

  double get _progress {
    if (_totalGoal == 0) return 0.0;
    // Eğer kilo verme hedefi ise (start > target)
    if (startWeight > targetWeight) {
      return ((startWeight - currentWeight) / (startWeight - targetWeight)).clamp(0.0, 1.0);
    } 
    // Eğer kilo alma hedefi ise (target > start)
    else if (targetWeight > startWeight) {
      return ((currentWeight - startWeight) / (targetWeight - startWeight)).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  int get _progressPercent => (_progress * 100).toInt();

  void _openWeightForm({bool isEditTarget = false}) {
    if (!_hasData || isEditTarget) {
      _showFullFormModal();
    } else {
      _showCurrentWeightFormModal();
    }
  }

  void _showFullFormModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FullWeightForm(
        initialStart: _startWeight ?? widget.fallbackWeight,
        initialCurrent: _currentWeight ?? widget.fallbackWeight,
        initialTarget: _targetWeight ?? (widget.fallbackWeight - 5.0),
        onSave: (start, current, target) {
          _saveData(start, current, target);
        },
      ),
    );
  }

  void _showCurrentWeightFormModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrentWeightForm(
        initialCurrent: currentWeight,
        onSave: (current) {
          _saveCurrentWeightOnly(current);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title Row ──
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hedef Kilo Takibim',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (_hasData)
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20, color: cs.primary),
                  onPressed: () => _openWeightForm(isEditTarget: true),
                  tooltip: 'Hedefi Düzenle',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              if (_hasData) const SizedBox(width: 8),
              _AddWeightButton(
                onTap: () => _openWeightForm(),
                colorScheme: cs,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Stat Boxes ──
          Row(
            children: [
              _StatBox(
                label: 'Başlangıç',
                value: '${startWeight.toStringAsFixed(1)} kg',
                subtitle: 'İlk kayıt',
                icon: Icons.flag_outlined,
                accentColor: cs.onSurfaceVariant,
                colorScheme: cs,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatBox(
                label: 'Mevcut',
                value: '${currentWeight.toStringAsFixed(1)} kg',
                subtitle: _getDiffSubtitle(),
                icon: Icons.monitor_weight_outlined,
                accentColor: _diff <= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                colorScheme: cs,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatBox(
                label: 'Hedef',
                value: '${targetWeight.toStringAsFixed(1)} kg',
                subtitle: 'Toplam ${_totalGoal.toStringAsFixed(1)} kg',
                icon: Icons.emoji_events_outlined,
                accentColor: const Color(0xFF42A5F5),
                colorScheme: cs,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatBox(
                label: 'Kalan',
                value: '${_remainingWeight.toStringAsFixed(1)} kg',
                subtitle: 'Hedefe kaldı',
                icon: Icons.local_fire_department_rounded,
                accentColor: const Color(0xFFFF9800),
                colorScheme: cs,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Progress Bar ──
          _ProgressSection(
            startWeight: startWeight,
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            progress: _progress,
            colorScheme: cs,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // ── Bottom message + decorative assets ──
          _BottomSection(
            progressPercent: _progressPercent,
            message: _getStatusMessage(),
            colorScheme: cs,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  String _getDiffSubtitle() {
    if (_diff < 0) {
      return '↓ ${_diff.abs().toStringAsFixed(1)} kg kayıp';
    } else if (_diff > 0) {
      return '↑ ${_diff.abs().toStringAsFixed(1)} kg artış';
    } else {
      return 'Değişim yok';
    }
  }

  String _getStatusMessage() {
    if (!_hasData) return 'Kilo takibini başlat. ✨';
    if (_progressPercent >= 100) return 'Hedefine ulaştın, harika gidiyorsun! 🏆';
    if (_progressPercent > 0) return 'Hedefe doğru ilerliyorsun. 💚';
    if (_progressPercent == 0 && _diff != 0) return 'Takibe devam et, küçük adımlar önemli. 🌱';
    return 'Kilo takibini başlat. ✨';
  }
}

// ── Add Weight Button ──
class _AddWeightButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _AddWeightButton({required this.onTap, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha:0.5),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Tartı Ekle',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Box ──
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final ColorScheme colorScheme;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest
              : accentColor.withValues(alpha:0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? colorScheme.outline.withValues(alpha:0.15)
                : accentColor.withValues(alpha:0.12),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timeline Painter ──
class TimelineTrackPainter extends CustomPainter {
  final double progress; 
  final Color activeColor;
  final Color inactiveColor;

  TimelineTrackPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double trackWidth = size.width;
    final double activeWidth = trackWidth * progress;
    final double centerY = size.height / 2;

    // Active solid line
    final Paint activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    if (activeWidth > 0) {
      canvas.drawLine(Offset(0, centerY), Offset(activeWidth, centerY), activePaint);
    }

    // Inactive dotted/dashed line
    final Paint inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    double dashWidth = 5.0;
    double dashSpace = 4.0;
    double startX = activeWidth > 0 ? activeWidth + dashSpace : 0;
    while (startX < trackWidth) {
      double endX = startX + dashWidth;
      if (endX > trackWidth) endX = trackWidth;
      canvas.drawLine(Offset(startX, centerY), Offset(endX, centerY), inactivePaint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant TimelineTrackPainter oldDelegate) => 
    oldDelegate.progress != progress ||
    oldDelegate.activeColor != activeColor ||
    oldDelegate.inactiveColor != inactiveColor;
}

// ── Progress Section (Timeline Journey) ──
class _ProgressSection extends StatelessWidget {
  final double startWeight;
  final double targetWeight;
  final double currentWeight;
  final double progress;
  final ColorScheme colorScheme;
  final bool isDark;

  const _ProgressSection({
    required this.startWeight,
    required this.targetWeight,
    required this.currentWeight,
    required this.progress,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    double safeProgress = 0.0;
    if (startWeight != targetWeight) {
      safeProgress = (currentWeight - startWeight) / (targetWeight - startWeight);
      safeProgress = safeProgress.clamp(0.0, 1.0);
    } else {
      safeProgress = 1.0;
    }

    List<int> interWeights = [];
    List<double> placeholderRatios = [];
    double diff = (startWeight - targetWeight).abs();
    
    if (diff > 0 && diff <= 12) {
      int startInt = startWeight.round();
      int targetInt = targetWeight.round();
      int step = startInt < targetInt ? 1 : -1;
      int curr = startInt + step;
      int loopCount = 0;
      while (curr != targetInt && loopCount < 15) {
        interWeights.add(curr);
        curr += step;
        loopCount++;
      }
    } else if (diff > 12) {
      int numDots = 4;
      for (int i = 1; i <= numDots; i++) {
        placeholderRatios.add(i / (numDots + 1));
      }
    }

    Color inactiveColor = isDark ? colorScheme.outline.withAlpha(80) : const Color(0xFFCFD8DC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double trackWidth = constraints.maxWidth - 72.0;
          if (trackWidth <= 0) return const SizedBox();

          final double pinLeft = 36.0 + safeProgress * trackWidth;

          double badgeLeft = pinLeft - 28;
          badgeLeft = badgeLeft.clamp(0.0, constraints.maxWidth - 56.0);

          return SizedBox(
            height: 110,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1) Track Line (CustomPainter)
                Positioned(
                  top: 56, // centerY of track line
                  left: 36,
                  right: 36,
                  child: SizedBox(
                    height: 0,
                    child: CustomPaint(
                      painter: TimelineTrackPainter(
                        progress: safeProgress,
                        activeColor: colorScheme.primary,
                        inactiveColor: inactiveColor,
                      ),
                    ),
                  ),
                ),

                // 2) Intermediate Dots & Texts
                ...interWeights.map((w) {
                  double ratio = (w - startWeight) / (targetWeight - startWeight);
                  ratio = ratio.clamp(0.0, 1.0);
                  double dotLeft = 36.0 + ratio * trackWidth;
                  bool isPassed = ratio <= safeProgress;
                  return Positioned(
                    top: 56 - 4, // center at 56, size 8 => top 52
                    left: dotLeft - 4,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: isPassed ? colorScheme.primary : inactiveColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
                ...interWeights.map((w) {
                  double ratio = (w - startWeight) / (targetWeight - startWeight);
                  ratio = ratio.clamp(0.0, 1.0);
                  double dotLeft = 36.0 + ratio * trackWidth;
                  return Positioned(
                    top: 68,
                    left: dotLeft - 20,
                    width: 40,
                    child: Text(
                      w.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }),

                // Placeholders if diff > 12
                ...placeholderRatios.map((ratio) {
                  double dotLeft = 36.0 + ratio * trackWidth;
                  bool isPassed = ratio <= safeProgress;
                  return Positioned(
                    top: 56 - 4, 
                    left: dotLeft - 4,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: isPassed ? colorScheme.primary : inactiveColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),

                // 3) Start Node Elements
                Positioned(
                  top: 24, left: 0, width: 72,
                  child: Text(
                    '${startWeight.toStringAsFixed(1)} kg',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                ),
                Positioned(
                  top: 56 - 8, left: 36 - 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 3.5),
                    ),
                  ),
                ),
                Positioned(
                  top: 68, left: 0, width: 72,
                  child: Column(
                    children: [
                      Text(startWeight.round().toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      Text('Başlangıç', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),

                // 4) Target Node Elements
                Positioned(
                  top: 24, right: 0, width: 72,
                  child: Text(
                    '${targetWeight.toStringAsFixed(1)} kg',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                ),
                Positioned(
                  top: 56 - 8, right: 36 - 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: safeProgress >= 1.0 ? colorScheme.primary : inactiveColor, width: 3.5),
                    ),
                  ),
                ),
                Positioned(
                  top: 68, right: 0, width: 72,
                  child: Column(
                    children: [
                      Text(targetWeight.round().toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      Text('Hedef', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),

                // 5) Current Node & Badge
                Positioned(
                  top: 0, left: badgeLeft, width: 56,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${currentWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                    ),
                  ),
                ),
                // Badge tail (tiny arrow down)
                Positioned(
                  top: 18, left: pinLeft - 12,
                  child: Icon(Icons.arrow_drop_down, size: 24, color: colorScheme.primary),
                ),
                Positioned(
                  top: 56 - 7, left: pinLeft - 7,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                      boxShadow: [
                        BoxShadow(color: colorScheme.primary.withAlpha(80), blurRadius: 4, spreadRadius: 1)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Bottom Section ──
class _BottomSection extends StatelessWidget {
  final int progressPercent;
  final String message;
  final ColorScheme colorScheme;
  final bool isDark;

  const _BottomSection({
    required this.progressPercent,
    required this.message,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 10, bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [
                  colorScheme.primary.withValues(alpha:0.08),
                  colorScheme.surfaceContainerHighest.withValues(alpha:0.6),
                  colorScheme.primary.withValues(alpha:0.05),
                ]
              : [
                  const Color(0xFFE8F5E9).withValues(alpha:0.7),
                  const Color(0xFFF1F8E9).withValues(alpha:0.5),
                  const Color(0xFFE0F2F1).withValues(alpha:0.6),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? colorScheme.primary.withValues(alpha:0.12)
              : const Color(0xFFC8E6C9).withValues(alpha:0.6),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Yıldız görseli — sol
          Image.asset(
            'assets/yildiz.png',
            width: 42,
            height: 42,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.star_rounded,
              size: 36,
              color: isDark ? colorScheme.primary.withValues(alpha:0.6) : const Color(0xFFFFC107),
            ),
          ),
          const SizedBox(width: 8),
          // Ortadaki chip + metin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha:isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hedefime: %$progressPercent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Tartı görseli — sağ, belirgin ve büyük (80-90px bandı, padding/kırpma olmadan)
          Image.asset(
            'assets/tarti.png',
            width: 86,
            height: 86,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.monitor_weight_outlined,
              size: 64,
              color: isDark ? colorScheme.onSurfaceVariant.withValues(alpha:0.5) : const Color(0xFF81C784),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modals ──
class _FullWeightForm extends StatefulWidget {
  final double initialStart;
  final double initialCurrent;
  final double initialTarget;
  final Function(double, double, double) onSave;

  const _FullWeightForm({
    required this.initialStart,
    required this.initialCurrent,
    required this.initialTarget,
    required this.onSave,
  });

  @override
  State<_FullWeightForm> createState() => _FullWeightFormState();
}

class _FullWeightFormState extends State<_FullWeightForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _startCtrl;
  late TextEditingController _currentCtrl;
  late TextEditingController _targetCtrl;

  @override
  void initState() {
    super.initState();
    _startCtrl = TextEditingController(text: widget.initialStart.toStringAsFixed(1));
    _currentCtrl = TextEditingController(text: widget.initialCurrent.toStringAsFixed(1));
    _targetCtrl = TextEditingController(text: widget.initialTarget.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _currentCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final s = double.parse(_startCtrl.text.replaceAll(',', '.'));
      final c = double.parse(_currentCtrl.text.replaceAll(',', '.'));
      final t = double.parse(_targetCtrl.text.replaceAll(',', '.'));
      widget.onSave(s, c, t);
      Navigator.of(context).pop();
    }
  }

  String? _validateWeight(String? val) {
    if (val == null || val.trim().isEmpty) return 'Lütfen kilo değerini gir.';
    final number = double.tryParse(val.replaceAll(',', '.'));
    if (number == null) return 'Geçerli bir sayı gir.';
    if (number <= 0) return 'Kilo 0\'dan büyük olmalı.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomInset + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hedef Kilo Kurulumu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildField('Başlangıç Kilosu (kg)', _startCtrl, cs),
            const SizedBox(height: 16),
            _buildField('Mevcut Kilo (kg)', _currentCtrl, cs),
            const SizedBox(height: 16),
            _buildField('Hedef Kilo (kg)', _targetCtrl, cs),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: cs.outline.withValues(alpha:0.5)),
                    ),
                    child: Text('İptal', style: TextStyle(color: cs.onSurface)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, ColorScheme cs) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outline.withValues(alpha:0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outline.withValues(alpha:0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      validator: _validateWeight,
    );
  }
}

class _CurrentWeightForm extends StatefulWidget {
  final double initialCurrent;
  final Function(double) onSave;

  const _CurrentWeightForm({required this.initialCurrent, required this.onSave});

  @override
  State<_CurrentWeightForm> createState() => _CurrentWeightFormState();
}

class _CurrentWeightFormState extends State<_CurrentWeightForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _currentCtrl;

  @override
  void initState() {
    super.initState();
    _currentCtrl = TextEditingController(text: widget.initialCurrent.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final c = double.parse(_currentCtrl.text.replaceAll(',', '.'));
      widget.onSave(c);
      Navigator.of(context).pop();
    }
  }

  String? _validateWeight(String? val) {
    if (val == null || val.trim().isEmpty) return 'Lütfen kilo değerini gir.';
    final number = double.tryParse(val.replaceAll(',', '.'));
    if (number == null) return 'Geçerli bir sayı gir.';
    if (number <= 0) return 'Kilo 0\'dan büyük olmalı.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomInset + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Yeni Tartı Kaydı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _currentCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Mevcut Kilo (kg)',
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha:0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha:0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
              ),
              validator: _validateWeight,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: cs.outline.withValues(alpha:0.5)),
                    ),
                    child: Text('İptal', style: TextStyle(color: cs.onSurface)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
