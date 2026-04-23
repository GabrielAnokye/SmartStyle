import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartstyle/features/wardrobe/data/wardrobe_repository.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';
import 'package:smartstyle/features/wardrobe/presentation/closet_screen.dart';

final itemByIdProvider =
    FutureProvider.family<ItemModel, String>((ref, id) async {
  return ref.watch(wardrobeRepositoryProvider).getItem(id);
});

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemByIdProvider(itemId));
    return Scaffold(
      appBar: AppBar(title: const Text('Item')),
      body: itemAsync.when(
        data: (item) => _Body(item: item),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final ItemModel item;
  const _Body({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(signedUrlProvider(item.imageUrl));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: urlAsync.when(
              data: (url) => CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const Icon(Icons.broken_image),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Icon(Icons.broken_image),
            ),
          ),
          const SizedBox(height: 16),
          _Row(label: 'Category', value: item.category),
          _Row(label: 'State', value: item.state.name),
          _Row(label: 'Primary color', value: item.primaryHex),
          _Row(label: 'Warmth (CLO)', value: item.warmthClo.toStringAsFixed(2)),
          _Row(
            label: 'Purchase price',
            value: item.purchasePrice?.toStringAsFixed(2) ?? '—',
          ),
          _Row(label: 'Times worn', value: item.timesWorn.toString()),
          _Row(
            label: 'Cost per wear',
            value: item.costPerWear?.toStringAsFixed(2) ?? '—',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/closet/${item.itemId}/edit'),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
                  onPressed: () => _confirmDelete(context, ref),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final repo = ref.read(wardrobeRepositoryProvider);
      await repo.deleteItem(item.itemId);
      await repo.deleteItemImage(item.imageUrl);
      ref.invalidate(itemsProvider);
      if (context.mounted) context.pop();
    } on WardrobeException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
