import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/widgets/request_workspace.dart';

Widget _host({bool loading = false, Object? result, double textScale = 1}) =>
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: RequestWorkspace(
              loading: loading,
              result: result,
              requestBar: const SizedBox(height: 120, child: Text('URL bar')),
              editor: const TextField(
                decoration: InputDecoration(labelText: 'Draft body'),
              ),
              response: const Text('Response content'),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('mobile switching retains draft and gives each panel space', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host());
    await tester.enterText(find.byType(TextField), 'keep this draft');
    await tester.tap(find.text('Response'));
    await tester.pumpAndSettle();
    expect(find.text('Response content'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Request'));
    await tester.pumpAndSettle();
    expect(find.text('keep this draft'), findsOneWidget);
    expect(tester.getSize(find.byType(IndexedStack)).height, greaterThan(500));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'send and validation results reveal response but editing remains available',
    (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpWidget(_host(loading: true));
      await tester.pump();
      expect(find.text('Response content'), findsOneWidget);
      await tester.tap(find.text('Request'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.pumpWidget(_host(result: 'Invalid URL'));
      await tester.pump();
      expect(find.text('Response content'), findsOneWidget);
    },
  );

  testWidgets('wide layout keeps both panels and retains draft across resize', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host());
    await tester.enterText(find.byType(TextField), 'resize draft');
    tester.view.physicalSize = const Size(1000, 700);
    await tester.pumpAndSettle();
    expect(find.text('Response content'), findsOneWidget);
    expect(find.text('resize draft'), findsOneWidget);
    expect(find.byType(IndexedStack), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short keyboard viewport and large text do not overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final size in [const Size(320, 480), const Size(667, 180)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(_host(textScale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    }
  });
}
