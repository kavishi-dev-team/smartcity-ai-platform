import '../models/energy_issue_model.dart';
import '../models/water_issue_model.dart';
import '../models/energy_water_statistics_model.dart';

class EnergyWaterService {
 
  Future<List<EnergyIssue>> fetchEnergyIssues({
    String? search,
    String? status,
    String? priority,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();
    final all = <EnergyIssue>[
      EnergyIssue(
        id: 1,
        title: 'Streetlight not working',
        description:
            'Streetlight near the main junction is off since last night.',
        category: 'energy',
        status: 'reported',
        priority: 'medium',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
        latitude: 7.2083,
        longitude: 79.8358,
        address: 'Main Street',
        city: 'Negombo',
      ),
      EnergyIssue(
        id: 2,
        title: 'Power outage in residential area',
        description: 'No electricity for the past 3 hours.',
        category: 'energy',
        status: 'in_progress',
        priority: 'high',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now,
        city: 'Negombo',
      ),
      EnergyIssue(
        id: 3,
        title: 'Damaged electric pole',
        description: 'Pole leaning dangerously after the storm.',
        category: 'energy',
        status: 'resolved',
        priority: 'high',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now,
        city: 'Colombo',
      ),
    ];

    return all.where((i) {
      final matchSearch = search == null ||
          search.isEmpty ||
          i.title.toLowerCase().contains(search.toLowerCase());
      final matchStatus = status == null || i.status == status;
      final matchPriority = priority == null || i.priority == priority;
      return matchSearch && matchStatus && matchPriority;
    }).toList();
  }

  
  Future<List<WaterIssue>> fetchWaterIssues({
    String? search,
    String? status,
    String? priority,
    bool leakageOnly = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();
    final all = <WaterIssue>[
      WaterIssue(
        id: 11,
        title: 'Burst water pipe',
        description: 'Water is gushing onto the road near the bus stand.',
        category: 'water',
        status: 'reported',
        priority: 'high',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now,
        latitude: 7.2094,
        longitude: 79.8386,
        address: 'Bus Stand Road',
        city: 'Negombo',
        isLeakage: true,
      ),
      WaterIssue(
        id: 12,
        title: 'No water supply',
        description: 'No water in the area since morning.',
        category: 'water',
        status: 'in_progress',
        priority: 'medium',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
        city: 'Colombo',
      ),
      WaterIssue(
        id: 13,
        title: 'Slow leak near school',
        description: 'Small continuous leak from a pipe joint.',
        category: 'water',
        status: 'resolved',
        priority: 'low',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
        latitude: 7.2051,
        longitude: 79.8420,
        address: 'School Lane',
        city: 'Negombo',
        isLeakage: true,
      ),
    ];

    return all.where((i) {
      final matchSearch = search == null ||
          search.isEmpty ||
          i.title.toLowerCase().contains(search.toLowerCase());
      final matchStatus = status == null || i.status == status;
      final matchPriority = priority == null || i.priority == priority;
      final matchLeak = !leakageOnly || i.isLeakage;
      return matchSearch && matchStatus && matchPriority && matchLeak;
    }).toList();
  }

    
  Future<EnergyWaterStatistics> fetchStatistics(String category) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (category == 'water') {
      return const EnergyWaterStatistics(
        totalReports: 42,
        resolvedReports: 25,
        byCategory: {'leakage': 18, 'supply': 14, 'quality': 10},
        byStatus: {'reported': 8, 'in progress': 9, 'resolved': 25},
        monthlyTrend: {'Jul': 6, 'Aug': 9, 'Sep': 12, 'Oct': 15},
      );
    }
    return const EnergyWaterStatistics(
      totalReports: 35,
      resolvedReports: 20,
      byCategory: {'streetlight': 15, 'outage': 12, 'pole': 8},
      byStatus: {'reported': 7, 'in progress': 8, 'resolved': 20},
      monthlyTrend: {'Jul': 5, 'Aug': 8, 'Sep': 10, 'Oct': 12},
    );
  }
}