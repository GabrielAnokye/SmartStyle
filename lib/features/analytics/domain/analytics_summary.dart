import 'package:smartstyle/features/wardrobe/domain/item_model.dart';

class AnalyticsSummary {
  final int itemCount;
  final double totalValue;
  final double? medianCostPerWear;
  // Worst-offender items — purchased, barely worn, dragging CPW up.
  final List<ItemModel> bottomFiveCpw;

  const AnalyticsSummary({
    required this.itemCount,
    required this.totalValue,
    required this.medianCostPerWear,
    required this.bottomFiveCpw,
  });

  /// Pure computation so it can be unit-tested without Supabase.
  /// - `totalValue` sums `purchase_price` (null treated as 0).
  /// - `medianCostPerWear` is the median across items that actually have a
  ///   `costPerWear` value. Null if nothing qualifies.
  /// - `bottomFiveCpw` returns up to 5 items with the highest cost-per-wear
  ///   (worst value). Items without a price are excluded — they'd be noisy.
  factory AnalyticsSummary.from(List<ItemModel> items) {
    double total = 0;
    final priced = <ItemModel>[];
    for (final i in items) {
      if (i.purchasePrice != null) total += i.purchasePrice!;
      if (i.costPerWear != null && i.purchasePrice != null) priced.add(i);
    }

    double? median;
    if (priced.isNotEmpty) {
      final cpws = priced.map((i) => i.costPerWear!).toList()..sort();
      final mid = cpws.length ~/ 2;
      median = cpws.length.isOdd
          ? cpws[mid]
          : (cpws[mid - 1] + cpws[mid]) / 2.0;
    }

    final worst = priced.toList()
      ..sort((a, b) => (b.costPerWear!).compareTo(a.costPerWear!));
    final bottom = worst.take(5).toList();

    return AnalyticsSummary(
      itemCount: items.length,
      totalValue: total,
      medianCostPerWear: median,
      bottomFiveCpw: bottom,
    );
  }
}
