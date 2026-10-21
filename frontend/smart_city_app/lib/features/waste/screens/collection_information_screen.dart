import 'package:smart_city_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CollectionInformationScreen extends StatefulWidget {
  const CollectionInformationScreen({super.key});

  @override
  State<CollectionInformationScreen> createState() =>
      _CollectionInformationScreenState();
}

class _CollectionInformationScreenState
    extends State<CollectionInformationScreen> {
  String _selectedArea = 'Colombo 07';

  static const _blue = AppColors.primary;
  static const _navy = AppColors.text;
  static const _muted = AppColors.muted;

  static const List<Map<String, String>> _schedules = [
    {
      'area': 'Colombo 07',
      'type': 'General waste',
      'day': 'Monday & Thursday',
      'time': '7:00 AM – 10:00 AM',
    },
    {
      'area': 'Colombo 07',
      'type': 'Recyclable waste',
      'day': 'Saturday',
      'time': '8:00 AM – 11:00 AM',
    },
    {
      'area': 'Nugegoda',
      'type': 'General waste',
      'day': 'Tuesday & Friday',
      'time': '7:00 AM – 10:00 AM',
    },
    {
      'area': 'Nugegoda',
      'type': 'Recyclable waste',
      'day': 'Sunday',
      'time': '8:00 AM – 11:00 AM',
    },
    {
      'area': 'Homagama',
      'type': 'General waste',
      'day': 'Monday & Friday',
      'time': '6:30 AM – 9:30 AM',
    },
    {
      'area': 'Homagama',
      'type': 'Recyclable waste',
      'day': 'Wednesday',
      'time': '8:00 AM – 11:00 AM',
    },
    {
      'area': 'Maharagama',
      'type': 'General waste',
      'day': 'Wednesday & Saturday',
      'time': '7:00 AM – 10:00 AM',
    },
    {
      'area': 'Maharagama',
      'type': 'Recyclable waste',
      'day': 'Thursday',
      'time': '8:00 AM – 11:00 AM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final schedules = _schedules
        .where((schedule) => schedule['area'] == _selectedArea)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Collection information'),
        backgroundColor: AppColors.card,
        foregroundColor: _navy,
        surfaceTintColor: Colors.transparent,
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
                    color: _navy,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose an area to view its collection schedule.',
                  style: TextStyle(color: _muted, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5DB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Demo schedules only. These are fictional times '
                    'for testing, not official collection schedules.',
                    style: TextStyle(color: Color(0xFF854D0E), height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _selectedArea,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Select area',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Colombo 07',
                      child: Text('Colombo 07'),
                    ),
                    DropdownMenuItem(
                      value: 'Nugegoda',
                      child: Text('Nugegoda'),
                    ),
                    DropdownMenuItem(
                      value: 'Homagama',
                      child: Text('Homagama'),
                    ),
                    DropdownMenuItem(
                      value: 'Maharagama',
                      child: Text('Maharagama'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedArea = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Schedules for $_selectedArea',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                ...schedules.map(_scheduleCard),
                const SizedBox(height: 12),
                const Text(
                  'Collection preparation',
                  style: TextStyle(
                    color: _navy,
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
                    style: TextStyle(color: _muted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scheduleCard(Map<String, String> schedule) {
    final isRecycling = schedule['type'] == 'Recyclable waste';

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
              Icon(
                isRecycling ? Icons.recycling : Icons.delete_outline,
                color: _blue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  schedule['type']!,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            schedule['day']!,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(schedule['time']!, style: const TextStyle(color: _muted)),
        ],
      ),
    );
  }
}
