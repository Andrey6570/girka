import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/analytics.dart';
import '../core/csv_import.dart';
import '../core/demo.dart';
import '../core/models.dart';

/// Состояние приложения. Все данные хранятся только на устройстве.
class AppState extends ChangeNotifier {
  AppState({this._today, this._prefs});

  static const _key = 'girka.v1';

  final DateTime? _today;
  SharedPreferences? _prefs;

  final Map<String, DayEntry> _days = {};
  Profile profile = const Profile();

  /// null — язык системы.
  String? lang;
  bool loaded = false;

  DateTime get today => _today ?? dateOnly(DateTime.now());

  List<DayEntry> get entries {
    final l = _days.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    return l;
  }

  DayEntry? entryFor(DateTime d) => _days[fmtDate(d)];

  double? get latestWeight {
    for (final e in entries.reversed) {
      if (e.weightKg != null) return e.weightKg;
    }
    return null;
  }

  Future<void> load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_key);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        profile = Profile.fromJson((j['profile'] as Map?)?.cast<String, dynamic>() ?? {});
        lang = j['lang'] as String?;
        for (final e in (j['days'] as List? ?? [])) {
          final d = DayEntry.fromJson((e as Map).cast<String, dynamic>());
          _days[d.date] = d;
        }
      }
    } catch (_) {
      // Повреждённое хранилище не должно ронять приложение: начинаем с пустого.
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      await _prefs?.setString(
        _key,
        jsonEncode({
          'profile': profile.toJson(),
          'lang': lang,
          'days': entries.map((e) => e.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void saveDay(DayEntry e) {
    _days[e.date] = e;
    _changed();
  }

  void deleteDay(String date) {
    _days.remove(date);
    _changed();
  }

  void setProfile(Profile p) {
    profile = p;
    _changed();
  }

  void setLang(String? l) {
    lang = l;
    _changed();
  }

  /// Возвращает число затронутых дней. Ручные значения не перезаписываются.
  int merge(Iterable<DayEntry> incoming) {
    var n = 0;
    for (final e in incoming) {
      final cur = _days[e.date];
      _days[e.date] = cur == null ? e : cur.fillMissing(e);
      n++;
    }
    _changed();
    return n;
  }

  void loadDemo() {
    _days.clear();
    for (final e in demoEntries(today)) {
      _days[e.date] = e;
    }
    profile = profile.copyWith(trackCycle: true);
    _changed();
  }

  void clear() {
    _days.clear();
    _changed();
  }

  String csv() => exportCsv(entries);

  ImportResult importText(String text) {
    final r = importCsv(text);
    merge(r.entries);
    return r;
  }

  // Производные значения для экрана.
  RateEstimate get rate => weightRate(entries, today);
  EnergyEstimate get energy => energyEstimate(entries, today);
  MacroTargets? get targets => macroTargets(profile, energy, latestWeight);
  Insight get insight => dailyInsight(entries, profile, today);
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
