import 'package:flutter_test/flutter_test.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';

void main() {
  group('ItemModel Serialization Tests', () {
    test('should correctly serialize and deserialize ItemModel from JSON', () {
      final jsonMap = {
        'item_id': '123-abc',
        'user_id': 'user-1',
        'created_at': '2026-04-13T08:00:00.000Z',
        'image_url': 'https://example.com/image.jpg',
        'ml_detected_category': 'jacket',
        'category': 'outerwear',
        'primary_hex': '#2B4A6B',
        'warmth_clo': 0.8,
        'purchase_price': 89.0,
        'occasions': ['casual', 'dinner'],
        'fabrics': ['cotton', 'polyester'],
        'times_worn': 12,
        'state': 'clean',
        'wears_before_laundry': 1,
        'last_worn_at': null,
        'cost_per_wear': 7.41
      };

      final item = ItemModel.fromJson(jsonMap);

      expect(item.itemId, '123-abc');
      expect(item.state, ItemState.clean);
      expect(item.warmthClo, 0.8);
      expect(item.occasions.length, 2);

      final convertedJson = item.toJson();
      expect(convertedJson['primary_hex'], '#2B4A6B');
      expect(convertedJson['state'], 'clean');
      expect(convertedJson['cost_per_wear'], 7.41);
    });

    test('should fallback to defaults when optional fields are omitted', () {
       final jsonMap = {
        'item_id': '123-abc',
        'user_id': 'user-1',
        'created_at': '2026-04-13T08:00:00.000Z',
        'image_url': 'https://example.com/image.jpg',
        'category': 'outerwear',
        'primary_hex': '#2B4A6B',
      };

      final item = ItemModel.fromJson(jsonMap);

      expect(item.warmthClo, 0.0);
      expect(item.timesWorn, 0);
      expect(item.state, ItemState.clean);
      expect(item.wearsBeforeLaundry, 1);
      expect(item.occasions, isEmpty);
    });
  });
}
