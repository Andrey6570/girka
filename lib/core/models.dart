enum Sex { female, male }

enum Goal { lose, maintain, gain }

enum Confidence { high, medium, low }

DateTime parseDate(String s) {
  final p = s.split('-');
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

int daysBetween(DateTime a, DateTime b) => b.difference(a).inDays;

/// Одна запись за день. Пустое поле значит «не записано», а не ноль.
class DayEntry {
  const DayEntry({
    required this.date,
    this.weightKg,
    this.kcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.steps,
    this.workouts = 0,
    this.closed = false,
    this.cycleStart = false,
  });

  /// yyyy-MM-dd
  final String date;
  final double? weightKg;
  final double? kcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final int? steps;
  final int workouts;

  /// Питание за день внесено полностью. Только такие дни идут в расчёт расхода.
  final bool closed;
  final bool cycleStart;

  DateTime get day => parseDate(date);

  /// Заполняет только пустые поля из [other]: ручные значения импорт не перезаписывает.
  DayEntry fillMissing(DayEntry other) => DayEntry(
        date: date,
        weightKg: weightKg ?? other.weightKg,
        kcal: kcal ?? other.kcal,
        proteinG: proteinG ?? other.proteinG,
        carbsG: carbsG ?? other.carbsG,
        fatG: fatG ?? other.fatG,
        steps: steps ?? other.steps,
        workouts: workouts > 0 ? workouts : other.workouts,
        closed: kcal != null ? closed : other.closed,
        cycleStart: cycleStart || other.cycleStart,
      );

  Map<String, Object?> toJson() => {
        'date': date,
        if (weightKg != null) 'weightKg': weightKg,
        if (kcal != null) 'kcal': kcal,
        if (proteinG != null) 'proteinG': proteinG,
        if (carbsG != null) 'carbsG': carbsG,
        if (fatG != null) 'fatG': fatG,
        if (steps != null) 'steps': steps,
        if (workouts > 0) 'workouts': workouts,
        if (closed) 'closed': true,
        if (cycleStart) 'cycleStart': true,
      };

  factory DayEntry.fromJson(Map<String, dynamic> j) => DayEntry(
        date: j['date'] as String,
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        kcal: (j['kcal'] as num?)?.toDouble(),
        proteinG: (j['proteinG'] as num?)?.toDouble(),
        carbsG: (j['carbsG'] as num?)?.toDouble(),
        fatG: (j['fatG'] as num?)?.toDouble(),
        steps: (j['steps'] as num?)?.toInt(),
        workouts: (j['workouts'] as num?)?.toInt() ?? 0,
        closed: j['closed'] as bool? ?? false,
        cycleStart: j['cycleStart'] as bool? ?? false,
      );
}

class Profile {
  const Profile({
    this.sex = Sex.female,
    this.age = 35,
    this.heightCm = 170,
    this.goal = Goal.lose,
    this.ratePctPerWeek = 0.5,
    this.trackCycle = false,
  });

  final Sex sex;
  final int age;
  final double heightCm;
  final Goal goal;

  /// Желаемый темп изменения веса, % массы тела в неделю (модуль).
  final double ratePctPerWeek;
  final bool trackCycle;

  Profile copyWith({
    Sex? sex,
    int? age,
    double? heightCm,
    Goal? goal,
    double? ratePctPerWeek,
    bool? trackCycle,
  }) =>
      Profile(
        sex: sex ?? this.sex,
        age: age ?? this.age,
        heightCm: heightCm ?? this.heightCm,
        goal: goal ?? this.goal,
        ratePctPerWeek: ratePctPerWeek ?? this.ratePctPerWeek,
        trackCycle: trackCycle ?? this.trackCycle,
      );

  Map<String, Object?> toJson() => {
        'sex': sex.name,
        'age': age,
        'heightCm': heightCm,
        'goal': goal.name,
        'ratePctPerWeek': ratePctPerWeek,
        'trackCycle': trackCycle,
      };

  factory Profile.fromJson(Map<String, dynamic> j) {
    const d = Profile();
    return Profile(
      sex: Sex.values.asNameMap()[j['sex']] ?? d.sex,
      age: (j['age'] as num?)?.toInt() ?? d.age,
      heightCm: (j['heightCm'] as num?)?.toDouble() ?? d.heightCm,
      goal: Goal.values.asNameMap()[j['goal']] ?? d.goal,
      ratePctPerWeek: (j['ratePctPerWeek'] as num?)?.toDouble() ?? d.ratePctPerWeek,
      trackCycle: j['trackCycle'] as bool? ?? d.trackCycle,
    );
  }
}
