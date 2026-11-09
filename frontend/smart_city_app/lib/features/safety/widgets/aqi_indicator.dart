import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/air_quality_model.dart';

const Color _orange = Color(0xFFF97316);
const Color _purple = Color(0xFF8B5CF6);
const Color _maroon = Color(0xFF9F1239);

/// Colour for an AQI value (standard US AQI bands).
Color aqiColor(int aqi) {
  if (aqi <= 50) return AppColors.success;
  if (aqi <= 100) return AppColors.warning;
  if (aqi <= 150) return _orange;
  if (aqi <= 200) return AppColors.error;
  if (aqi <= 300) return _purple;
  return _maroon;
}

class AqiLevel {
  final int min;
  final int max;
  final String label;
  final Color color;
  const AqiLevel(this.min, this.max, this.label, this.color);
}

const List<AqiLevel> aqiLevels = [
  AqiLevel(0, 50, 'Good', AppColors.success),
  AqiLevel(51, 100, 'Moderate', AppColors.warning),
  AqiLevel(101, 150, 'Unhealthy for Sensitive Groups', _orange),
  AqiLevel(151, 200, 'Unhealthy', AppColors.error),
  AqiLevel(201, 300, 'Very Unhealthy', _purple),
  AqiLevel(301, 500, 'Hazardous', _maroon),
];

/// Circular AQI gauge.
class AqiIndicator extends StatelessWidget {
  final int aqi;
  final String category;
  final double size;

  const AqiIndicator({
    super.key,
    required this.aqi,
    required this.category,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final color = aqiColor(aqi);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: (aqi / 300).clamp(0.0, 1.0),
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$aqi',
                  style: TextStyle(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  category,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: size * 0.07,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'AQI',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rows for the pollutant values that are available.
class PollutantList extends StatelessWidget {
  final AirQualityReading reading;
  const PollutantList({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, double? value, String unit})>[
      (label: 'PM2.5 (Fine Particles)', value: reading.pm25, unit: '\u00B5g/m\u00B3'),
      (label: 'PM10 (Coarse Dust)', value: reading.pm10, unit: '\u00B5g/m\u00B3'),
      (label: 'NO\u2082 (Nitrogen Dioxide)', value: reading.nitrogenDioxide, unit: '\u00B5g/m\u00B3'),
      (label: 'SO\u2082 (Sulphur Dioxide)', value: reading.sulphurDioxide, unit: '\u00B5g/m\u00B3'),
      (label: 'O\u2083 (Ground Ozone)', value: reading.ozone, unit: '\u00B5g/m\u00B3'),
      (label: 'CO (Carbon Monoxide)', value: reading.carbonMonoxide, unit: '\u00B5g/m\u00B3'),
      (label: 'UV Index', value: reading.uvIndex, unit: 'UV'),
    ].where((e) => e.value != null).toList();

    return Column(
      children: [
        for (final e in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.label, style: const TextStyle(color: AppColors.muted)),
                Text(
                  '${e.value!.toStringAsFixed(1)} ${e.unit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
