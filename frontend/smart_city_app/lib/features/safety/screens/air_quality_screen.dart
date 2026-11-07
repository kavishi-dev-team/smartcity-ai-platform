import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/safety_provider.dart';
import '../utils/safety_formatters.dart';
import '../widgets/aqi_indicator.dart';
import '../widgets/safety_message_view.dart';
import 'air_quality_details_screen.dart';
import 'air_quality_history_screen.dart';

/// Entry point for the Air Quality feature.
/// Creates the provider, so it can be opened from anywhere:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const AirQualityScreen()));
class AirQualityScreen extends StatelessWidget {
  const AirQualityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SafetyProvider()..loadAirQuality(),
      child: const _AirQualityView(),
    );
  }
}

/// Opens another screen while sharing the same provider.
void _open(BuildContext context, Widget screen) {
  final provider = context.read<SafetyProvider>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(value: provider, child: screen),
    ),
  );
}

class _AirQualityView extends StatelessWidget {
  const _AirQualityView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SafetyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Quality'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => p.loadAirQuality(),
          ),
        ],
      ),
      body: _buildBody(context, p),
    );
  }

  Widget _buildBody(BuildContext context, SafetyProvider p) {
    if (p.isLoadingAir && p.readings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.airError != null && p.readings.isEmpty) {
      return SafetyMessageView(
        icon: Icons.cloud_off,
        message: p.airError!,
        actionLabel: 'Try again',
        onAction: () => p.loadAirQuality(),
      );
    }
    final current = p.selectedReading;
    if (current == null) {
      return SafetyMessageView(
        icon: Icons.air,
        message: 'No air quality data available yet.',
        actionLabel: 'Refresh',
        onAction: () => p.loadAirQuality(),
      );
    }

    return RefreshIndicator(
      onRefresh: p.loadAirQuality,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(current.area),
            initialValue: current.area,
            decoration: const InputDecoration(
              labelText: 'Area',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: [
              for (final r in p.readings)
                DropdownMenuItem(value: r.area, child: Text(r.area)),
            ],
            onChanged: (value) {
              if (value != null) p.selectArea(value);
            },
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AqiIndicator(aqi: current.aqi, category: current.category),
                  const SizedBox(height: 16),
                  Text(
                    'Last updated: ${formatDateTime(current.recordedAt)}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pollutants',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PollutantList(reading: current),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _open(context, const AirQualityDetailsScreen()),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _open(context, const AirQualityHistoryScreen()),
                  icon: const Icon(Icons.show_chart),
                  label: const Text('History'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'All areas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          for (final r in p.readings)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                onTap: () => p.selectArea(r.area),
                leading: CircleAvatar(
                  backgroundColor: aqiColor(r.aqi),
                  child: Text(
                    '${r.aqi}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                title: Text(r.area),
                subtitle: Text(r.category),
                trailing: r.area == current.area
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : const Icon(Icons.chevron_right),
              ),
            ),
        ],
      ),
    );
  }
}