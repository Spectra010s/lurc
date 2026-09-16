import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/app.dart';

void main() {
  testWidgets('Lurc app loads', (tester) async {
    await tester.pumpWidget(const LurcApp());

    expect(find.text('Lurc'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });
}
