
class EnergyWaterStatistics {
  final int totalReports;
  final int resolvedReports;
  final Map<String, int> byCategory;
  final Map<String, int> byStatus;
  final Map<String, int> monthlyTrend;
  final Map<String, int> areaWise;

  const EnergyWaterStatistics({
    required this.totalReports,
    required this.resolvedReports,
    required this.byCategory,
    required this.byStatus,
    required this.monthlyTrend,
    required this.areaWise,
  });

  factory EnergyWaterStatistics.fromJson(Map<String, dynamic> json) {
    Map<String, int> convertBreakdown(dynamic items) {
      final result = <String, int>{};

      if (items is List) {
        for (final item in items) {
          final row = item as Map<String, dynamic>;
          result[row['name'].toString()] =
              (row['count'] as num).toInt();
        }
      }

      return result;
    }

    Map<String, int> convertMonthly(dynamic items) {
      final result = <String, int>{};

      if (items is List) {
        for (final item in items) {
          final row = item as Map<String, dynamic>;
          result[row['month'].toString()] =
              (row['total_reports'] as num).toInt();
        }
      }

      return result;
    }

    Map<String, int> convertAreas(dynamic items) {
      final result = <String, int>{};

      if (items is List) {
        for (final item in items) {
          final row = item as Map<String, dynamic>;
          result[row['area'].toString()] =
              (row['total_reports'] as num).toInt();
        }
      }

      return result;
    }

    return EnergyWaterStatistics(
      totalReports: (json['total_reports'] as num?)?.toInt() ?? 0,
      resolvedReports: (json['resolved_reports'] as num?)?.toInt() ?? 0,
      byCategory: convertBreakdown(json['category_breakdown']),
      byStatus: convertBreakdown(json['status_breakdown']),
      monthlyTrend: convertMonthly(json['monthly_trends']),
      areaWise: convertAreas(json['area_wise']),
    );
  }
}
