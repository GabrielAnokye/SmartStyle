import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartstyle/features/recommendations/data/feedback_repository.dart';
import 'package:smartstyle/features/recommendations/data/geolocation_service.dart';
import 'package:smartstyle/features/recommendations/data/recommendations_providers.dart';
import 'package:smartstyle/features/recommendations/domain/outfit.dart';
import 'package:smartstyle/features/recommendations/domain/recommendation_context.dart';
import 'package:smartstyle/features/wardrobe/data/wardrobe_repository.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';
import 'package:smartstyle/features/wardrobe/presentation/closet_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dashboardProvider);
    final userOccasion = ref.watch(occasionProvider);
    final inferredAsync = ref.watch(inferredOccasionProvider);
    final inferred = inferredAsync.value;
    final effectiveOccasion = userOccasion ?? inferred ?? Occasion.casual;

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
        onRefresh: () async {
          // Calendar scan results are cached in the inferred provider; without
          // this the dashboard refetches outfits but keeps yesterday's (or
          // pre-permission-grant) occasion guess.
          ref.invalidate(inferredOccasionProvider);
          ref.invalidate(dashboardProvider);
        },
        child: dataAsync.when(
          data: (d) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _WeatherHeader(data: d),
              const SizedBox(height: 16),
              if (inferred != null && userOccasion == null)
                _CalendarHint(suggested: inferred),
              _OccasionPicker(
                current: effectiveOccasion,
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
                        // Key by outfit identity so a different outfit landing
                        // at the same index gets fresh state (prevents the
                        // greyed-out "dismissed" flag from sticking after a
                        // thumbs-down bumps a new combo into place).
                        child: _OutfitCard(
                          key: ValueKey(
                            (e.value.itemIds.toList()..sort()).join('|'),
                          ),
                          rank: e.key + 1,
                          outfit: e.value,
                        ),
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

class _CalendarHint extends ConsumerWidget {
  final Occasion suggested;
  const _CalendarHint({required this.suggested});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.event_available, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Calendar suggests ${suggested.name}. Tap a chip to override.',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
        ],
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

class _OutfitCard extends ConsumerStatefulWidget {
  final int rank;
  final Outfit outfit;
  const _OutfitCard({super.key, required this.rank, required this.outfit});

  @override
  ConsumerState<_OutfitCard> createState() => _OutfitCardState();
}

class _OutfitCardState extends ConsumerState<_OutfitCard> {
  bool _logging = false;
  bool _logged = false;
  bool _dismissed = false;

  Future<void> _rejectOutfit() async {
    if (_dismissed) return;
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => const _RejectReasonSheet(),
    );
    if (reason == null) return;
    final outfit = widget.outfit;
    try {
      await ref.read(feedbackRepositoryProvider).logNegative(
            itemIds: outfit.allItems.map((i) => i.itemId).toList(),
            reason: reason,
          );
      if (!mounted) return;
      setState(() => _dismissed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Noted — we\'ll avoid that combo.')),
      );
      // Pull fresh recs so the rejected outfit is demoted now, not next launch.
      ref.invalidate(dashboardProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save feedback: $e')),
      );
    }
  }

  Future<void> _wearToday() async {
    if (_logging || _logged) return;
    setState(() => _logging = true);
    final outfit = widget.outfit;
    try {
      await ref.read(wardrobeRepositoryProvider).logWear(
            itemIds: outfit.allItems.map((i) => i.itemId).toList(),
            outfitKey: (outfit.itemIds.toList()..sort()).join('|'),
          );
      if (!mounted) return;
      setState(() => _logged = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged — nice fit.')),
      );
      // Counters + state changed, so the closet and dashboard need fresh data.
      ref.invalidate(itemsProvider);
      ref.invalidate(dashboardProvider);
    } on WardrobeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

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
                CircleAvatar(radius: 14, child: Text('${widget.rank}')),
                const SizedBox(width: 8),
                Text(
                  'Score ${(widget.outfit.score * 100).round()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Not for me',
                  icon: const Icon(Icons.thumb_down_off_alt),
                  onPressed: _dismissed || _logged ? null : _rejectOutfit,
                ),
                FilledButton.icon(
                  onPressed: _logged || _logging || _dismissed ? null : _wearToday,
                  icon: _logging
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_logged ? Icons.check : Icons.checkroom, size: 18),
                  label: Text(_logged ? 'Worn' : 'Wear today'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.outfit.allItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _ItemThumb(item: widget.outfit.allItems[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectReasonSheet extends StatelessWidget {
  const _RejectReasonSheet();

  static const _reasons = <({String key, String label})>[
    (key: 'too_warm', label: 'Too warm'),
    (key: 'too_cold', label: 'Too cold'),
    (key: 'too_formal', label: 'Too formal'),
    (key: 'too_casual', label: 'Too casual'),
    (key: 'clash', label: 'Colors clash'),
    (key: 'other', label: 'Something else'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What was off?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons
                  .map((r) => ActionChip(
                        label: Text(r.label),
                        onPressed: () => Navigator.pop(context, r.key),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
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
