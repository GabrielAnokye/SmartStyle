import 'package:smartstyle/features/recommendations/domain/weather_snapshot.dart';

enum Occasion { casual, work, formal, workout, outdoors }

class RecommendationContext {
  final WeatherSnapshot weather;
  final Occasion occasion;
  final DateTime when;
  // Item ids worn in the last 7 days — used to penalize repeats without
  // hard-filtering them (user may want to re-wear a clean favorite).
  final Set<String> recentlyWornItemIds;

  const RecommendationContext({
    required this.weather,
    required this.occasion,
    required this.when,
    this.recentlyWornItemIds = const {},
  });
}
