import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Reusable glassmorphic input field for authentication screens.
class AuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixWidget;
  final void Function(String)? onFieldSubmitted;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.suffixWidget,
    this.onFieldSubmitted,
  });

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _focusCtrl;
  late final Animation<double> _focusAnim;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _focusAnim = CurvedAnimation(parent: _focusCtrl, curve: Curves.easeOut);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _focusCtrl.forward();
      } else {
        _focusCtrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary
                    .withValues(alpha: 0.10 * _focusAnim.value),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            onFieldSubmitted: widget.onFieldSubmitted,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textHint),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 18, right: 12),
                child: Icon(widget.icon,
                    color: _focusNode.hasFocus
                        ? AppColors.primary
                        : AppColors.textLight,
                    size: 20),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 50, minHeight: 0),
              suffixIcon: widget.suffixWidget,
              filled: true,
              fillColor: AppColors.backgroundWhite,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide:
                    const BorderSide(color: AppColors.divider, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 1.5),
              ),
              errorStyle: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.error, height: 1.4),
            ),
          ),
        );
      },
    );
  }
}
