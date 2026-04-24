import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartstyle/features/wardrobe/data/wardrobe_repository.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ClosetFilter {
  final String? category;
  final ItemState? state;
  const ClosetFilter({this.category, this.state});

  ClosetFilter copyWith({String? category, ItemState? state, bool clearCategory = false, bool clearState = false}) {
    return ClosetFilter(
      category: clearCategory ? null : (category ?? this.category),
      state: clearState ? null : (state ?? this.state),
    );
  }
}

class ClosetFilterNotifier extends Notifier<ClosetFilter> {
  @override
  ClosetFilter build() => const ClosetFilter();
  void set(ClosetFilter value) => state = value;
  void clear() => state = const ClosetFilter();
}

final closetFilterProvider =
    NotifierProvider<ClosetFilterNotifier, ClosetFilter>(ClosetFilterNotifier.new);

const int kClosetPageSize = 20;

final itemsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final repo = ref.watch(wardrobeRepositoryProvider);
  final filter = ref.watch(closetFilterProvider);
  // First page; pagination below loads additional pages on demand.
  return repo.getItems(
    limit: kClosetPageSize,
    offset: 0,
    categoryFilter: filter.category,
    stateFilter: filter.state,
  );
});

final signedUrlProvider = FutureProvider.family<String, String>((ref, path) async {
  final repo = ref.watch(wardrobeRepositoryProvider);
  return repo.signedUrlFor(path);
});

class ClosetScreen extends ConsumerStatefulWidget {
  const ClosetScreen({super.key});

  @override
  ConsumerState<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends ConsumerState<ClosetScreen> {
  final List<ItemModel> _loaded = [];
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final filter = ref.read(closetFilterProvider);
      final next = await ref.read(wardrobeRepositoryProvider).getItems(
            limit: kClosetPageSize,
            offset: _offset,
            categoryFilter: filter.category,
            stateFilter: filter.state,
          );
      setState(() {
        _loaded.addAll(next);
        _offset += next.length;
        _hasMore = next.length == kClosetPageSize;
      });
    } on WardrobeException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _resetPagination(List<ItemModel> firstPage) {
    _loaded
      ..clear()
      ..addAll(firstPage);
    _offset = firstPage.length;
    _hasMore = firstPage.length == kClosetPageSize;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ClosetFilter>(closetFilterProvider, (previous, current) {
      ref.invalidate(itemsProvider);
    });

    final itemsAsync = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Closet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _openFilterSheet(context),
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (firstPage) {
          if (_loaded.isEmpty && _offset == 0) {
            _resetPagination(firstPage);
          }
          if (_loaded.isEmpty) {
            return const Center(child: Text('Your closet is empty. Add some items!'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              _offset = 0;
              _loaded.clear();
              _hasMore = true;
              ref.invalidate(itemsProvider);
            },
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _loaded.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _loaded.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final item = _loaded[index];
                return _ItemCard(
                  item: item,
                  onTap: () => context.push('/closet/${item.itemId}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    final current = ref.read(closetFilterProvider);
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet(initial: current),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  final ItemModel item;
  final VoidCallback onTap;
  const _ItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorVal = int.tryParse(item.primaryHex.replaceFirst('#', 'FF'), radix: 16) ?? 0xFF808080;
    final urlAsync = ref.watch(signedUrlProvider(item.imageUrl));
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Color(colorVal), width: 3),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            urlAsync.when(
              data: (url) => CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: Colors.black54,
                child: Text(
                  item.category.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  final ClosetFilter initial;
  const _FilterSheet({required this.initial});
  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late TextEditingController _categoryCtrl;
  ItemState? _state;

  @override
  void initState() {
    super.initState();
    _categoryCtrl = TextEditingController(text: widget.initial.category ?? '');
    _state = widget.initial.state;
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ItemState?>(
            initialValue: _state,
            decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem<ItemState?>(value: null, child: Text('Any')),
              ...ItemState.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))),
            ],
            onChanged: (v) => setState(() => _state = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(closetFilterProvider.notifier).clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(closetFilterProvider.notifier).set(
                          ClosetFilter(
                            category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
                            state: _state,
                          ),
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
