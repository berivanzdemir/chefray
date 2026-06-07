import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final String displayName;
  final String avatarInitial;

  const HomeHeader({
    super.key,
    required this.displayName,
    required this.avatarInitial,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      'Merhaba $displayName',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.15,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '👋',
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hedeflerine bir adım daha yaklaşıyorsun.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Notification
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none_rounded,
                    color: Theme.of(context).colorScheme.onSurface, size: 22),
                // Small notification dot
                Positioned(
                  top: 11,
                  right: 12,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Avatar
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Center(
              child: Text(
                avatarInitial,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
