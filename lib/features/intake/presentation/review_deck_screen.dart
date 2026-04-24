import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:smartstyle/core/services/supabase_service.dart';
import 'package:smartstyle/core/utils/media_processing_service.dart';
import 'package:smartstyle/features/intake/data/intake_providers.dart';
import 'package:smartstyle/features/intake/data/intake_queue.dart';
import 'package:smartstyle/features/intake/domain/classifier.dart';
import 'package:smartstyle/features/intake/domain/intake_draft.dart';
import 'package:smartstyle/features/intake/domain/segmenter.dart';
import 'package:path_provider/path_provider.dart';

class ReviewDeckScreen extends ConsumerStatefulWidget {
  final List<IntakeDraft> drafts;
  const ReviewDeckScreen({super.key, required this.drafts});

  @override
  ConsumerState<ReviewDeckScreen> createState() => _ReviewDeckScreenState();
}

class _ReviewDeckScreenState extends ConsumerState<ReviewDeckScreen> {
  final _pageController = PageController();
  int _index = 0;
  bool _initialEnrichmentStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialEnrichmentStarted) {
      _initialEnrichmentStarted = true;
      _enrichAll();
    }
  }

  Future<void> _enrichAll() async {
    final segmenter = ref.read(segmenterProvider);
    final classifier = ref.read(classifierProvider);
    for (final d in widget.drafts) {
      await _enrichOne(d, segmenter, classifier);
      if (mounted) setState(() {});
    }
  }

  Future<void> _enrichOne(
    IntakeDraft draft,
    Segmenter segmenter,
    Classifier classifier,
  ) async {
    try {
      final rawBytes = await File(draft.rawImagePath).readAsBytes();
      final segmented = await segmenter.stripBackground(rawBytes);
      final workingBytes = segmented ?? rawBytes;

      if (segmented != null) {
        final tempDir = await getTemporaryDirectory();
        final segFile = File('${tempDir.path}/seg_${draft.id}.png');
        await segFile.writeAsBytes(segmented);
        draft.segmentedImagePath = segFile.path;
      }

      final result = await classifier.classify(workingBytes);
      draft
        ..suggestedCategory = result.category
        ..confidence = result.confidence;

      final hex = await MediaProcessingService.extractDominantColor(workingBytes);
      draft.primaryHex = hex;
    } catch (e) {
      debugPrint('Enrichment failed for ${draft.id}: $e');
    }
  }

  Future<Uint8List?> _compressedFor(IntakeDraft d) async {
    final path = d.segmentedImagePath ?? d.rawImagePath;
    return MediaProcessingService.compressImagePath(path);
  }

  Future<void> _save(IntakeDraft d) async {
    d.savedAt ??= DateTime.now();
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) {
      _toast('Not signed in.');
      return;
    }
    try {
      final compressed = await _compressedFor(d);
      if (compressed == null) {
        _toast('Could not compress image below 200KB.');
        return;
      }
      // Durable dir — iOS purges getTemporaryDirectory() when the app is
      // backgrounded, which would make the queue drain fail with
      // "Local image missing" on every subsequent launch.
      final docsDir = await getApplicationDocumentsDirectory();
      final queueDir = Directory('${docsDir.path}/intake_queue');
      if (!await queueDir.exists()) {
        await queueDir.create(recursive: true);
      }
      final finalFile = File('${queueDir.path}/${d.id}.jpg');
      await finalFile.writeAsBytes(compressed);

      final queued = QueuedItem(
        id: d.id,
        userId: user.id,
        // Basename only — queue resolves against current documents dir.
        imagePath: '${d.id}.jpg',
        category: d.effectiveCategory,
        primaryHex: d.primaryHex ?? '#808080',
        purchasePrice: d.purchasePrice,
      );
      await ref.read(intakeQueueProvider).enqueue(queued);

      final ms = d.timeToConfirmMs;
      if (ms != null) {
        // Instrumentation: target ≤10s median. Sentry breadcrumb is free.
        Sentry.addBreadcrumb(Breadcrumb(
          category: 'intake',
          message: 'confirmed in ${ms}ms',
          data: {'item_id': d.id, 'confidence': d.confidence ?? 0},
        ));
      }
      _advance();
    } catch (e) {
      _toast('Save failed: $e');
    }
  }

  void _skip(IntakeDraft d) {
    // User declined the item; drop it from the batch.
    d.savedAt = DateTime.now();
    _advance();
  }

  void _advance() {
    final next = _index + 1;
    if (next >= widget.drafts.length) {
      _finish();
      return;
    }
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _finish() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch queued for upload!')),
    );
    // Pop review deck + batch camera off the /add branch so the tab returns
    // to the hub — otherwise re-tapping Add shows the same drafts and Save
    // enqueues duplicates.
    while (context.canPop()) {
      context.pop();
    }
    context.go('/closet');
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review ${_index + 1}/${widget.drafts.length}')),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.drafts.length,
        onPageChanged: (i) {
          setState(() => _index = i);
          widget.drafts[i].displayedAt = DateTime.now();
        },
        itemBuilder: (context, i) => _ReviewCard(
          draft: widget.drafts[i],
          onSave: () => _save(widget.drafts[i]),
          onSkip: () => _skip(widget.drafts[i]),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final IntakeDraft draft;
  final VoidCallback onSave;
  final VoidCallback onSkip;
  const _ReviewCard({required this.draft, required this.onSave, required this.onSkip});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _categoryCtrl = TextEditingController(text: widget.draft.effectiveCategory);
    _priceCtrl = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant _ReviewCard old) {
    super.didUpdateWidget(old);
    if (old.draft.id != widget.draft.id) {
      _categoryCtrl.text = widget.draft.effectiveCategory;
      _priceCtrl.text = widget.draft.purchasePrice?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final colorVal = int.tryParse((d.primaryHex ?? '#808080').replaceFirst('#', 'FF'), radix: 16) ?? 0xFF808080;
    final previewPath = d.segmentedImagePath ?? d.rawImagePath;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(colorVal), width: 6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(File(previewPath), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (d.confidence != null && d.confidence! < 0.6)
            const Card(
              color: Color(0xFFFFF3CD),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Unsure about category — please confirm below.'),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => d.userCategory = v,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Purchase Price',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => d.purchasePrice = double.tryParse(v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onSkip,
                  label: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  onPressed: widget.onSave,
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
