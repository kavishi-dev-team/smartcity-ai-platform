import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../services/collection_services.dart';

class CollectionInformationScreen extends StatefulWidget {
  const CollectionInformationScreen({super.key});

  @override
  State<CollectionInformationScreen> createState() =>
      _CollectionInformationScreenState();
}

class _CollectionInformationScreenState
    extends State<CollectionInformationScreen> {
  final _service = CollectionService();

  List<Map<String, dynamic>> _schedules = [];
  String? _selectedArea;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  List<String> get _areas {
    final areas =
        _schedules
            .map((schedule) => schedule['area'].toString())
            .toSet()
            .toList()
          ..sort();

    return areas;
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final schedules = await _service.getSchedules();

      if (!mounted) return;

      setState(() {
        _schedules = schedules;

        final areas = _areas;
        if (!areas.contains(_selectedArea)) {
          _selectedArea = areas.isEmpty ? null : areas.first;
        }

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Could not load collection schedules. '
            'Check that the backend is running and try again.';
      });
    }
  }

  String _text(Map<String, dynamic> schedule, String field, String fallback) {
    final value = schedule[field]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    final schedules = _schedules
        .where((schedule) => schedule['area'] == _selectedArea)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Collection information',
          style: TextStyle(color: AppColors.text),
        ),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh schedules',
            onPressed: _loading ? null : _loadSchedules,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collection schedules',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose an area to view its collection schedule.',
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5DB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Test schedules are not official collection times. '
                    'Confirm collection arrangements with your local authority.',
                    style: TextStyle(color: Color(0xFF854D0E), height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadSchedules,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ] else if (_schedules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No collection schedules available yet.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedArea),
                    initialValue: _selectedArea,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select area',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: _areas.map((area) {
                      return DropdownMenuItem(value: area, child: Text(area));
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedArea = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Schedules for $_selectedArea',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...schedules.map(_scheduleCard),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Collection preparation',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '• Keep general and recyclable waste separate.\n\n'
                    '• Close waste bags securely.\n\n'
                    '• Keep the collection point accessible.\n\n'
                    '• Follow your local authority’s instructions.',
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scheduleCard(Map<String, dynamic> schedule) {
    final instructions = _text(schedule, 'instructions', '');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.delete_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _text(schedule, 'waste_types', 'Waste collection'),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _text(schedule, 'collection_day', 'Day not specified'),
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _text(schedule, 'collection_time', 'Time not specified'),
            style: const TextStyle(color: AppColors.muted),
          ),
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              instructions,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
