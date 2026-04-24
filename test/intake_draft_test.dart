import 'package:flutter_test/flutter_test.dart';
import 'package:smartstyle/features/intake/domain/intake_draft.dart';

void main() {
  group('IntakeDraft', () {
    test('effectiveCategory prefers user override', () {
      final d = IntakeDraft(id: '1', rawImagePath: '/tmp/a.jpg')
        ..suggestedCategory = 'shirt'
        ..userCategory = 'jacket';
      expect(d.effectiveCategory, 'jacket');
    });

    test('effectiveCategory falls back to suggested', () {
      final d = IntakeDraft(id: '1', rawImagePath: '/tmp/a.jpg')
        ..suggestedCategory = 'shirt';
      expect(d.effectiveCategory, 'shirt');
    });

    test('effectiveCategory uses uncategorized when nothing set', () {
      final d = IntakeDraft(id: '1', rawImagePath: '/tmp/a.jpg');
      expect(d.effectiveCategory, 'uncategorized');
    });

    test('timeToConfirmMs measures display→save', () async {
      final d = IntakeDraft(id: '1', rawImagePath: '/tmp/a.jpg',
          displayedAt: DateTime.now().subtract(const Duration(milliseconds: 800)));
      d.savedAt = DateTime.now();
      expect(d.timeToConfirmMs, greaterThanOrEqualTo(700));
      expect(d.timeToConfirmMs, lessThan(2000));
    });

    test('timeToConfirmMs is null before save', () {
      final d = IntakeDraft(id: '1', rawImagePath: '/tmp/a.jpg');
      expect(d.timeToConfirmMs, isNull);
    });
  });
}
