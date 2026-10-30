import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

class StatisticsChart extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  final Color color;

  const StatisticsChart({
    super.key,
    required this.title,
    required this.data,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue =
        data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in data.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: maxValue == 0 ? 0 : entry.value / maxValue,
                          minHeight: 14,
                          color: color,
                          backgroundColor: AppColors.lightBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}