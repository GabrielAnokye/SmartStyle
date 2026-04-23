import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartstyle/core/services/supabase_service.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository(ref.watch(supabaseClientProvider));
});

class WardrobeRepository {
  final SupabaseClient _supabase;

  WardrobeRepository(this._supabase);

  Future<List<ItemModel>> getItems() async {
    final response = await _supabase.from('items').select().order('created_at', ascending: false);
    return (response as List).map((json) => ItemModel.fromJson(json)).toList();
  }

  Future<ItemModel> addItem(ItemModel item) async {
    final response = await _supabase.from('items').insert(item.toJson()).select().single();
    return ItemModel.fromJson(response);
  }

  Future<void> updateItem(ItemModel item) async {
    await _supabase.from('items').update(item.toJson()).eq('item_id', item.itemId);
  }

  Future<void> deleteItem(String itemId) async {
    await _supabase.from('items').delete().eq('item_id', itemId);
  }

  Future<String> uploadItemImage(Uint8List bytes) async {
    final userId = _supabase.auth.currentUser!.id;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';
    
    await _supabase.storage.from('wardrobe').uploadBinary(
      path, 
      bytes, 
      fileOptions: const FileOptions(contentType: 'image/jpeg')
    );
    
    return _supabase.storage.from('wardrobe').getPublicUrl(path);
  }
}
