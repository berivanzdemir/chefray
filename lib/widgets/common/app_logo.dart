import 'package:flutter/material.dart';


/// ChefRay Logo Widget — minimal, Apple-level clean.
/// 72×72 rounded container, single soft shadow, no glow.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 72,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Icon container ─────────────────────────────────────────────────
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(size * 0.24),
            border: Border.all(color: Theme.of(context).dividerColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          padding: EdgeInsets.all(size * 0.13),
          child: Image.asset(
            'assets/branding/chefray_logo.png',
            fit: BoxFit.contain,
          ),
        ),

        // ── Wordmark ───────────────────────────────────────────────────────
        if (showText) ...[
          SizedBox(height: size * 0.18),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Chef',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: size * 0.27,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: 'Ray',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: size * 0.27,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
