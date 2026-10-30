import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../models/water_issue_model.dart';
import '../services/energy_water_service.dart';

class WaterLeakageMapScreen extends StatefulWidget {
  const WaterLeakageMapScreen({super.key});

  @override
  State<WaterLeakageMapScreen> createState() => _WaterLeakageMapScreenState();
}

class _WaterLeakageMapScreenState extends State<WaterLeakageMapScreen> {
  final EnergyWaterService _service = EnergyWaterService();

  List<WaterIssue> _issues = [];
  WaterIssue? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _service.fetchWaterIssues(leakageOnly: true);
      _issues = all
          .where((i) => i.latitude != null && i.longitude != null)
          .toList();
    } catch (e) {
      _error = 'Failed to load leakage locations';
    }
    if (mounted) setState(() => _loading = false);
  }

  Color _color(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Water Leakage Map')),
      body: Builder(builder: (context) {
        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
          return Center(
            child: Text(_error!,
                style: const TextStyle(color: AppColors.error)),
          );
        }
        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(7.2083, 79.8358),
                initialZoom: 14,
                onTap: (_, __) => setState(() => _selected = null),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.smart_city_app',
                ),
                MarkerLayer(
                  markers: [
                    for (final i in _issues)
                      Marker(
                        point: LatLng(i.latitude!, i.longitude!),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => setState(() => _selected = i),
                          child: Icon(
                            Icons.location_on,
                            size: 44,
                            color: _color(i.priority),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (_selected != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selected!.title,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selected!.description,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_selected!.status.replaceAll('_', ' ')} • '
                          '${_selected!.priority} severity • '
                          '${_selected!.address ?? _selected!.city ?? ''}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}