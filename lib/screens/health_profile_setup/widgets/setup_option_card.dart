import 'package:flutter/material.dart';

/// Single-select option card for the "Seni Tanıyalım" flow.
class SetupOptionCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const SetupOptionCard({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFFFF5) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFF2DFF88) : const Color(0xFFE8F3ED),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF2DFF88).withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2DFF88).withValues(alpha: 0.2)
                      : const Color(0xFFF6F8F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? const Color(0xFF008F4C) : const Color(0xFF8A9B9B),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF102B2B) : const Color(0xFF102B2B),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5F7373),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isSelected
                  ? Container(
                      key: const ValueKey('selected'),
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2DFF88),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 16, color: Color(0xFF102B2B)),
                    )
                  : const SizedBox(
                      key: ValueKey('empty'), width: 28, height: 28),
            ),
          ],
        ),
      ),
    );
  }
}
