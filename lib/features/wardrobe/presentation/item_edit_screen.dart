import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartstyle/features/wardrobe/data/wardrobe_repository.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';
import 'package:smartstyle/features/wardrobe/presentation/closet_screen.dart';
import 'package:smartstyle/features/wardrobe/presentation/item_detail_screen.dart';

class ItemEditScreen extends ConsumerWidget {
  final String itemId;
  const ItemEditScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemByIdProvider(itemId));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: itemAsync.when(
        data: (item) => _EditForm(item: item),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  final ItemModel item;
  const _EditForm({required this.item});

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _warmthCtrl;
  late ItemState _state;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoryCtrl = TextEditingController(text: widget.item.category);
    _priceCtrl = TextEditingController(
      text: widget.item.purchasePrice?.toString() ?? '',
    );
    _warmthCtrl = TextEditingController(text: widget.item.warmthClo.toString());
    _state = widget.item.state;
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _warmthCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final category = _categoryCtrl.text.trim();
    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category is required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = widget.item.copyWith(
        category: category,
        purchasePrice: double.tryParse(_priceCtrl.text),
        warmthClo: double.tryParse(_warmthCtrl.text) ?? widget.item.warmthClo,
        state: _state,
      );
      await ref.read(wardrobeRepositoryProvider).updateItem(updated);
      ref.invalidate(itemsProvider);
      ref.invalidate(itemByIdProvider(widget.item.itemId));
      if (mounted) context.pop();
    } on WardrobeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Purchase Price', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _warmthCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Warmth (CLO)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ItemState>(
            initialValue: _state,
            decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
            items: ItemState.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _state = v ?? _state),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}
