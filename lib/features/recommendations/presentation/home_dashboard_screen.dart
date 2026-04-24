import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartstyle/features/recommendations/data/geolocation_service.dart';
import 'package:smartstyle/features/recommendations/data/recommendations_providers.dart';
import 'package:smartstyle/features/recommendations/domain/outfit.dart';
import 'package:smartstyle/features/recommendations/domain/recommendation_context.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';
import 'package:smartstyle/features/wardrobe/presentation/closet_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dashboardProvider);
    final occasion = ref.watch(occasionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            tooltip: 'Change location',
            onPressed: () => _openLocationSheet(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: dataAsync.when(
          data: (d) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _WeatherHeader(data: d),
              const SizedBox(height: 16),
              _OccasionPicker(
                current: occasion,
                onSelect: (v) => ref.read(occasionProvider.notifier).set(v),
              ),
              const SizedBox(height: 16),
              if (d.outfits.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Not enough clean items to compose an outfit. '
                      'Add tops and bottoms to your closet.',
                    ),
                  ),
                )
              else
                ...d.outfits.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OutfitCard(rank: e.key + 1, outfit: e.value),
                      ),
                    ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            error: e,
            onSetManual: () => _openLocationSheet(context, ref),
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
        ),
      ),
    );
  }

  void _openLocationSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _LocationSheet(),
    ).then((_) => ref.invalidate(dashboardProvider));
  }
}

class _WeatherHeader extends StatelessWidget {
  final DashboardData data;
  const _WeatherHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final w = data.weather;
    final label = data.location.label ??
        '${data.location.lat.toStringAsFixed(2)}, ${data.location.lon.toStringAsFixed(2)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${w.tempC.round()}°C · feels ${w.feelsLikeC.round()}°C · '
                    '${(w.precipProb * 100).round()}% rain',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OccasionPicker extends StatelessWidget {
  final Occasion current;
  final ValueChanged<Occasion> onSelect;
  const _OccasionPicker({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: Occasion.values
            .map((o) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(o.name),
                    selected: o == current,
                    onSelected: (_) => onSelect(o),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final int rank;
  final Outfit outfit;
  const _OutfitCard({required this.rank, required this.outfit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 14, child: Text('$rank')),
                const SizedBox(width: 8),
                Text(
                  'Score ${(outfit.score * 100).round()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: outfit.allItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _ItemThumb(item: outfit.allItems[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemThumb extends ConsumerWidget {
  final ItemModel item;
  const _ItemThumb({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(signedUrlProvider(item.imageUrl));
    final borderColor =
        int.tryParse(item.primaryHex.replaceFirst('#', 'FF'), radix: 16) ?? 0xFF808080;
    return Container(
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(borderColor), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: urlAsync.when(
        data: (url) => CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Icon(Icons.broken_image),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onSetManual;
  const _ErrorState({required this.error, required this.onRetry, required this.onSetManual});

  @override
  Widget build(BuildContext context) {
    final isLocation = error is GeolocationException;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isLocation ? Icons.location_off : Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (isLocation)
              FilledButton(onPressed: onSetManual, child: const Text('Set city manually'))
            else
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _LocationSheet extends ConsumerStatefulWidget {
  const _LocationSheet();
  @override
  ConsumerState<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<_LocationSheet> {
  final _ctrl = TextEditingController();
  List<LocationFix> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref.read(geolocationServiceProvider).searchCity(_ctrl.text);
      setState(() => _results = r);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick(LocationFix fix) async {
    await ref.read(geolocationServiceProvider).saveManual(fix);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clearManual() async {
    await ref.read(geolocationServiceProvider).clearManual();
    if (mounted) Navigator.pop(context);
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              labelText: 'City name',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
            ),
            onSubmitted: (_) => _search(),
          ),
          if (_loading) const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
          ..._results.map((r) => ListTile(
                title: Text(r.label ?? '${r.lat}, ${r.lon}'),
                onTap: () => _pick(r),
              )),
          const Divider(),
          TextButton.icon(
            icon: const Icon(Icons.my_location),
            label: const Text('Use GPS instead'),
            onPressed: _clearManual,
          ),
        ],
      ),
    );
  }
}
