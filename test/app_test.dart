import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girka/data/app_state.dart';
import 'package:girka/ui/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fonts.dart';

Future<AppState> _boot(WidgetTester tester, {String lang = 'en'}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final st = AppState(today: DateTime.utc(2026, 11, 8));
  await st.load();
  st.setLang(lang);
  await tester.pumpWidget(GirkaApp(state: st));
  await tester.pumpAndSettle();
  return st;
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets('empty state offers demo, demo fills the home screen', (tester) async {
    final st = await _boot(tester);
    expect(find.text('Let us start with data'), findsOneWidget);
    await tester.tap(find.text('Try the demo'));
    await tester.pumpAndSettle();
    expect(st.entries, isNotEmpty);
    expect(find.text('Plan for today'), findsOneWidget);
    expect(find.text('Week rhythm', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tabs switch and render without errors', (tester) async {
    final st = await _boot(tester);
    st.loadDemo();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress').last);
    await tester.pumpAndSettle();
    expect(find.text('Weight and trend'), findsOneWidget);
    expect(find.text('Energy expenditure'), findsOneWidget);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Import from CSV'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('logging a day saves it and persists', (tester) async {
    final st = await _boot(tester);
    await tester.tap(find.text('Log a day'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Weight'), '71,5');
    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '1800');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final e = st.entryFor(st.today);
    expect(e?.weightKg, 71.5);
    expect(e?.kcal, 1800);

    final again = AppState(today: st.today);
    await again.load();
    expect(again.entryFor(again.today)?.weightKg, 71.5);
  });

  testWidgets('Russian strings are used when selected', (tester) async {
    await _boot(tester, lang: 'ru');
    expect(find.text('Начнём с данных'), findsOneWidget);
  });

  testWidgets('corrupt storage does not crash the app', (tester) async {
    SharedPreferences.setMockInitialValues({'girka.v1': '{not json'});
    final st = AppState(today: DateTime.utc(2026, 11, 8));
    await st.load();
    expect(st.loaded, isTrue);
    expect(st.entries, isEmpty);
  });
}
