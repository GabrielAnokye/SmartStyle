import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartstyle/main.dart';

void main() {
  testWidgets('Auth smoke test - should route to login when not authenticated', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartStyleApp()));
    await tester.pumpAndSettle();

    // Verify if it redirects to the SmartStyle Login
    expect(find.text('SmartStyle Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
