import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartstyle/features/intake/domain/classifier.dart';

/// Maps ML Kit's generic image labels to our wardrobe category taxonomy.
/// This is the fallback-first strategy; a TFLite classifier can later
/// replace this implementation with zero caller changes.
const Map<String, String> _labelToCategory = {
  // tops
  't-shirt': 'tops',
  'shirt': 'tops',
  'blouse': 'tops',
  'top': 'tops',
  'sweater': 'tops',
  'hoodie': 'tops',
  // outerwear
  'jacket': 'outerwear',
  'coat': 'outerwear',
  'blazer': 'outerwear',
  'parka': 'outerwear',
  // bottoms
  'jeans': 'bottoms',
  'pants': 'bottoms',
  'trousers': 'bottoms',
  'shorts': 'bottoms',
  'skirt': 'bottoms',
  // dresses
  'dress': 'dresses',
  'gown': 'dresses',
  // shoes
  'shoe': 'shoes',
  'sneaker': 'shoes',
  'boot': 'shoes',
  'sandal': 'shoes',
  'footwear': 'shoes',
  // accessories
  'hat': 'accessories',
  'cap': 'accessories',
  'scarf': 'accessories',
  'belt': 'accessories',
  'bag': 'accessories',
  'handbag': 'accessories',
  'sunglasses': 'accessories',
};

String? _mapLabel(String rawLabel) {
  final lower = rawLabel.toLowerCase();
  if (_labelToCategory.containsKey(lower)) return _labelToCategory[lower];
  for (final entry in _labelToCategory.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}

class MlKitLabelClassifier implements Classifier {
  final ImageLabeler _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );

  @override
  Future<ClassifierResult> classify(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/label_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes);

      final input = InputImage.fromFilePath(file.path);
      final labels = await _labeler.processImage(input);

      String? bestCategory;
      double bestConf = 0;
      final raw = <String>[];
      for (final l in labels) {
        raw.add('${l.label}:${l.confidence.toStringAsFixed(2)}');
        final mapped = _mapLabel(l.label);
        if (mapped != null && l.confidence > bestConf) {
          bestCategory = mapped;
          bestConf = l.confidence;
        }
      }
      return ClassifierResult(
        category: bestCategory,
        confidence: bestConf,
        rawLabels: raw,
      );
    } catch (e, st) {
      debugPrint('MlKitLabelClassifier failure: $e\n$st');
      return const ClassifierResult();
    }
  }

  @override
  Future<void> dispose() => _labeler.close();
}
