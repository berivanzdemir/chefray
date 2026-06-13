import 'package:flutter/material.dart';

class BasicInfoGoalCard extends StatelessWidget {
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String goal;
  final String activity;

  const BasicInfoGoalCard({
    super.key,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.goal,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Temel Bilgiler',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(context, Icons.calendar_today_rounded, 'Yaş', '$age'),
          _buildDivider(),
          _buildInfoRow(context, Icons.wc_rounded, 'Cinsiyet', gender),
          _buildDivider(),
          _buildInfoRow(
            context,
            Icons.height_rounded,
            'Boy',
            '${height.toInt()} cm',
          ),
          _buildDivider(),
          _buildInfoRow(
            context,
            Icons.monitor_weight_rounded,
            'Kilo',
            '${weight.toInt()} kg',
          ),
          _buildDivider(),
          _buildInfoRow(
            context,
            Icons.directions_run_rounded,
            'Aktivite',
            activity,
          ),
          _buildDivider(),
          _buildInfoRow(context, Icons.flag_rounded, 'Hedef', goal),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[100]);
  }
}
