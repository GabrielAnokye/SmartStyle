import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartstyle/core/services/supabase_service.dart';
import 'package:smartstyle/core/utils/media_processing_service.dart';
import 'package:smartstyle/features/wardrobe/data/wardrobe_repository.dart';
import 'package:smartstyle/features/wardrobe/domain/item_model.dart';
import 'package:uuid/uuid.dart';

class ManualIntakeScreen extends ConsumerStatefulWidget {
  const ManualIntakeScreen({super.key});

  @override
  ConsumerState<ManualIntakeScreen> createState() => _ManualIntakeScreenState();
}

class _ManualIntakeScreenState extends ConsumerState<ManualIntakeScreen> {
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  Uint8List? _imageBytes;
  String _primaryHex = '#808080';
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isProcessing = true);
    try {
      final compressed = await MediaProcessingService.compressImage(pickedFile);
      if (compressed != null) {
        final hex = await MediaProcessingService.extractDominantColor(compressed);
        setState(() {
          _imageBytes = compressed;
          _primaryHex = hex;
        });
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveItem() async {
    if (_imageBytes == null) return;
    if (_categoryController.text.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(wardrobeRepositoryProvider);
      final userId = ref.read(supabaseClientProvider).auth.currentUser!.id;
      
      final imageUrl = await repo.uploadItemImage(_imageBytes!);
      
      final item = ItemModel(
        itemId: const Uuid().v4(),
        userId: userId,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        category: _categoryController.text.trim(),
        primaryHex: _primaryHex,
        purchasePrice: double.tryParse(_priceController.text),
      );

      await repo.addItem(item);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item stored safely in the cloud!')));
        // reset form
        setState(() {
          _imageBytes = null;
          _categoryController.clear();
          _priceController.clear();
          _primaryHex = '#808080';
        });
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate valid hex wrapper for border preview. Ensure we strip out any alpha if present falsely.
    final colorVal = int.tryParse(_primaryHex.replaceFirst('#', 'FF'), radix: 16) ?? 0xFF808080;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(colorVal), width: 6),
                ),
                child: _imageBytes != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to snap or select photo', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _categoryController, 
              decoration: const InputDecoration(labelText: 'Category (e.g. Jacket, T-Shirt, Jeans)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController, 
              decoration: const InputDecoration(labelText: 'Purchase Price (\$)', border: OutlineInputBorder()), 
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      onPressed: (_imageBytes != null) ? _saveItem : null, 
                      label: const Text('Save to Closet', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                    ),
            ),
          ],
        ),
      )
    );
  }
}
