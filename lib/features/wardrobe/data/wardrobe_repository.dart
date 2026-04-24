import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartstyle/core/services/supabase_service.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';

const int kMaxUploadBytes = 200 * 1024;
const int kSignedUrlTtlSeconds = 60 * 60;

class WardrobeException implements Exception {
  final String message;
  final Object? cause;
  WardrobeException(this.message, [this.cause]);
  @override
  String toString() => 'WardrobeException: $message';
}

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository(ref.watch(supabaseClientProvider));
});

class WardrobeRepository {
  final SupabaseClient _supabase;

  WardrobeRepository(this._supabase);

  String _requireUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw WardrobeException('Not signed in.');
    }
    return user.id;
  }

  Future<List<ItemModel>> getItems({
    int limit = 20,
    int offset = 0,
    String? categoryFilter,
    ItemState? stateFilter,
  }) async {
    try {
      _requireUserId();
      var query = _supabase.from('items').select();
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        query = query.eq('category', categoryFilter);
      }
      if (stateFilter != null) {
        query = query.eq('state', stateFilter.name);
      }
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (response as List)
          .map((json) => ItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw WardrobeException('Failed to load items: ${e.message}', e);
    }
  }

  Future<ItemModel> getItem(String itemId) async {
    try {
      _requireUserId();
      final response =
          await _supabase.from('items').select().eq('item_id', itemId).single();
      return ItemModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw WardrobeException('Failed to load item: ${e.message}', e);
    }
  }

  Future<ItemModel> addItem(ItemModel item) async {
    try {
      _requireUserId();
      final payload = Map<String, dynamic>.from(item.toJson())
        ..remove('cost_per_wear');
      final response =
          await _supabase.from('items').insert(payload).select().single();
      return ItemModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw WardrobeException('Failed to add item: ${e.message}', e);
    }
  }

  Future<ItemModel> updateItem(ItemModel item) async {
    try {
      _requireUserId();
      final payload = Map<String, dynamic>.from(item.toJson())
        ..remove('cost_per_wear')
        ..remove('item_id')
        ..remove('created_at')
        ..remove('user_id');
      final response = await _supabase
          .from('items')
          .update(payload)
          .eq('item_id', item.itemId)
          .select()
          .single();
      return ItemModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw WardrobeException('Failed to update item: ${e.message}', e);
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      _requireUserId();
      await _supabase.from('items').delete().eq('item_id', itemId);
    } on PostgrestException catch (e) {
      throw WardrobeException('Failed to delete item: ${e.message}', e);
    }
  }

  /// Uploads a compressed image and returns its storage path (NOT a public URL).
  /// Enforces the 200KB budget at the upload boundary.
  Future<String> uploadItemImage(Uint8List bytes) async {
    if (bytes.lengthInBytes > kMaxUploadBytes) {
      throw WardrobeException(
          'Image exceeds ${kMaxUploadBytes ~/ 1024}KB limit (${bytes.lengthInBytes ~/ 1024}KB).');
    }
    final userId = _requireUserId();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';

    try {
      await _supabase.storage.from('wardrobe').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return path;
    } on StorageException catch (e) {
      throw WardrobeException('Upload failed: ${e.message}', e);
    }
  }

  /// Returns a signed URL for a stored image path. Bucket is private by design.
  Future<String> signedUrlFor(String path) async {
    try {
      return await _supabase.storage
          .from('wardrobe')
          .createSignedUrl(path, kSignedUrlTtlSeconds);
    } on StorageException catch (e) {
      throw WardrobeException('Could not sign URL: ${e.message}', e);
    }
  }

  Future<void> deleteItemImage(String path) async {
    try {
      await _supabase.storage.from('wardrobe').remove([path]);
    } on StorageException catch (e) {
      throw WardrobeException('Could not delete image: ${e.message}', e);
    }
  }

  /// Logs a wear event for each item and lets the Postgres trigger advance
  /// times_worn / last_worn_at / state. Client never updates those fields
  /// directly — the trigger is the source of truth.
  Future<void> logWear({
    required List<String> itemIds,
    DateTime? wornAt,
    String? outfitKey,
  }) async {
    if (itemIds.isEmpty) return;
    final userId = _requireUserId();
    final ts = (wornAt ?? DateTime.now().toUtc()).toIso8601String();
    final payload = itemIds
        .map((id) => {
              'user_id': userId,
              'item_id': id,
              'worn_at': ts,
              if (outfitKey != null) 'outfit_key': outfitKey,
            })
        .toList();
    try {
      await _supabase.from('wear_events').insert(payload);
    } on PostgrestException catch (e) {
      throw WardrobeException('Failed to log wear: ${e.message}', e);
    }
  }

  /// Explicit laundry-state transitions. The trigger handles the
  /// clean → worn → laundry path on wear; these cover the manual moves
  /// (mark dirty, mark clean after laundry day).
  Future<void> setState(String itemId, ItemState newState) async {
    try {
      _requireUserId();
      await _supabase
          .from('items')
          .update({'state': newState.name})
          .eq('item_id', itemId);
    } on PostgrestException catch (e) {
      throw WardrobeException('Failed to update state: ${e.message}', e);
    }
  }

  /// Bulk "laundry day is done" — flip every laundry-state item to clean.
  Future<int> markAllLaundryClean() async {
    try {
      final userId = _requireUserId();
      final rows = await _supabase
          .from('items')
          .update({'state': ItemState.clean.name})
          .eq('user_id', userId)
          .eq('state', ItemState.laundry.name)
          .select('item_id');
      return rows.length;
    } on PostgrestException catch (e) {
      throw WardrobeException('Failed to clear laundry: ${e.message}', e);
    } on AuthException catch (e) {
      throw WardrobeException('Auth error clearing laundry: ${e.message}', e);
    } catch (e) {
      throw WardrobeException('Failed to clear laundry: $e', e);
    }
  }
}
