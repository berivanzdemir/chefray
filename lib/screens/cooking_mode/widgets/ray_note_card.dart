import 'package:flutter/material.dart';

class RayNoteCard extends StatelessWidget {
  final String tipText;

  const RayNoteCard({super.key, required this.tipText});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E3A31)
            : const Color(0xFFF1F8F4), // Very light mint / dark green
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2B4A40) : const Color(0xFFE2EFE7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Image.asset('assets/mascot/ray_tip.png', width: 60, height: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ray'den not",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark
                        ? const Color(0xFFDFFFEF)
                        : const Color(0xFF0D9B5E), // Green title
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tipText,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFFC7D8D2)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
