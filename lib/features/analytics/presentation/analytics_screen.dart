import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartstyle/features/analytics/domain/analytics_summary.dart';
import 'package:smartstyle/features/wardrobe/data/wardrobe_repository.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';
import 'package:smartstyle/features/wardrobe/presentation/closet_screen.dart';

final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>((ref) async {
  final repo = ref.watch(wardrobeRepositoryProvider);
  final items = await repo.getItems(limit: 500, offset: 0);
  return AnalyticsSummary.from(items);
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(analyticsSummaryProvider),
        child: summaryAsync.when(
          data: (s) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Closet value',
                      value: _money(s.totalValue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Median CPW',
                      value: s.medianCostPerWear != null
                          ? _money(s.medianCostPerWear!)
                          : '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatCard(label: 'Items tracked', value: '${s.itemCount}'),
              const SizedBox(height: 24),
              const Text(
                'Worst value in your closet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Items with the highest cost-per-wear. Wear them more or consider letting them go.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              if (s.bottomFiveCpw.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Add purchase prices to your items to unlock cost-per-wear analytics.',
                    ),
                  ),
                )
              else
                ...s.bottomFiveCpw.map((i) => _BottomItemTile(item: i)),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  String _money(double v) => '\$${v.toStringAsFixed(2)}';
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _BottomItemTile extends ConsumerWidget {
  final ItemModel item;
  const _BottomItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(signedUrlProvider(item.imageUrl));
    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 52,
          height: 52,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: urlAsync.when(
              data: (url) => CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
              loading: () => Container(color: Colors.grey.shade200),
              error: (_, _) => const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        title: Text(item.category),
        subtitle: Text('worn ${item.timesWorn}×'),
        trailing: Text(
          '\$${item.costPerWear!.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onTap: () => context.push('/closet/${item.itemId}'),
      ),
    );
  }
}
