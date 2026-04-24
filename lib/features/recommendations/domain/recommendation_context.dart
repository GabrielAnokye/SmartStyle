import 'package:smartstyle/features/recommendations/domain/weather_snapshot.dart';

enum Occasion { casual, work, formal, workout, outdoors }

class FeedbackSignal {
  final Set<String> itemIds;
  // 0..1, fresher rejections weigh more; the repository decays by age.
  final double weight;
  const FeedbackSignal({required this.itemIds, required this.weight});
}

class RecommendationContext {
  final WeatherSnapshot weather;
  final Occasion occasion;
  final DateTime when;
  // Item ids worn in the last 7 days — used to penalize repeats without
  // hard-filtering them (user may want to re-wear a clean favorite).
  final Set<String> recentlyWornItemIds;
  // Decay-weighted negative feedback from the last 14 days. Engine penalizes
  // outfits sharing ≥2 items with any signal here.
  final List<FeedbackSignal> negativeFeedback;

  const RecommendationContext({
    required this.weather,
    required this.occasion,
    required this.when,
    this.recentlyWornItemIds = const {},
    this.negativeFeedback = const [],
  });
}
