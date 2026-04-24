// Exercises the pure label→category mapping via the Classifier interface
// using a fake implementation. The real ML Kit classifier is integration-
// tested on-device; this test guards the contract + confidence threshold.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartstyle/features/intake/domain/classifier.dart';

class _FakeClassifier implements Classifier {
  final ClassifierResult result;
  _FakeClassifier(this.result);
  @override
  Future<ClassifierResult> classify(Uint8List bytes) async => result;
  @override
  Future<void> dispose() async {}
}

void main() {
  test('low-confidence flag trips below 0.6', () {
    const r = ClassifierResult(category: 'tops', confidence: 0.55);
    expect(r.isLowConfidence, isTrue);
  });

  test('high-confidence flag holds at 0.6+', () {
    const r = ClassifierResult(category: 'tops', confidence: 0.6);
    expect(r.isLowConfidence, isFalse);
  });

  test('fake classifier returns category through interface', () async {
    final c = _FakeClassifier(const ClassifierResult(
      category: 'outerwear',
      confidence: 0.9,
      rawLabels: ['jacket:0.90'],
    ));
    final got = await c.classify(Uint8List(0));
    expect(got.category, 'outerwear');
    expect(got.rawLabels, ['jacket:0.90']);
  });
}
