class AirQualityReading {
  final int id;
  final String area;
  final int aqi;
  final String category;
  final String healthRecommendation;
  final double? pm25;
  final double? pm10;
  final double? carbonMonoxide;
  final double? nitrogenDioxide;
  final double? ozone;
  final String? source;
  final DateTime recordedAt;

  const AirQualityReading({
    required this.id,
    required this.area,
    required this.aqi,
    required this.category,
    required this.healthRecommendation,
    this.pm25,
    this.pm10,
    this.carbonMonoxide,
    this.nitrogenDioxide,
    this.ozone,
    this.source,
    required this.recordedAt,
  });

  factory AirQualityReading.fromJson(Map<String, dynamic> json) {
    return AirQualityReading(
      id: (json['id'] as num).toInt(),
      area: json['area'] as String,
      aqi: (json['aqi'] as num).toInt(),
      category: json['category'] as String,
      healthRecommendation: json['health_recommendation'] as String,
      pm25: (json['pm2_5'] as num?)?.toDouble(),
      pm10: (json['pm10'] as num?)?.toDouble(),
      carbonMonoxide: (json['carbon_monoxide'] as num?)?.toDouble(),
      nitrogenDioxide: (json['nitrogen_dioxide'] as num?)?.toDouble(),
      ozone: (json['ozone'] as num?)?.toDouble(),
      source: json['source'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}

class AirQualityHistoryPoint {
  final DateTime timestamp;
  final int aqi;
  final double? pm25;
  final double? pm10;

  const AirQualityHistoryPoint({
    required this.timestamp,
    required this.aqi,
    this.pm25,
    this.pm10,
  });

  factory AirQualityHistoryPoint.fromJson(Map<String, dynamic> json) {
    return AirQualityHistoryPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      aqi: (json['aqi'] as num).toInt(),
      pm25: (json['pm2_5'] as num?)?.toDouble(),
      pm10: (json['pm10'] as num?)?.toDouble(),
    );
  }
}

class AirQualityHistory {
  final String area;
  final String period;
  final int averageAqi;
  final int minAqi;
  final int maxAqi;
  final List<AirQualityHistoryPoint> points;

  const AirQualityHistory({
    required this.area,
    required this.period,
    required this.averageAqi,
    required this.minAqi,
    required this.maxAqi,
    required this.points,
  });

  factory AirQualityHistory.fromJson(Map<String, dynamic> json) {
    return AirQualityHistory(
      area: json['area'] as String,
      period: json['period'] as String,
      averageAqi: (json['average_aqi'] as num).toInt(),
      minAqi: (json['min_aqi'] as num).toInt(),
      maxAqi: (json['max_aqi'] as num).toInt(),
      points: (json['points'] as List<dynamic>)
          .map((e) => AirQualityHistoryPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
