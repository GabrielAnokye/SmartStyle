import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstyle/features/intake/data/mlkit_label_classifier.dart';
import 'package:smartstyle/features/intake/data/mlkit_segmenter.dart';
import 'package:smartstyle/features/intake/domain/classifier.dart';
import 'package:smartstyle/features/intake/domain/segmenter.dart';

/// Fallback-first ML stack. Swap these `create` calls to a TFLite
/// implementation when the custom model is ready — no caller changes.
final segmenterProvider = Provider<Segmenter>((ref) {
  final s = MlKitSegmenter();
  ref.onDispose(() => s.dispose());
  return s;
});

final classifierProvider = Provider<Classifier>((ref) {
  final c = MlKitLabelClassifier();
  ref.onDispose(() => c.dispose());
  return c;
});
