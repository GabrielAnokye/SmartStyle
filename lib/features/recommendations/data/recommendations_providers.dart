import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstyle/features/recommendations/data/geolocation_service.dart';
import 'package:smartstyle/features/recommendations/data/open_meteo_client.dart';
import 'package:smartstyle/features/recommendations/domain/outfit.dart';
import 'package:smartstyle/features/recommendations/domain/recommendation_context.dart';
import 'package:smartstyle/features/recommendations/domain/scoring_engine.dart';
import 'package:smartstyle/features/recommendations/domain/weather_snapshot.dart';
import 'package:smartstyle/features/wardrobe/data/wardrobe_repository.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';

class OccasionNotifier extends Notifier<Occasion> {
  @override
  Occasion build() => Occasion.casual;
  void set(Occasion v) => state = v;
}

final occasionProvider = NotifierProvider<OccasionNotifier, Occasion>(OccasionNotifier.new);

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
  final occasion = ref.watch(occasionProvider);

  final fix = await geo.currentFix();
  final weather = await wx.fetch(lat: fix.lat, lon: fix.lon);

  // Pull a wide slice of the closet for scoring. Pagination doesn't help here
  // since the engine needs the full candidate pool.
  final items = await repo.getItems(limit: 500, offset: 0);

  final recent = _recentlyWorn(items);
  final context = RecommendationContext(
    weather: weather,
    occasion: occasion,
    when: DateTime.now(),
    recentlyWornItemIds: recent,
  );

  const engine = ScoringEngine();
  final outfits = engine.recommend(items: items, context: context);
  return DashboardData(weather: weather, location: fix, outfits: outfits);
});

Set<String> _recentlyWorn(List<ItemModel> items) {
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  return items
      .where((i) => i.lastWornAt != null && i.lastWornAt!.isAfter(cutoff))
      .map((i) => i.itemId)
      .toSet();
}
