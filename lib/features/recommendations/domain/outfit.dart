import 'package:smartstyle/features/wardrobe/domain/item_model.dart';

class Outfit {
  final ItemModel top;
  final ItemModel bottom;
  final ItemModel? outerwear;
  final ItemModel? shoes;
  final double score;
  final Map<String, double> scoreBreakdown;

  const Outfit({
    required this.top,
    required this.bottom,
    this.outerwear,
    this.shoes,
    required this.score,
    this.scoreBreakdown = const {},
  });

  List<ItemModel> get allItems => [
        top,
        // Dresses occupy both slots, so skip a second copy.
        if (bottom.itemId != top.itemId) bottom,
        ?outerwear,
        ?shoes,
      ];

  Set<String> get itemIds => allItems.map((i) => i.itemId).toSet();
}
