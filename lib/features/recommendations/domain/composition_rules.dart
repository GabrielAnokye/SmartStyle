import 'package:smartstyle/features/wardrobe/domain/item_model.dart';

/// Canonical categories the engine understands. Items with other categories
/// (accessories, etc.) are ignored by composition for now.
enum Slot { top, bottom, dress, outerwear, shoes }

Slot? slotFor(ItemModel item) {
  final c = item.category.toLowerCase();
  if (c == 'tops' || c == 'top' || c == 'shirt' || c == 't-shirt') return Slot.top;
  if (c == 'bottoms' || c == 'bottom' || c == 'pants' || c == 'jeans' || c == 'shorts' || c == 'skirt') return Slot.bottom;
  if (c == 'dress' || c == 'dresses') return Slot.dress;
  if (c == 'outerwear' || c == 'jacket' || c == 'coat') return Slot.outerwear;
  if (c == 'shoes' || c == 'footwear') return Slot.shoes;
  return null;
}

/// Outerwear is required when the day is cold or wet.
bool needsOuterwear({required double feelsLikeC, required double precipProb}) {
  return feelsLikeC < 15.0 || precipProb > 0.4;
}
