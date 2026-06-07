import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Premium social login button for Google and Apple authentication.
///
/// Tries to load [assets/icons/<iconAsset>.png] first.
/// Falls back to a Material icon if the asset is missing, so the app
/// never crashes in development when PNG files are not yet present.
class AuthSocialButton extends StatefulWidget {
  final String label;

  /// 'google' or 'apple'
  final String iconAsset;
  final VoidCallback onTap;
  final bool isLoading;

  const AuthSocialButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<AuthSocialButton> createState() => _AuthSocialButtonState();
}

class _AuthSocialButtonState extends State<AuthSocialButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.isLoading) return;
    setState(() => _pressed = true);
    _pressCtrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    _pressCtrl.reverse();
    if (!widget.isLoading) widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressed ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.02 : 0.05),
                blurRadius: _pressed ? 4 : 12,
                offset: Offset(0, _pressed ? 1 : 3),
                spreadRadius: 0,
              ),
            ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _SocialIconWidget(asset: widget.iconAsset),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon resolver: tries PNG asset → falls back to Material icon
// ─────────────────────────────────────────────────────────────────────────────

class _SocialIconWidget extends StatelessWidget {
  final String asset;

  const _SocialIconWidget({required this.asset});

  static const double _size = 22;
  static const String _basePath = 'assets/icons/';

  @override
  Widget build(BuildContext context) {
    final String imagePath = asset == 'google' ? 'assets/google.png' : '$_basePath$asset.png';
    return SizedBox(
      width: _size,
      height: _size,
      child: Image.asset(
        imagePath,
        width: _size,
        height: _size,
        fit: BoxFit.contain,
        // If the PNG asset is missing, show a recognisable fallback icon
        errorBuilder: (context, error, stackTrace) {
          if (asset == 'google') return const _GoogleFallbackIcon();
          return const Icon(
            Icons.apple_rounded,
            size: _size,
            color: Color(0xFF1D1D1F),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback: hand-painted Google "G" using CustomPaint
// Only used when assets/icons/google.png is absent.
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleFallbackIcon extends StatelessWidget {
  const _GoogleFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final strokeW = w * 0.16;
    final radius = (w - strokeW) / 2;

    final rect = Rect.fromCircle(
        center: Offset(cx, cy), radius: radius);

    // ── 4 coloured arc segments (each ~90° but with 2° gaps) ───────────────
    const gap = 0.04; // radians ≈ 2°
    final pi = 3.14159265358979;
    final arcs = [
      // [startAngle, sweepAngle, color]
      [-pi / 2 + gap, pi / 2 - gap * 2, _blue],    // top → right (blue)
      [gap, pi / 2 - gap * 2, _green],               // right → bottom (green)
      [pi / 2 + gap, pi / 2 - gap * 2, _yellow],    // bottom → left (yellow)
      [pi + gap, pi / 2 - gap * 2, _red],            // left → top (red)
    ];

    for (final arc in arcs) {
      final paint = Paint()
        ..color = arc[2] as Color
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, arc[0] as double, arc[1] as double, false, paint);
    }

    // ── Horizontal blue bar (the flat part of the G) ───────────────────────
    final barTop = cy - strokeW * 0.55;
    final barBottom = cy + strokeW * 0.55;
    final barLeft = cx - strokeW * 0.1;   // starts just past center
    final barRight = cx + radius;          // reaches the right edge of circle

    // White background to erase arc behind bar
    canvas.drawRect(
      Rect.fromLTRB(barLeft - 2, barTop, barRight + 2, barBottom),
      Paint()..color = Colors.white,
    );

    // Solid blue rectangle for the bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(barLeft, barTop, barRight, barBottom),
        Radius.circular(strokeW * 0.3),
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
