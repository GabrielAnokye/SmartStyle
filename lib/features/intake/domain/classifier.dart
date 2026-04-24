import 'dart:typed_data';

class ClassifierResult {
  final String? category;
  final double confidence;
  final List<String> rawLabels;

  const ClassifierResult({
    this.category,
    this.confidence = 0.0,
    this.rawLabels = const [],
  });

  bool get isLowConfidence => confidence < 0.6;
}

/// Maps images → wardrobe category.
/// MVP implementation uses ML Kit's generic labeler + a lookup table.
/// Post-launch we swap in a TFLite DeepFashion2 model behind this same interface.
abstract class Classifier {
  Future<ClassifierResult> classify(Uint8List bytes);

  Future<void> dispose();
}
