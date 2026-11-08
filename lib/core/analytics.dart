import 'dart:math' as math;

import 'models.dart';

/// Энергия в 1 кг массы тела: грубое допущение, поэтому расход помечается оценкой.
const kcalPerKg = 7700.0;

const minKcalFemale = 1200.0;
const minKcalMale = 1500.0;

class TrendPoint {
  const TrendPoint(this.date, this.weight, this.trend);
  final DateTime date;
  final double weight;
  final double trend;
}

/// Экспоненциальное сглаживание с учётом пропусков между взвешиваниями.
List<TrendPoint> trendSeries(List<DayEntry> entries, {double alpha = 0.1}) {
  final out = <TrendPoint>[];
  double? trend;
  DateTime? prev;
  for (final e in entries) {
    final w = e.weightKg;
    if (w == null) continue;
    final d = e.day;
    if (trend == null) {
      trend = w;
    } else {
      final gap = math.max(1, daysBetween(prev!, d));
      final a = 1 - math.pow(1 - alpha, gap).toDouble();
      trend = trend + a * (w - trend);
    }
    prev = d;
    out.add(TrendPoint(d, w, trend));
  }
  return out;
}

class RateEstimate {
  const RateEstimate({
    required this.kgPerWeek,
    required this.pctPerWeek,
    required this.points,
    required this.spanDays,
    required this.confidence,
  });

  /// Знак: минус означает снижение.
  final double? kgPerWeek;
  final double? pctPerWeek;
  final int points;
  final int spanDays;
  final Confidence confidence;

  bool get available => kgPerWeek != null;
}

/// Наклон линейной регрессии веса за [windowDays] дней, оканчивающихся в [end] (включительно).
RateEstimate weightRate(List<DayEntry> entries, DateTime end, {int windowDays = 28}) {
  final start = end.subtract(Duration(days: windowDays - 1));
  final pts = <(double, double)>[];
  for (final e in entries) {
    final w = e.weightKg;
    final d = e.day;
    if (w == null || d.isBefore(start) || d.isAfter(end)) continue;
    pts.add((daysBetween(start, d).toDouble(), w));
  }
  final span = pts.length < 2 ? 0 : (pts.last.$1 - pts.first.$1).round();
  if (pts.length < 3 || span < 7) {
    return RateEstimate(
      kgPerWeek: null,
      pctPerWeek: null,
      points: pts.length,
      spanDays: span,
      confidence: Confidence.low,
    );
  }
  final n = pts.length;
  final mx = pts.fold<double>(0, (s, p) => s + p.$1) / n;
  final my = pts.fold<double>(0, (s, p) => s + p.$2) / n;
  var sxy = 0.0, sxx = 0.0;
  for (final p in pts) {
    sxy += (p.$1 - mx) * (p.$2 - my);
    sxx += (p.$1 - mx) * (p.$1 - mx);
  }
  final slope = sxx == 0 ? 0.0 : sxy / sxx;
  final conf = n >= 10 && span >= 21
      ? Confidence.high
      : n >= 6 && span >= 14
          ? Confidence.medium
          : Confidence.low;
  return RateEstimate(
    kgPerWeek: slope * 7,
    pctPerWeek: slope * 7 / my * 100,
    points: n,
    spanDays: span,
    confidence: conf,
  );
}

class EnergyEstimate {
  const EnergyEstimate({
    required this.expenditureKcal,
    required this.avgIntakeKcal,
    required this.intakeDays,
    required this.confidence,
  });

  final double? expenditureKcal;
  final double? avgIntakeKcal;
  final int intakeDays;
  final Confidence confidence;
}

/// Фактический расход энергии = средний приём − (изменение веса × 7700 / день).
/// Окно: 28 дней до вчерашнего. Считаются только закрытые дни с питанием.
EnergyEstimate energyEstimate(List<DayEntry> entries, DateTime today) {
  final end = today.subtract(const Duration(days: 1));
  final start = end.subtract(const Duration(days: 27));
  final intake = <double>[];
  for (final e in entries) {
    final d = e.day;
    if (d.isBefore(start) || d.isAfter(end)) continue;
    final k = e.kcal;
    if (e.closed && k != null && k > 0) intake.add(k);
  }
  final avg = intake.isEmpty ? null : intake.reduce((a, b) => a + b) / intake.length;
  final rate = weightRate(entries, end);
  if (avg == null || intake.length < 10 || !rate.available || rate.confidence == Confidence.low) {
    return EnergyEstimate(
      expenditureKcal: null,
      avgIntakeKcal: avg,
      intakeDays: intake.length,
      confidence: Confidence.low,
    );
  }
  final expenditure = avg - rate.kgPerWeek! / 7 * kcalPerKg;
  final conf = intake.length >= 21 && rate.confidence == Confidence.high
      ? Confidence.high
      : Confidence.medium;
  return EnergyEstimate(
    expenditureKcal: expenditure,
    avgIntakeKcal: avg,
    intakeDays: intake.length,
    confidence: conf,
  );
}

/// Оценка по формуле Миффлина — Сан Жеора с умеренной активностью. Только запасной вариант.
double formulaExpenditure(Profile p, double weightKg) {
  final bmr = 10 * weightKg + 6.25 * p.heightCm - 5 * p.age + (p.sex == Sex.male ? 5 : -161);
  return bmr * 1.4;
}

class MacroTargets {
  const MacroTargets({
    required this.kcal,
    required this.proteinMinG,
    required this.proteinMaxG,
    required this.fatG,
    required this.carbsG,
    required this.fromMeasured,
    required this.floorApplied,
  });

