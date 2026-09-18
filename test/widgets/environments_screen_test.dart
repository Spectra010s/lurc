import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurc/core/environments/environment_controller.dart';
import 'package:lurc/screens/environments/environments_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('creates edits selects and deletes an environment', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: EnvironmentsScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.text('No environments yet'), findsOneWidget);
    await tester.tap(find.text('Environment'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Development');
    await tester.enterText(find.byType(TextField).at(1), 'host');
    await tester.enterText(find.byType(TextField).at(2), 'https://example.com');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Development'), findsOneWidget);
    expect(find.text('1 variable • Active'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EnvironmentsScreen)),
    );
    final selection = container.read(activeEnvironmentIdProvider.notifier);
    selection.selectedId = null;
    await tester.pumpAndSettle();
    await tester.tap(find.text('Development'));
    await tester.pumpAndSettle();
    expect(container.read(activeEnvironmentProvider)?.variables, {
      'host': 'https://example.com',
    });

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('https://example.com'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Production');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Production'), findsOneWidget);
    expect(container.read(activeEnvironmentProvider)?.name, 'Production');

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('No environments yet'), findsOneWidget);
    expect(container.read(activeEnvironmentIdProvider), isNull);
    expect(tester.takeException(), isNull);
  });
}
