import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartstyle/features/wardrobe/data/wardrobe_repository.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';
import 'package:smartstyle/features/wardrobe/presentation/closet_screen.dart';

enum QueuedStatus { pending, uploading, done, failed }

class QueuedItem {
  final String id; // also used as ItemModel.item_id
  final String userId;
  // Filename within the durable intake_queue/ subdir, not an absolute path —
  // iOS rewrites the app-container path on reinstall, so absolute paths
  // persisted here would all go stale.
  final String imagePath;
  final String category;
  final String primaryHex;
  final double? purchasePrice;
  QueuedStatus status;
  String? lastError;

  QueuedItem({
    required this.id,
    required this.userId,
    required String imagePath,
    required this.category,
    required this.primaryHex,
    this.purchasePrice,
    this.status = QueuedStatus.pending,
    this.lastError,
  }) : imagePath = imagePath.contains('/') ? imagePath.split('/').last : imagePath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'image_path': imagePath,
        'category': category,
        'primary_hex': primaryHex,
        'purchase_price': purchasePrice,
        'status': status.name,
        'last_error': lastError,
      };

  static QueuedItem fromJson(Map<String, dynamic> j) => QueuedItem(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        imagePath: j['image_path'] as String,
        category: j['category'] as String,
        primaryHex: j['primary_hex'] as String,
        purchasePrice: (j['purchase_price'] as num?)?.toDouble(),
        status: QueuedStatus.values.firstWhere(
          (s) => s.name == (j['status'] as String? ?? 'pending'),
          orElse: () => QueuedStatus.pending,
        ),
        lastError: j['last_error'] as String?,
      );
}

/// Durable, file-backed queue. Keeps things simple and free of native-dep
/// codegen while still surviving app kills.
class IntakeQueue {
  static const _fileName = 'intake_queue.json';
  final WardrobeRepository _repo;
  final Connectivity _connectivity;
  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  final List<QueuedItem> _items = [];
  final _controller = StreamController<List<QueuedItem>>.broadcast();
  bool _draining = false;
  bool _loaded = false;

  IntakeQueue(this._repo, this._connectivity, this._ref);

  Stream<List<QueuedItem>> watch() => _controller.stream;
  List<QueuedItem> get snapshot => List.unmodifiable(_items);

  Future<File> _storeFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<Directory> _queueDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final q = Directory('${dir.path}/intake_queue');
    if (!await q.exists()) await q.create(recursive: true);
    return q;
  }

  Future<File> resolveFile(QueuedItem q) async {
    final dir = await _queueDir();
    return File('${dir.path}/${q.imagePath}');
  }

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final f = await _storeFile();
      if (!await f.exists()) return;
      final text = await f.readAsString();
      if (text.trim().isEmpty) return;
      final list = jsonDecode(text) as List<dynamic>;
      _items
        ..clear()
        ..addAll(list.map((j) => QueuedItem.fromJson(j as Map<String, dynamic>)));
      _emit();
    } catch (e) {
      debugPrint('IntakeQueue load failed: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final f = await _storeFile();
      await f.writeAsString(jsonEncode(_items.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('IntakeQueue persist failed: $e');
    }
  }

  void _emit() => _controller.add(snapshot);

  Future<void> start() async {
    await _load();
    _sub ??= _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) drain();
    });
    // Kick a drain attempt at startup.
    unawaited(drain());
  }

  Future<void> enqueue(QueuedItem q) async {
    await _load();
    _items.add(q);
    _emit();
    await _persist();
    unawaited(drain());
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    _emit();
    await _persist();
  }

  /// Resets any failed items back to pending and kicks a fresh drain.
  Future<void> retryAll() async {
    await _load();
    for (final q in _items) {
      if (q.status == QueuedStatus.failed) {
        q.status = QueuedStatus.pending;
        q.lastError = null;
      }
    }
    _emit();
    await _persist();
    await drain();
  }

  /// Drains pending items one at a time. Safe to call repeatedly.
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      await _load();
      for (final q in List<QueuedItem>.from(_items)) {
        if (q.status == QueuedStatus.done) continue;
        q.status = QueuedStatus.uploading;
        _emit();
        try {
          final file = await resolveFile(q);
          if (!await file.exists()) {
            throw WardrobeException('Local image missing: ${q.imagePath}');
          }
          final bytes = await file.readAsBytes();
          final storagePath = await _repo.uploadItemImage(bytes);
          await _repo.addItem(ItemModel(
            itemId: q.id,
            userId: q.userId,
            createdAt: DateTime.now(),
            imageUrl: storagePath,
            category: q.category,
            primaryHex: q.primaryHex,
            purchasePrice: q.purchasePrice,
          ));
          q.status = QueuedStatus.done;
          q.lastError = null;
          try {
            await file.delete();
          } catch (_) {}
          _items.removeWhere((e) => e.id == q.id);
          _emit();
          _ref.invalidate(itemsProvider);
          await _persist();
        } catch (e) {
          q.status = QueuedStatus.failed;
          q.lastError = e.toString();
          _emit();
          await _persist();
          // Continue to the next item — one bad item shouldn't block the batch.
          continue;
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}

final intakeQueueProvider = Provider<IntakeQueue>((ref) {
  final q = IntakeQueue(
    ref.watch(wardrobeRepositoryProvider),
    Connectivity(),
    ref,
  );
  unawaited(q.start());
  ref.onDispose(() => q.dispose());
  return q;
});

final intakeQueueStreamProvider = StreamProvider<List<QueuedItem>>((ref) {
  final q = ref.watch(intakeQueueProvider);
  return q.watch();
});
