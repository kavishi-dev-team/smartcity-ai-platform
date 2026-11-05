import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/safety_provider.dart';
import '../utils/safety_formatters.dart';
import '../widgets/aqi_indicator.dart';
import '../widgets/safety_message_view.dart';
import 'air_quality_history_screen.dart';

class AirQualityDetailsScreen extends StatelessWidget {
  const AirQualityDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reading = context.watch<SafetyProvider>().selectedReading;

    return Scaffold(
      appBar: AppBar(title: Text(reading?.area ?? 'Air Quality Details')),
      body: reading == null
          ? const SafetyMessageView(
              icon: Icons.air,
              message: 'No air quality data available.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: AqiIndicator(
                    aqi: reading.aqi,
                    category: reading.category,
                    size: 170,
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Health recommendations',
                  icon: Icons.favorite_outline,
                  child: Text(
                    reading.healthRecommendation,
                    style: const TextStyle(color: AppColors.text, height: 1.4),
                  ),
                ),
                _SectionCard(
                  title: 'Pollutants',
                  icon: Icons.science_outlined,
                  child: PollutantList(reading: reading),
                ),
                _SectionCard(
                  title: 'What does AQI mean?',
                  icon: Icons.help_outline,
                  child: Column(
                    children: [
                      for (final level in aqiLevels)
                        _LevelRow(
                          level: level,
                          isCurrent: reading.aqi >= level.min &&
                              reading.aqi <= level.max,
                        ),
                    ],
                  ),
                ),
                _SectionCard(
                  title: 'Data information',
                  icon: Icons.schedule,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last updated: ${formatDateTime(reading.recordedAt)}'),
                      if (reading.source != null) ...[
                        const SizedBox(height: 4),
                        Text('Source: ${reading.source}'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final provider = context.read<SafetyProvider>();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: const AirQualityHistoryScreen(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.show_chart),
                  label: const Text('View historical trends'),
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final AqiLevel level;
  final bool isCurrent;
  const _LevelRow({required this.level, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final rangeText =
        level.max >= 301 ? '${level.min}+' : '${level.min}-${level.max}';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent ? level.color.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(10),
        border: isCurrent ? Border.all(color: level.color) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: level.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              level.label,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
          Text(rangeText, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
