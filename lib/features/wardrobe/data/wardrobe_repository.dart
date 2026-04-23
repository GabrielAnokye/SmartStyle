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
}
