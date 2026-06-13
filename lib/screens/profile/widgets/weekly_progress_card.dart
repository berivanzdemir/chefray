import 'package:flutter/material.dart';

class WeeklyProgressCard extends StatelessWidget {
  final List<int> activeWeekdays;

  const WeeklyProgressCard({super.key, required this.activeWeekdays});

  @override
  Widget build(BuildContext context) {
    final int activeDaysCount = activeWeekdays.length;
    final double percent = (activeDaysCount / 7.0).clamp(0.0, 1.0);
    final int percentInt = (percent * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Haftalık İlerleme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$activeDaysCount aktif gün',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDayIndicator(
                          context,
                          'Pzt',
                          activeWeekdays.contains(1),
                        ),
                        _buildDayIndicator(
                          context,
                          'Sal',
                          activeWeekdays.contains(2),
                        ),
                        _buildDayIndicator(
                          context,
                          'Çar',
                          activeWeekdays.contains(3),
                        ),
                        _buildDayIndicator(
                          context,
                          'Per',
                          activeWeekdays.contains(4),
                        ),
                        _buildDayIndicator(
                          context,
                          'Cum',
                          activeWeekdays.contains(5),
                        ),
                        _buildDayIndicator(
                          context,
                          'Cmt',
                          activeWeekdays.contains(6),
                        ),
                        _buildDayIndicator(
                          context,
                          'Paz',
                          activeWeekdays.contains(7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '%$percentInt',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'tamamlandı',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: const Color(0xFFF0F0F0),
              color: Theme.of(context).colorScheme.primary,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayIndicator(BuildContext context, String day, bool isActive) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: isActive
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.surface,
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive
                ? Theme.of(context).colorScheme.onSurface
                : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
