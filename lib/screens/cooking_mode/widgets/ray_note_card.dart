import 'package:flutter/material.dart';

class RayNoteCard extends StatelessWidget {
  final String tipText;

  const RayNoteCard({
    super.key,
    required this.tipText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EF), // Very light mint background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4E8DC), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/mascot/ray_tip.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.smart_toy_rounded,
              color: Color(0xFF2E7D32),
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Ray'den not",
                  style: TextStyle(
                    color: Color(0xFF2E7D32), // Green title matching reference
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tipText,
                  style: TextStyle(
                    color: Colors.black87.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.4,
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
