import 'package:smartstyle/features/recommendations/domain/composition_rules.dart';
import 'package:smartstyle/features/recommendations/domain/outfit.dart';
import 'package:smartstyle/features/recommendations/domain/recommendation_context.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';

class ScoringWeights {
  final double weatherFit;
  final double occasionFit;
  final double freshness;
  final double recentlyWornPenalty;

  const ScoringWeights({
    this.weatherFit = 0.45,
    this.occasionFit = 0.30,
    this.freshness = 0.25,
    this.recentlyWornPenalty = 0.20,
  });
}

class ScoringEngine {
  final ScoringWeights weights;
  const ScoringEngine({this.weights = const ScoringWeights()});

  /// Returns at most [topN] outfits ranked by score. Dirty/laundry items are
  /// filtered before scoring — see [_cleanItems].
  List<Outfit> recommend({
    required List<ItemModel> items,
    required RecommendationContext context,
    int topN = 3,
  }) {
    final clean = _cleanItems(items);
    final tops = <ItemModel>[];
    final bottoms = <ItemModel>[];
    final dresses = <ItemModel>[];
    final outerwear = <ItemModel>[];
    final shoes = <ItemModel>[];
    for (final i in clean) {
      switch (slotFor(i)) {
        case Slot.top:
          tops.add(i);
        case Slot.bottom:
          bottoms.add(i);
        case Slot.dress:
          dresses.add(i);
        case Slot.outerwear:
          outerwear.add(i);
        case Slot.shoes:
          shoes.add(i);
        case null:
          break;
      }
    }

    final requireOuterwear = needsOuterwear(
      feelsLikeC: context.weather.feelsLikeC,
      precipProb: context.weather.precipProb,
    );

    final candidates = <Outfit>[];
    // Top+Bottom combinations.
    for (final t in tops) {
      for (final b in bottoms) {
        candidates.add(_scoreOutfit(
          top: t,
          bottom: b,
          outerwear: requireOuterwear ? _bestOuterwear(outerwear, context) : null,
          shoes: _bestShoes(shoes, context),
          context: context,
          requireOuterwear: requireOuterwear,
        ));
      }
    }
    // Dresses substitute top+bottom. Treat the dress as both slots.
    for (final d in dresses) {
      candidates.add(_scoreOutfit(
        top: d,
        bottom: d,
        outerwear: requireOuterwear ? _bestOuterwear(outerwear, context) : null,
        shoes: _bestShoes(shoes, context),
        context: context,
        requireOuterwear: requireOuterwear,
      ));
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    // De-duplicate by item-id set so the top-N aren't near-identical.
    final seen = <String>{};
    final picks = <Outfit>[];
    for (final o in candidates) {
      final key = (o.itemIds.toList()..sort()).join('|');
      if (seen.add(key)) picks.add(o);
      if (picks.length >= topN) break;
    }
    return picks;
  }

  List<ItemModel> _cleanItems(List<ItemModel> items) =>
      items.where((i) => i.state == ItemState.clean || i.state == ItemState.worn).toList();

  ItemModel? _bestOuterwear(List<ItemModel> pool, RecommendationContext ctx) {
    if (pool.isEmpty) return null;
    pool.sort((a, b) => b.warmthClo.compareTo(a.warmthClo));
    // Colder → warmer outerwear. Above 15°C we wouldn't be here.
    return pool.first;
  }

  ItemModel? _bestShoes(List<ItemModel> pool, RecommendationContext ctx) {
    if (pool.isEmpty) return null;
    return pool.first;
  }

  Outfit _scoreOutfit({
    required ItemModel top,
    required ItemModel bottom,
    required ItemModel? outerwear,
    required ItemModel? shoes,
    required RecommendationContext context,
    required bool requireOuterwear,
  }) {
    final parts = <ItemModel>[
      top,
      // Avoid double-counting a dress that fills both top and bottom slots
      // (would double its warmth_clo and skew every score component).
      if (bottom.itemId != top.itemId) bottom,
      ?outerwear,
      ?shoes,
    ];
    final weather = _weatherFit(parts, context);
    final occasion = _occasionFit(parts, context);
    final freshness = _freshness(parts);
    final recent = _recentPenalty(parts, context);

    final raw = weights.weatherFit * weather +
        weights.occasionFit * occasion +
        weights.freshness * freshness -
        weights.recentlyWornPenalty * recent;

    // Penalize missing outerwear when it's required — don't hide the outfit,
    // just mark it clearly suboptimal so the top-3 prefers fuller outfits.
    final missingOuter = requireOuterwear && outerwear == null ? 0.3 : 0.0;
    final score = (raw - missingOuter).clamp(-1.0, 1.0);

    return Outfit(
      top: top,
      bottom: bottom,
      outerwear: outerwear,
      shoes: shoes,
      score: score,
      scoreBreakdown: {
        'weather': weather,
        'occasion': occasion,
        'freshness': freshness,
        'recent_penalty': recent,
        'missing_outer': missingOuter,
      },
    );
  }

  /// How well the outfit's summed warmth matches the felt temperature.
  /// 0.0 (terrible) .. 1.0 (ideal).
  double _weatherFit(List<ItemModel> parts, RecommendationContext ctx) {
    final totalClo = parts.fold<double>(0, (s, i) => s + i.warmthClo);
    // Rough target clo by feels-like temp. These constants are tunable.
    final target = _targetClo(ctx.weather.feelsLikeC);
    final delta = (totalClo - target).abs();
    // 0.5 clo off = 0.5 score; 1.5+ clo off = 0.0.
    return (1.0 - (delta / 1.5)).clamp(0.0, 1.0);
  }

  double _targetClo(double feelsLikeC) {
    if (feelsLikeC >= 25) return 0.4;
    if (feelsLikeC >= 18) return 0.8;
    if (feelsLikeC >= 10) return 1.4;
    if (feelsLikeC >= 0) return 2.2;
    return 3.0;
  }

  double _occasionFit(List<ItemModel> parts, RecommendationContext ctx) {
    final name = ctx.occasion.name;
    int matched = 0;
    int tagged = 0;
    for (final i in parts) {
      if (i.occasions.isEmpty) continue;
      tagged++;
      if (i.occasions.map((e) => e.toLowerCase()).contains(name)) matched++;
    }
    if (tagged == 0) return 0.6; // neutral when no data
    return matched / tagged;
  }

  /// Prefer items that haven't been worn many times / recently.
  double _freshness(List<ItemModel> parts) {
    double sum = 0;
    for (final i in parts) {
      // timesWorn 0 -> 1.0, 10+ -> ~0.0
      sum += (1.0 - (i.timesWorn / 10.0)).clamp(0.0, 1.0);
    }
    return sum / parts.length;
  }

  double _recentPenalty(List<ItemModel> parts, RecommendationContext ctx) {
    if (ctx.recentlyWornItemIds.isEmpty) return 0.0;
    final hits = parts.where((i) => ctx.recentlyWornItemIds.contains(i.itemId)).length;
    return hits / parts.length;
  }
}
