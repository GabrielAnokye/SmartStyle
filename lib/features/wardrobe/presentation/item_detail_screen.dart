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
          _StateActions(item: item),
          const SizedBox(height: 12),
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

class _StateActions extends ConsumerStatefulWidget {
  final ItemModel item;
  const _StateActions({required this.item});

  @override
  ConsumerState<_StateActions> createState() => _StateActionsState();
}

class _StateActionsState extends ConsumerState<_StateActions> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() op, String successMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await op();
      if (!mounted) return;
      ref.invalidate(itemByIdProvider(widget.item.itemId));
      ref.invalidate(itemsProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
    } on WardrobeException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(wardrobeRepositoryProvider);
    final item = widget.item;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          icon: const Icon(Icons.checkroom, size: 18),
          onPressed: _busy || item.state == ItemState.laundry
              ? null
              : () => _run(
                    () => repo.logWear(itemIds: [item.itemId]),
                    'Wear logged.',
                  ),
          label: const Text('Log wear'),
        ),
        if (item.state != ItemState.laundry)
          OutlinedButton.icon(
            icon: const Icon(Icons.local_laundry_service, size: 18),
            onPressed: _busy
                ? null
                : () => _run(
                      () => repo.setState(item.itemId, ItemState.laundry),
                      'Marked dirty.',
                    ),
            label: const Text('Send to laundry'),
          ),
        if (item.state == ItemState.laundry)
          FilledButton.icon(
            icon: const Icon(Icons.cleaning_services, size: 18),
            onPressed: _busy
                ? null
                : () => _run(
                      () => repo.setState(item.itemId, ItemState.clean),
                      'Back to clean.',
                    ),
            label: const Text('Mark clean'),
          ),
      ],
    );
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
