import 'package:flutter_test/flutter_test.dart';
import 'package:girka/core/analytics.dart';
import 'package:girka/core/csv_import.dart';
import 'package:girka/core/demo.dart';
import 'package:girka/core/models.dart';

void main() {
  final today = DateTime.utc(2026, 11, 8);

  group('weight trend', () {
    test('linear loss gives matching rate', () {
      final entries = [
        for (var i = 27; i >= 0; i--)
          DayEntry(date: fmtDate(today.subtract(Duration(days: i))), weightKg: 80 - (27 - i) * 0.05),
      ];
      final r = weightRate(entries, today);
      expect(r.kgPerWeek, closeTo(-0.35, 0.01));
      expect(r.pctPerWeek, closeTo(-0.45, 0.05));
      expect(r.confidence, Confidence.high);
    });

    test('too few weigh-ins gives no rate', () {
      final entries = [
        DayEntry(date: '2026-11-07', weightKg: 80),
        DayEntry(date: '2026-11-08', weightKg: 79.8),
      ];
      expect(weightRate(entries, today).available, isFalse);
    });

    test('trend handles gaps and lags the raw weight', () {
      final t = trendSeries([
        const DayEntry(date: '2026-11-01', weightKg: 80),
        const DayEntry(date: '2026-11-02', kcal: 2000),
        const DayEntry(date: '2026-11-05', weightKg: 79),
      ]);
      expect(t.length, 2);
      expect(t.last.trend, greaterThan(79));
      expect(t.last.trend, lessThan(80));
    });
  });

  group('energy', () {
    test('recovers the true expenditure from demo data', () {
      final e = energyEstimate(demoEntries(today), today);
      expect(e.expenditureKcal, isNotNull);
      expect(e.expenditureKcal!, closeTo(2300, 250));
      expect(e.confidence, isNot(Confidence.low));
    });

    test('open days and today are not counted', () {
      final entries = [
        for (var i = 20; i >= 0; i--)
          DayEntry(date: fmtDate(today.subtract(Duration(days: i))), weightKg: 70, kcal: 2000, closed: i != 3),
      ];
      expect(energyEstimate(entries, today).intakeDays, 19);
    });

    test('without data falls back to formula and marks it', () {
      const p = Profile();
      final t = macroTargets(p, const EnergyEstimate(expenditureKcal: null, avgIntakeKcal: null, intakeDays: 0, confidence: Confidence.low), 70)!;
      expect(t.fromMeasured, isFalse);
      expect(t.kcal, greaterThan(1200));
    });
  });

  group('targets', () {
    const energy = EnergyEstimate(expenditureKcal: 1500, avgIntakeKcal: 1500, intakeDays: 20, confidence: Confidence.high);

    test('calorie floor is applied and reported', () {
      final t = macroTargets(const Profile(), energy, 90)!;
      expect(t.kcal, 1200);
      expect(t.floorApplied, isTrue);
    });

    test('maintain keeps expenditure, macros add up', () {
      const e = EnergyEstimate(expenditureKcal: 2400, avgIntakeKcal: 2400, intakeDays: 20, confidence: Confidence.high);
      final t = macroTargets(const Profile(goal: Goal.maintain), e, 75)!;
      expect(t.kcal, 2400);
      final sum = t.proteinG * 4 + t.carbsG * 4 + t.fatG * 9;
      expect((sum - t.kcal).abs(), lessThan(40));
      expect(t.proteinMinG, lessThanOrEqualTo(t.proteinMaxG));
    });
  });

  group('insight', () {
    test('empty data asks for data', () {
      expect(dailyInsight([], const Profile(), today).code, InsightCode.addData);
    });

    test('demo data with deficit is on track', () {
      final i = dailyInsight(demoEntries(today), const Profile(), today);
      expect(i.code, anyOf(InsightCode.onTrack, InsightCode.tooSlow));
    });

    test('growing weight while losing is flagged', () {
      final entries = [
        for (var i = 27; i >= 0; i--)
          DayEntry(date: fmtDate(today.subtract(Duration(days: i))), weightKg: 70 + (27 - i) * 0.05, kcal: 2000, closed: true),
      ];
      expect(dailyInsight(entries, const Profile(), today).code, InsightCode.wrongDirection);
    });
  });

  group('cycle', () {
    test('day of cycle and comparison with the previous cycle', () {
      final entries = <DayEntry>[];
      for (var i = 60; i >= 0; i--) {
        final d = today.subtract(Duration(days: i));
        entries.add(DayEntry(date: fmtDate(d), weightKg: 70, cycleStart: i == 40 || i == 12));
      }
      final c = Cycle(entries);
      expect(c.dayOf(today), 13);
      expect(c.sameDayPrevious(today), today.subtract(const Duration(days: 28)));
      final cmp = compareWithPreviousCycle(entries, c, today);
      expect(cmp, isNotNull);
      expect(cmp!.diffKg, closeTo(0, 0.001));
    });

    test('no comparison when the previous cycle was shorter', () {
      final c = Cycle([
        const DayEntry(date: '2026-10-01', cycleStart: true),
        const DayEntry(date: '2026-10-20', cycleStart: true),
      ]);
      expect(c.sameDayPrevious(DateTime.utc(2026, 11, 8)), isNull);
    });
  });

  group('csv', () {
    test('Russian semicolon export with decimal commas and dotted dates', () {
      final r = importCsv('Дата;Вес (кг);Калории;Белки;Углеводы;Жиры\n'
          '28.10.2026;72,4;1850;110;200;60\n'
          '29.10.2026;;1900;120;190;62\n'
          'мусор;1;1;1;1;1\n');
      expect(r.entries.length, 2);
      expect(r.skipped, 1);
      expect(r.entries.first.weightKg, 72.4);
      expect(r.entries.first.kcal, 1850);
      expect(r.entries.first.closed, isTrue);
      expect(r.entries.last.weightKg, isNull);
    });

    test('per-meal rows are summed per day', () {
      final r = importCsv('Date,Meal,Calories,Protein\n'
          '2026-10-28,Breakfast,400,20\n'
          '2026-10-28,Lunch,700,40\n'
          '2026-10-29,Lunch,500,30\n');
      expect(r.entries.length, 2);
      expect(r.entries.first.kcal, 1100);
      expect(r.entries.first.proteinG, 60);
    });

    test('quoted cells and US dates', () {
      final r = importCsv('"Date","Weight","Calories"\n"10/28/2026","160.5","2,000"\n');
      expect(r.entries.single.date, '2026-10-28');
    });

    test('missing date column imports nothing', () {
      final r = importCsv('a,b\n1,2\n');
      expect(r.entries, isEmpty);
    });

    test('export then import round-trips', () {
      final src = demoEntries(today, days: 10);
      final back = importCsv(exportCsv(src));
      expect(back.entries.length, src.length);
      expect(back.entries.last.kcal, src.last.kcal);
    });
  });

  test('import never overwrites manual values', () {
    const manual = DayEntry(date: '2026-10-28', weightKg: 71.9);
    const imported = DayEntry(date: '2026-10-28', weightKg: 72.4, kcal: 1800, closed: true);
    final m = manual.fillMissing(imported);
    expect(m.weightKg, 71.9);
    expect(m.kcal, 1800);
    expect(m.closed, isTrue);
  });
}
