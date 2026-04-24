import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstyle/features/recommendations/data/calendar_service.dart';
import 'package:smartstyle/features/recommendations/data/feedback_repository.dart';
import 'package:smartstyle/features/recommendations/data/geolocation_service.dart';
import 'package:smartstyle/features/recommendations/data/open_meteo_client.dart';
import 'package:smartstyle/features/recommendations/domain/outfit.dart';
import 'package:smartstyle/features/recommendations/domain/recommendation_context.dart';
import 'package:smartstyle/features/recommendations/domain/scoring_engine.dart';
import 'package:smartstyle/features/recommendations/domain/weather_snapshot.dart';
import 'package:smartstyle/features/wardrobe/data/wardrobe_repository.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';

/// Null = no explicit user pick; dashboard falls back to calendar suggestion
/// or Occasion.casual. Setting a value sticks until the user clears it.
class OccasionNotifier extends Notifier<Occasion?> {
  @override
  Occasion? build() => null;
  void set(Occasion v) => state = v;
  void clear() => state = null;
}

final occasionProvider = NotifierProvider<OccasionNotifier, Occasion?>(OccasionNotifier.new);

/// Calendar-derived suggestion for today. Null if permission denied, no events,
/// or no keyword match. Cheap to recompute; providers above depend on it.
final inferredOccasionProvider = FutureProvider<Occasion?>((ref) async {
  final cal = ref.watch(calendarServiceProvider);
  return cal.inferOccasion(DateTime.now());
});

class DashboardData {
  final WeatherSnapshot weather;
  final LocationFix location;
  final List<Outfit> outfits;
  const DashboardData({required this.weather, required this.location, required this.outfits});
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final geo = ref.watch(geolocationServiceProvider);
  final wx = ref.watch(openMeteoClientProvider);
  final repo = ref.watch(wardrobeRepositoryProvider);
  final feedback = ref.watch(feedbackRepositoryProvider);
  final userOccasion = ref.watch(occasionProvider);
  final inferred = await ref.watch(inferredOccasionProvider.future);
  final occasion = userOccasion ?? inferred ?? Occasion.casual;

  final fix = await geo.currentFix();
  final weather = await wx.fetch(lat: fix.lat, lon: fix.lon);

  // Pull a wide slice of the closet for scoring. Pagination doesn't help here
  // since the engine needs the full candidate pool.
  final items = await repo.getItems(limit: 500, offset: 0);
  final feedbackRows = await feedback.recentNegative();

  final recent = _recentlyWorn(items);
  final now = DateTime.now();
  final signals = feedbackRows
      .map((r) => FeedbackSignal(
            itemIds: r.itemIds,
            weight: _decayWeight(now.difference(r.createdAt)),
          ))
      .where((s) => s.weight > 0.05)
      .toList();

  final context = RecommendationContext(
    weather: weather,
    occasion: occasion,
    when: now,
    recentlyWornItemIds: recent,
    negativeFeedback: signals,
  );

  const engine = ScoringEngine();
  final outfits = engine.recommend(items: items, context: context);
  return DashboardData(weather: weather, location: fix, outfits: outfits);
});

/// Half-life ≈ 7 days. Fresh thumbs-down ≈ 1.0, 7-day-old ≈ 0.5, 14-day ≈ 0.25.
double _decayWeight(Duration age) {
  final days = age.inHours / 24.0;
  if (days < 0) return 1.0;
  return 1.0 / (1.0 + (days / 7.0));
}

Set<String> _recentlyWorn(List<ItemModel> items) {
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  return items
      .where((i) => i.lastWornAt != null && i.lastWornAt!.isAfter(cutoff))
      .map((i) => i.itemId)
      .toSet();
}
