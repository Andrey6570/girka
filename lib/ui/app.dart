import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/app_state.dart';
import '../l10n.dart';
import 'day_editor.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'today_screen.dart';

const _seed = Color(0xFF1F7A6B);

S strings(BuildContext context) => S.of(context, AppScope.of(context).lang);

class GirkaApp extends StatelessWidget {
  const GirkaApp({super.key, required this.state});

  final AppState state;

  ThemeData _theme(Brightness b) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: b),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0),
        visualDensity: VisualDensity.standard,
      );

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: Builder(builder: (context) {
        final lang = AppScope.of(context).lang;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Girka',
          locale: lang == null ? null : Locale(lang),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const Shell(),
        );
      }),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = strings(context);
    const pages = [TodayScreen(), ProgressScreen(), ProfileScreen()];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      floatingActionButton: _tab == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showDayEditor(context),
              icon: const Icon(Icons.add),
              label: Text(s('add')),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.today_outlined), selectedIcon: const Icon(Icons.today), label: s('today')),
          NavigationDestination(icon: const Icon(Icons.show_chart), label: s('progress')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: s('profile')),
        ],
      ),
    );
  }
}