  final int kcal;
  final int proteinMinG;
  final int proteinMaxG;
  final int fatG;
  final int carbsG;

  /// true — цель построена на фактическом расходе, false — на формуле.
  final bool fromMeasured;

  /// Цель подтянута к нижней границе калорий.
  final bool floorApplied;

  int get proteinG => ((proteinMinG + proteinMaxG) / 2).round();
}

MacroTargets? macroTargets(Profile p, EnergyEstimate energy, double? weightKg) {
  if (weightKg == null) return null;
  final measured = energy.expenditureKcal;
  final expenditure = measured ?? formulaExpenditure(p, weightKg);
  final sign = switch (p.goal) {
    Goal.lose => -1.0,
    Goal.maintain => 0.0,
    Goal.gain => 1.0,
  };
  final rate = p.ratePctPerWeek.clamp(0.25, 1.0);
  final delta = sign * weightKg * rate / 100 * kcalPerKg / 7;
  final floor = p.sex == Sex.male ? minKcalMale : minKcalFemale;
  var kcal = expenditure + delta;
  var floored = false;
  if (kcal < floor) {
    kcal = floor;
    floored = true;
  }
  final protein = (weightKg * 1.8).clamp(0, kcal * 0.4 / 4);
  final fat = kcal * 0.27 / 9;
  final carbs = math.max(0.0, (kcal - protein * 4 - fat * 9) / 4);
  return MacroTargets(
    kcal: kcal.round(),
    proteinMinG: math.min((weightKg * 1.6).round(), protein.round()),
    proteinMaxG: math.min((weightKg * 2.2).round(), (kcal * 0.4 / 4).round()),
    fatG: fat.round(),
    carbsG: carbs.round(),
    fromMeasured: measured != null,
    floorApplied: floored,
  );
}

enum InsightCode {
  addData,
  needWeighins,
  closeDays,
  onTrack,
  tooFast,
  tooSlow,
  wrongDirection,
  stable,
  maintainDrift,
}

class Insight {
  const Insight(this.code, {this.n, this.v});
  final InsightCode code;
  final int? n;
  final double? v;
}

/// Одна главная мысль на день. Правила идут по приоритету.
Insight dailyInsight(List<DayEntry> entries, Profile p, DateTime today) {
  if (entries.isEmpty) return const Insight(InsightCode.addData);
  final rate = weightRate(entries, today);
  if (!rate.available) {
    final need = math.max(1, 3 - rate.points);
    return Insight(InsightCode.needWeighins, n: need);
  }
  final energy = energyEstimate(entries, today);
  if (energy.intakeDays < 7) {
    return Insight(InsightCode.closeDays, n: 7 - energy.intakeDays);
  }
  final pct = rate.pctPerWeek!;
  switch (p.goal) {
    case Goal.lose:
      if (pct > 0.1) return Insight(InsightCode.wrongDirection, v: pct);
      final loss = -pct;
      if (loss > 1.0) return Insight(InsightCode.tooFast, v: loss);
      if (loss < p.ratePctPerWeek * 0.4 && rate.confidence != Confidence.low) {
        return Insight(InsightCode.tooSlow, v: loss);
      }
      return Insight(InsightCode.onTrack, v: loss);
    case Goal.gain:
      if (pct < -0.1) return Insight(InsightCode.wrongDirection, v: pct);
      if (pct > 0.5) return Insight(InsightCode.tooFast, v: pct);
      return Insight(InsightCode.onTrack, v: pct);
    case Goal.maintain:
      if (pct.abs() > 0.3) return Insight(InsightCode.maintainDrift, v: pct);
      return Insight(InsightCode.stable, v: pct);
  }
}

/// Дни цикла по подтверждённым началам менструации, без прогноза.
class Cycle {
  Cycle(List<DayEntry> entries)
      : starts = (entries.where((e) => e.cycleStart).map((e) => e.day).toSet().toList()..sort());

  final List<DateTime> starts;

  DateTime? currentStart(DateTime date) {
    DateTime? r;
    for (final s in starts) {
      if (!s.isAfter(date)) r = s;
    }
    return r;
  }

  int? dayOf(DateTime date) {
    final s = currentStart(date);
    return s == null ? null : daysBetween(s, date) + 1;
  }

  /// Тот же день предыдущего цикла. null, если такого дня не было (цикл короче).
  DateTime? sameDayPrevious(DateTime date) {
    final cur = currentStart(date);
    if (cur == null) return null;
    final i = starts.indexOf(cur);
    if (i == 0) return null;
    final prevStart = starts[i - 1];
    final d = prevStart.add(Duration(days: daysBetween(cur, date)));
    return d.isBefore(cur) ? d : null;
  }
}

class CycleComparison {
  const CycleComparison(this.cycleDay, this.diffKg);
  final int cycleDay;
  final double diffKg;
}

/// Среднее за 3 дня до сегодняшнего дня цикла против тех же дней прошлого цикла.
CycleComparison? compareWithPreviousCycle(List<DayEntry> entries, Cycle cycle, DateTime today) {
  final day = cycle.dayOf(today);
  final prev = cycle.sameDayPrevious(today);
  if (day == null || prev == null) return null;
  double? mean(DateTime end) {
    final from = end.subtract(const Duration(days: 2));
    final ws = [
      for (final e in entries)
        if (e.weightKg != null && !e.day.isBefore(from) && !e.day.isAfter(end)) e.weightKg!
    ];
    return ws.length < 2 ? null : ws.reduce((a, b) => a + b) / ws.length;
  }

  final a = mean(today);
  final b = mean(prev);
  if (a == null || b == null) return null;
  return CycleComparison(day, a - b);
}
