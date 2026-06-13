import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Diyetini\nYükle',
                icon: Icons.cloud_upload_outlined,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => context.push('/diet-upload?uploadType=dietPdf'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                title: 'Kan\nTahlili',
                icon: Icons.water_drop_rounded,
                color: Colors.red.shade500,
                onTap: () => context.push('/diet-upload?uploadType=bloodPdf'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                title: 'Ürün\nTara',
                icon: Icons.qr_code_scanner_rounded,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => context.push('/product-scan'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                title: 'Tarif\nAra',
                icon: Icons.search_rounded,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => context.push('/recipe-list'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                title: 'Belgelerim',
                icon: Icons.folder_open_rounded,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => context.push('/documents'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.15,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
