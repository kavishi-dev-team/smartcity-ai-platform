class EnergyWaterStatistics {
  final int totalReports;
  final int resolvedReports;
  final Map<String, int> byCategory;
  final Map<String, int> byStatus;
  final Map<String, int> monthlyTrend;

  const EnergyWaterStatistics({
    required this.totalReports,
    required this.resolvedReports,
    required this.byCategory,
    required this.byStatus,
    required this.monthlyTrend,
  });

  factory EnergyWaterStatistics.fromJson(Map<String, dynamic> json) {
    Map<String, int> toMap(dynamic v) => (v as Map<String, dynamic>? ?? {})
        .map((k, val) => MapEntry(k, (val as num).toInt()));

    return EnergyWaterStatistics(
      totalReports: (json['total_reports'] as num?)?.toInt() ?? 0,
      resolvedReports: (json['resolved_reports'] as num?)?.toInt() ?? 0,
      byCategory: toMap(json['by_category']),
      byStatus: toMap(json['by_status']),
      monthlyTrend: toMap(json['monthly_trend']),
    );
  }
}