import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/app.dart';

void main() {
  testWidgets('Lurc app loads', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LurcApp()),
    );

    expect(find.text('Lurc'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });
}
