import 'models.dart';

class ImportResult {
  const ImportResult({
    required this.entries,
    required this.rows,
    required this.skipped,
    required this.columns,
  });

  final List<DayEntry> entries;
  final int rows;
  final int skipped;

  /// Какие поля нашлись в заголовке: date, weight, kcal, protein, carbs, fat, steps.
  final Set<String> columns;
}

const _synonyms = <String, List<String>>{
  'date': ['date', 'дата', 'день', 'day'],
  'weight': ['weight', 'вес', 'body weight', 'масса'],
  'kcal': ['calories', 'calorie', 'kcal', 'energy', 'ккал', 'калории', 'энергия'],
  'protein': ['protein', 'белки', 'белок'],
  'carbs': ['carbs', 'carbohydrate', 'углеводы'],
  'fat': ['fat', 'жиры', 'жир'],
  'steps': ['steps', 'шаги'],
};

List<List<String>> parseCsvRows(String text) {
  final src = text.startsWith('﻿') ? text.substring(1) : text;
  final firstLine = src.split('\n').first;
  final delim = [';', '\t', ',']
      .map((d) => (d, d.allMatches(firstLine).length))
      .reduce((a, b) => b.$2 > a.$2 ? b : a)
      .$1;
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  void endCell() {
    row.add(cell.toString().trim());
    cell.clear();
  }

  void endRow() {
    endCell();
    if (row.any((c) => c.isNotEmpty)) rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < src.length; i++) {
    final c = src[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < src.length && src[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == delim) {
      endCell();
    } else if (c == '\n') {
      endRow();
    } else if (c != '\r') {
      cell.write(c);
    }
  }
  endRow();
  return rows;
}

String? _field(String header) {
  final h = header.toLowerCase().replaceAll(RegExp(r'\(.*?\)'), '').trim();
  for (final e in _synonyms.entries) {
    for (final s in e.value) {
      if (h == s || h.contains(s)) return e.key;
    }
  }
  return null;
}

/// Поддерживает ISO (2026-10-28), 28.10.2026 и 10/28/2026.
DateTime? parseFlexibleDate(String s) {
  final t = s.trim().split(' ').first.split('T').first;
  var m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(t);
  int y, mo, d;
  if (m != null) {
    y = int.parse(m[1]!);
    mo = int.parse(m[2]!);
    d = int.parse(m[3]!);
  } else {
    m = RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{2,4})$').firstMatch(t);
    if (m == null) return null;
    var a = int.parse(m[1]!);
    var b = int.parse(m[2]!);
    y = int.parse(m[3]!);
    if (y < 100) y += 2000;
    final slash = t.contains('/');
    if (slash && a <= 12) {
      mo = a;
      d = b;
    } else {
      d = a;
      mo = b;
    }
  }
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  final r = DateTime.utc(y, mo, d);
  return r.month == mo ? r : null;
}

double? _num(String s) {
  final t = s.trim().replaceAll(RegExp(r'[^0-9,.\-]'), '').replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

/// Универсальный разбор CSV из дневников питания и весов.
/// Строки с одной датой складываются (питание по приёмам пищи), вес берётся последний.
/// Дни с калориями считаются закрытыми: в экспорте приходит итог дня.
ImportResult importCsv(String text) {
  final rows = parseCsvRows(text);
  if (rows.length < 2) {
    return const ImportResult(entries: [], rows: 0, skipped: 0, columns: {});
  }
  final cols = <int, String>{};
  for (var i = 0; i < rows.first.length; i++) {
    final f = _field(rows.first[i]);
    if (f != null && !cols.containsValue(f)) cols[i] = f;
  }
  if (!cols.containsValue('date')) {
    return ImportResult(entries: const [], rows: rows.length - 1, skipped: rows.length - 1, columns: cols.values.toSet());
  }
  final byDate = <String, Map<String, double>>{};
  var skipped = 0;
  for (final r in rows.skip(1)) {
    DateTime? date;
    final vals = <String, double>{};
    cols.forEach((i, f) {
      if (i >= r.length) return;
      if (f == 'date') {
        date = parseFlexibleDate(r[i]);
      } else {
        final v = _num(r[i]);
        if (v != null) vals[f] = v;
      }
    });
    if (date == null) {
      skipped++;
      continue;
    }
    final acc = byDate.putIfAbsent(fmtDate(date!), () => {});
    for (final e in vals.entries) {
      if (e.key == 'weight') {
        acc['weight'] = e.value;
      } else {
        acc[e.key] = (acc[e.key] ?? 0) + e.value;
      }
    }
  }
  final out = <DayEntry>[];
  for (final e in byDate.entries) {
    final v = e.value;
    final w = v['weight'];
    final k = v['kcal'];
    out.add(DayEntry(
      date: e.key,
      weightKg: w != null && w > 20 && w < 400 ? w : null,
      kcal: k != null && k > 0 ? k : null,
      proteinG: v['protein'],
      carbsG: v['carbs'],
      fatG: v['fat'],
      steps: v['steps']?.round(),
      closed: k != null && k > 0,
    ));
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return ImportResult(entries: out, rows: rows.length - 1, skipped: skipped, columns: cols.values.toSet());
}

String exportCsv(List<DayEntry> entries) {
  final b = StringBuffer('date,weight_kg,kcal,protein_g,carbs_g,fat_g,steps,workouts,day_closed,cycle_start\n');
  String n(num? v) => v == null ? '' : (v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1));
  for (final e in entries) {
    b.writeln([
      e.date,
      n(e.weightKg),
      n(e.kcal),
      n(e.proteinG),
      n(e.carbsG),
      n(e.fatG),
      n(e.steps),
      e.workouts,
      e.closed ? 1 : 0,
      e.cycleStart ? 1 : 0,
    ].join(','));
  }
  return b.toString();
}
