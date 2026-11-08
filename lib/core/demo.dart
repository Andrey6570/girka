import 'dart:math' as math;

import 'analytics.dart' show kcalPerKg;
import 'models.dart';

/// Демо-данные: 10 недель с дефицитом около 400 ккал в день. Расход «в жизни» 2300 ккал.
List<DayEntry> demoEntries(DateTime today, {int days = 70, int seed = 7}) {
  final rnd = math.Random(seed);
  final out = <DayEntry>[];
  var trueWeight = 78.4;
  const expenditure = 2300.0;
  for (var i = days; i >= 0; i--) {
    final d = today.subtract(Duration(days: i));
    final isToday = i == 0;
    final intake = 1900 + (rnd.nextDouble() - 0.5) * 300;
    trueWeight += (intake - expenditure) / kcalPerKg;
    final weighed = rnd.nextDouble() < 0.8;
    out.add(DayEntry(
      date: fmtDate(d),
      weightKg: weighed ? double.parse((trueWeight + (rnd.nextDouble() - 0.5) * 0.8).toStringAsFixed(1)) : null,
      kcal: isToday ? 640 : intake.roundToDouble(),
      proteinG: isToday ? 48 : (115 + rnd.nextDouble() * 20).roundToDouble(),
      carbsG: isToday ? 70 : (190 + rnd.nextDouble() * 40).roundToDouble(),
      fatG: isToday ? 22 : (60 + rnd.nextDouble() * 15).roundToDouble(),
      steps: isToday ? 2400 : (6500 + rnd.nextDouble() * 4000).round(),
      workouts: i % 7 == 1 || i % 7 == 3 || i % 7 == 5 ? 1 : 0,
      closed: !isToday,
      cycleStart: i % 28 == 10,
    ));
  }
  return out;
}
