class WeatherSnapshot {
  final double tempC;
  final double feelsLikeC;
  final double precipProb; // 0..1
  final double windKph;
  final DateTime fetchedAt;

  const WeatherSnapshot({
    required this.tempC,
    required this.feelsLikeC,
    required this.precipProb,
    required this.windKph,
    required this.fetchedAt,
  });

  Map<String, dynamic> toJson() => {
        'temp_c': tempC,
        'feels_like_c': feelsLikeC,
        'precip_prob': precipProb,
        'wind_kph': windKph,
        'fetched_at': fetchedAt.toIso8601String(),
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> j) => WeatherSnapshot(
        tempC: (j['temp_c'] as num).toDouble(),
        feelsLikeC: (j['feels_like_c'] as num).toDouble(),
        precipProb: (j['precip_prob'] as num).toDouble(),
        windKph: (j['wind_kph'] as num).toDouble(),
        fetchedAt: DateTime.parse(j['fetched_at'] as String),
      );
}
