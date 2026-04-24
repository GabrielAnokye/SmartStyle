import 'package:flutter_test/flutter_test.dart';
import 'package:smartstyle/features/recommendations/domain/outfit.dart';
import 'package:smartstyle/features/recommendations/domain/recommendation_context.dart';
import 'package:smartstyle/features/recommendations/domain/scoring_engine.dart';
import 'package:smartstyle/features/recommendations/domain/weather_snapshot.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';
import 'package:uuid/uuid.dart';

void main() {
  late ScoringEngine engine;

  ItemModel mockItem({
    required String category,
    required ItemState state,
    double warmthClo = 0.5,
    List<String> occasions = const ['casual'],
    int timesWorn = 0,
  }) {
    return ItemModel(
      itemId: const Uuid().v4(),
      userId: 'test-user',
      imageUrl: 'test.jpg',
      category: category,
      primaryHex: '#000000',
      purchasePrice: 0.0,
      createdAt: DateTime.now(),
      state: state,
      warmthClo: warmthClo,
      occasions: occasions,
      timesWorn: timesWorn,
    );
  }

  setUp(() {
    engine = const ScoringEngine();
  });

  group('Laundry Filter Property Tests', () {
    test('laundry items never surface in recommendations', () {
      final dirtyShirt = mockItem(category: 't-shirt', state: ItemState.laundry);
      final cleanPants = mockItem(category: 'jeans', state: ItemState.clean);
      final laundryShirt = mockItem(category: 'shirt', state: ItemState.laundry);

      final ctx = RecommendationContext(
        weather: WeatherSnapshot(tempC: 22, feelsLikeC: 22, precipProb: 0, windKph: 5, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {},
      );

      final outfits = engine.recommend(
        items: [dirtyShirt, cleanPants, laundryShirt],
        context: ctx,
      );

      // We supplied no clean tops/dresses, so NO outfits can be formed mathematically.
      expect(outfits.isEmpty, isTrue);
    });

    test('worn but not dirty items DO surface', () {
      final wornShirt = mockItem(category: 't-shirt', state: ItemState.worn);
      final cleanPants = mockItem(category: 'jeans', state: ItemState.clean);

      final ctx = RecommendationContext(
        weather: WeatherSnapshot(tempC: 22, feelsLikeC: 22, precipProb: 0, windKph: 5, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {},
      );

      final outfits = engine.recommend(
        items: [wornShirt, cleanPants],
        context: ctx,
      );

      expect(outfits.length, equals(1));
      expect(outfits.first.top.itemId, equals(wornShirt.itemId));
    });
  });

  group('Boundary Weather Testing (Outerwear Mechanics)', () {
    final tShirt = mockItem(category: 't-shirt', state: ItemState.clean, warmthClo: 0.4);
    final jeans = mockItem(category: 'jeans', state: ItemState.clean, warmthClo: 0.5);
    final jacket = mockItem(category: 'jacket', state: ItemState.clean, warmthClo: 1.0);

    test('15.0°C does NOT require outerwear, no penalty missing it', () {
      final ctx = RecommendationContext(
        weather: WeatherSnapshot(tempC: 15, feelsLikeC: 15, precipProb: 0, windKph: 5, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {},
      );

      final outfitsWithoutJacket = engine.recommend(
        items: [tShirt, jeans],
        context: ctx,
      );

      expect(outfitsWithoutJacket.isNotEmpty, isTrue);
      expect(outfitsWithoutJacket.first.scoreBreakdown['missing_outer'], equals(0.0));
      expect(outfitsWithoutJacket.first.outerwear, isNull);
    });

    test('14.9°C DOES require outerwear, penalty applied if missing', () {
      final ctx = RecommendationContext(
        weather: WeatherSnapshot(tempC: 14.9, feelsLikeC: 14.9, precipProb: 0, windKph: 0, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {},
      );

      // Test without jacket
      final missingJacket = engine.recommend(items: [tShirt, jeans], context: ctx);
      expect(missingJacket.first.scoreBreakdown['missing_outer'], equals(0.3));

      // Test with jacket available
      final withJacket = engine.recommend(items: [tShirt, jeans, jacket], context: ctx);
      expect(withJacket.first.scoreBreakdown['missing_outer'], equals(0.0));
      expect(withJacket.first.outerwear, isNotNull);
      expect(withJacket.first.score, greaterThan(missingJacket.first.score));
    });
  });

  group('Outfit Composition & De-duplication', () {
    test('Dresses seamlessly substitute top and bottom', () {
      final dress = mockItem(category: 'dress', state: ItemState.clean, warmthClo: 0.6);
      final ctx = RecommendationContext(
        weather: WeatherSnapshot(tempC: 25, feelsLikeC: 25, precipProb: 0, windKph: 0, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {},
      );

      final outfits = engine.recommend(items: [dress], context: ctx);
      expect(outfits.length, equals(1));
      expect(outfits.first.top.itemId, equals(dress.itemId));
      expect(outfits.first.bottom.itemId, equals(dress.itemId));
    });

    test('Dress is not double-counted in allItems or warmth fit', () {
      // Dress clo 0.6 at feels-like 25°C (target 0.4). If double-counted,
      // total clo = 1.2 (delta 0.8 -> weather_fit ~0.47). Single-counted,
      // total clo = 0.6 (delta 0.2 -> weather_fit ~0.87).
      final dress = mockItem(category: 'dress', state: ItemState.clean, warmthClo: 0.6);
      final ctx = RecommendationContext(
        weather: WeatherSnapshot(tempC: 25, feelsLikeC: 25, precipProb: 0, windKph: 0, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {},
      );
      final outfit = engine.recommend(items: [dress], context: ctx).first;
      expect(outfit.allItems.length, equals(1),
          reason: 'Dress should appear once, not twice, in allItems');
      expect(outfit.scoreBreakdown['weather']!, greaterThan(0.8),
          reason: 'Warmth must not be doubled by dress occupying two slots');
    });

    test('Unknown categories are ignored, not forced into an outfit', () {
      final accessory = mockItem(category: 'accessory', state: ItemState.clean);
      final shirt = mockItem(category: 't-shirt', state: ItemState.clean);
      final jeans = mockItem(category: 'jeans', state: ItemState.clean);
      final ctx = RecommendationContext(
        weather: WeatherSnapshot(tempC: 22, feelsLikeC: 22, precipProb: 0, windKph: 0, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {},
      );
      final outfit = engine.recommend(items: [accessory, shirt, jeans], context: ctx).first;
      expect(outfit.itemIds.contains(accessory.itemId), isFalse);
    });
  });

  group('Feedback Penalty', () {
    test('outfit sharing ≥2 items with recent thumbs-down is demoted', () {
      final t1 = mockItem(category: 't-shirt', state: ItemState.clean);
      final t2 = mockItem(category: 't-shirt', state: ItemState.clean);
      final b1 = mockItem(category: 'jeans', state: ItemState.clean);
      final b2 = mockItem(category: 'jeans', state: ItemState.clean);

      final ctx = RecommendationContext(
        weather: WeatherSnapshot(tempC: 22, feelsLikeC: 22, precipProb: 0, windKph: 0, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {},
        negativeFeedback: [
          FeedbackSignal(itemIds: {t1.itemId, b1.itemId}, weight: 1.0),
        ],
      );

      final outfits = engine.recommend(items: [t1, t2, b1, b2], context: ctx, topN: 4);
      // The (t1,b1) combo must not be rank 1 anymore.
      expect(outfits.first.itemIds, isNot(equals({t1.itemId, b1.itemId})));
    });

    test('single-item overlap does NOT trigger penalty', () {
      final shirt = mockItem(category: 't-shirt', state: ItemState.clean);
      final jeans = mockItem(category: 'jeans', state: ItemState.clean);
      final strangerId = 'ffffffff-ffff-ffff-ffff-ffffffffffff';

      final ctx = RecommendationContext(
        weather: WeatherSnapshot(tempC: 22, feelsLikeC: 22, precipProb: 0, windKph: 0, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {},
        negativeFeedback: [
          // Only shirt overlaps; the other item isn't in the closet.
          FeedbackSignal(itemIds: {shirt.itemId, strangerId}, weight: 1.0),
        ],
      );

      final outfit = engine.recommend(items: [shirt, jeans], context: ctx).first;
      expect(outfit.scoreBreakdown['feedback_penalty'], equals(0.0));
    });

    test('stronger (fresher) signal dominates older ones', () {
      final shirt = mockItem(category: 't-shirt', state: ItemState.clean);
      final jeans = mockItem(category: 'jeans', state: ItemState.clean);
      final ctx = RecommendationContext(
        weather: WeatherSnapshot(tempC: 22, feelsLikeC: 22, precipProb: 0, windKph: 0, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {},
        negativeFeedback: [
          FeedbackSignal(itemIds: {shirt.itemId, jeans.itemId}, weight: 0.2),
          FeedbackSignal(itemIds: {shirt.itemId, jeans.itemId}, weight: 0.9),
        ],
      );
      final outfit = engine.recommend(items: [shirt, jeans], context: ctx).first;
      expect(outfit.scoreBreakdown['feedback_penalty'], closeTo(0.9, 1e-9));
    });
  });

  group('Rejection Penalty & Freshness Delta', () {
    test('Recently worn items apply distinct mathematical penalty clamp', () {
      final overWornShirt = mockItem(category: 't-shirt', state: ItemState.clean, timesWorn: 3);
      final freshShirt = mockItem(category: 't-shirt', state: ItemState.clean, timesWorn: 0);
      final jeans = mockItem(category: 'jeans', state: ItemState.clean);

      final ctxNormal = RecommendationContext(
        weather: WeatherSnapshot(tempC: 22, feelsLikeC: 22, precipProb: 0, windKph: 5, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {},
      );

      // Ensure fresh shirt is ranked better due to 0 timesWorn vs 15 timesWorn.
      final outfitsNormal = engine.recommend(
        items: [overWornShirt, freshShirt, jeans],
        context: ctxNormal,
      );

      expect(outfitsNormal.first.top.itemId, equals(freshShirt.itemId));

      // Now severely penalize the fresh shirt via Context tracking.
      final ctxPenalized = RecommendationContext(
        weather: WeatherSnapshot(tempC: 22, feelsLikeC: 22, precipProb: 0, windKph: 5, fetchedAt: DateTime.now()),
        occasion: Occasion.casual,
        when: DateTime.now(),
        recentlyWornItemIds: {freshShirt.itemId},
      );

      final outfitsPenalized = engine.recommend(
        items: [overWornShirt, freshShirt, jeans],
        context: ctxPenalized,
      );

      // Because freshShirt is in recentlyWornItemIds, it gets a heavy recent_penalty delta,
      // forcing overWornShirt to float to rank #1.
      expect(outfitsPenalized.first.top.itemId, equals(overWornShirt.itemId));
    });
  });
}
