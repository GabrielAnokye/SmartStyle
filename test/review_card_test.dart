// Widget-level smoke test for the review card inputs. The real screen wires
// Supabase + Riverpod; this test exercises just the card form logic.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartstyle/features/intake/domain/intake_draft.dart';

class _HarnessCard extends StatefulWidget {
  final IntakeDraft draft;
  const _HarnessCard({required this.draft});
  @override
  State<_HarnessCard> createState() => _HarnessCardState();
}

class _HarnessCardState extends State<_HarnessCard> {
  late final TextEditingController _categoryCtrl =
      TextEditingController(text: widget.draft.effectiveCategory);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextField(
              key: const Key('category'),
              controller: _categoryCtrl,
              onChanged: (v) => widget.draft.userCategory = v,
            ),
            if (widget.draft.confidence != null && widget.draft.confidence! < 0.6)
              const Text('Unsure', key: Key('low-confidence')),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('pre-fills suggested category', (tester) async {
    final d = IntakeDraft(id: '1', rawImagePath: '/tmp/a.jpg')
      ..suggestedCategory = 'tops';
    await tester.pumpWidget(_HarnessCard(draft: d));
    expect(find.text('tops'), findsOneWidget);
  });

  testWidgets('user edit overrides suggested category', (tester) async {
    final d = IntakeDraft(id: '1', rawImagePath: '/tmp/a.jpg')
      ..suggestedCategory = 'tops';
    await tester.pumpWidget(_HarnessCard(draft: d));
    await tester.enterText(find.byKey(const Key('category')), 'outerwear');
    expect(d.userCategory, 'outerwear');
    expect(d.effectiveCategory, 'outerwear');
  });

  testWidgets('shows low-confidence hint when confidence<0.6', (tester) async {
    final d = IntakeDraft(id: '1', rawImagePath: '/tmp/a.jpg')
      ..suggestedCategory = 'tops'
      ..confidence = 0.3;
    await tester.pumpWidget(_HarnessCard(draft: d));
    expect(find.byKey(const Key('low-confidence')), findsOneWidget);
  });
}
