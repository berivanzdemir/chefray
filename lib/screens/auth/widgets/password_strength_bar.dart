import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Animated password strength indicator bar for the register screen.
class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  _StrengthState _evaluate(String p) {
    if (p.length < 6) return _StrengthState.weak;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}<>]').hasMatch(p)) score++;
    if (score <= 1) return _StrengthState.weak;
    if (score == 2) return _StrengthState.fair;
    if (score == 3) return _StrengthState.good;
    return _StrengthState.strong;
  }

  @override
  Widget build(BuildContext context) {
    final level = _evaluate(password);
    final ratio = (level.index + 1) / 4;
    final color = level.color;
    final label = level.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (context, value, child) => LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              'Şifre gücü: $label',
              style: AppTextStyles.labelSmall.copyWith(color: color),
            ),
          ],
        ),
      ],
    );
  }
}

enum _StrengthState {
  weak('Zayıf', Color(0xFFFF6B6B)),
  fair('Orta', Color(0xFFFFA726)),
  good('İyi', Color(0xFF5BC0EB)),
  strong('Güçlü', Color(0xFF2DFF88));

  final String label;
  final Color color;
  const _StrengthState(this.label, this.color);
}
