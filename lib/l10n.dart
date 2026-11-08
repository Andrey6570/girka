import 'package:flutter/widgets.dart';

import 'core/analytics.dart';
import 'core/models.dart';

const _ru = <String, String>{
  'app': 'Гирька',
  'tagline': 'Ваш вес, питание и тренировки без паники',
  'today': 'Сегодня',
  'progress': 'Прогресс',
  'profile': 'Профиль',
  'add': 'Внести день',
  'eaten': 'съедено',
  'of': 'из',
  'kcal': 'ккал',
  'calories': 'Калории',
  'protein': 'Белок',
  'carbs': 'Углеводы',
  'fat': 'Жиры',
  'g': 'г',
  'kg': 'кг',
  'steps': 'Шаги',
  'weight': 'Вес',
  'trend': 'Тренд',
  'perWeek': 'в неделю',
  'rhythm': 'Ритм недели',
  'rhythmNote': 'Пропуски нормальны: серий и штрафов нет.',
  'workouts': 'Тренировки',
  'cycleDay': 'День цикла',
  'cycleVsPrev': 'К тому же дню прошлого цикла',
  'planTitle': 'План на сегодня',
  'planFormula': 'Оценка по формуле: данных для расчёта пока мало.',
  'planMeasured': 'Построено на вашем фактическом расходе.',
  'floorNote': 'Цель поднята до безопасного минимума калорий.',
  'noWeight': 'Внесите вес, чтобы увидеть план.',
  'confidence': 'Надёжность',
  'conf.high': 'высокая',
  'conf.medium': 'средняя',
  'conf.low': 'низкая',
  'range14': '2 нед.',
  'range28': '4 нед.',
  'range90': '3 мес.',
  'weightChart': 'Вес и тренд',
  'energyTitle': 'Расход энергии',
  'energyNote': 'Средний приём минус изменение веса. Это оценка: 7700 ккал на кг условны.',
  'energyNone': 'Пока не посчитать: нужно хотя бы 10 закрытых дней питания и 6 взвешиваний за 4 недели.',
  'avgIntake': 'Средний приём',
  'daysCounted': 'дней в расчёте',
  'expenditure': 'Расход',
  'why': 'Научная основа',
  'why1': 'Силовые тренировки при дефиците калорий сильнее всего снижают жир и сохраняют мышцы (Lopez и др., Obesity Reviews 2022).',
  'why2': 'Белок около 1,6 г на кг массы даёт основной эффект, выше эффект не доказан (Morton и др., Br J Sports Med 2018).',
  'why3': 'Темп до 0,5–1% массы в неделю щадит мышцы лучше быстрого (Garthe и др., 2011). Данные по небольшим группам.',
  'why4': 'Вес колеблется на 1–2 кг за сутки, поэтому решения принимаются по тренду, а не по одному взвешиванию.',
  'dayEditor': 'День',
  'dayClosed': 'Питание за день внесено полностью',
  'cycleStartToday': 'Началась менструация',
  'save': 'Сохранить',
  'delete': 'Удалить день',
  'cancel': 'Отмена',
  'profileTitle': 'Цели',
  'sex': 'Пол',
  'female': 'Женский',
  'male': 'Мужской',
  'age': 'Возраст',
  'height': 'Рост, см',
  'goal': 'Цель',
  'goal.lose': 'Снизить вес',
  'goal.maintain': 'Держать',
  'goal.gain': 'Набрать',
  'rate': 'Желаемый темп',
  'trackCycle': 'Учитывать цикл',
  'trackCycleNote': 'Данные цикла остаются на устройстве.',
  'dataTitle': 'Данные',
  'import': 'Импорт из CSV',
  'importNote': 'Подойдёт экспорт из MyFitnessPal, Cronometer, Hevy и таблиц: нужен столбец с датой.',
  'importDone': 'Загружено дней: {n}. Пропущено строк: {s}.',
  'importEmpty': 'В файле не нашлось строк с датой.',
  'importFail': 'Не удалось прочитать файл.',
  'export': 'Скопировать CSV',
  'exportDone': 'CSV скопирован в буфер обмена.',
  'demo': 'Загрузить демо-данные',
  'demoNote': 'Заменит текущие записи примером на 10 недель.',
  'clear': 'Удалить все данные',
  'clearAsk': 'Удалить все записи с этого устройства? Это нельзя отменить.',
  'language': 'Язык',
  'langAuto': 'Как в системе',
  'privacy': 'Все записи хранятся только на этом устройстве. Приложение не отправляет данные никуда. Не заменяет врача.',
  'emptyTitle': 'Начнём с данных',
  'emptyBody': 'Внесите день вручную, импортируйте CSV или загрузите демо.',
  'loadDemo': 'Посмотреть на демо',
  'insight.addData': 'Внесите вес и питание за пару дней: тогда появится тренд и план.',
  'insight.needWeighins': 'Взвесьтесь ещё {n} раз(а) в ближайшие дни: тренд появится после трёх взвешиваний за неделю.',
  'insight.closeDays': 'Отметьте полностью внесённые дни питания: нужно ещё {n} для расчёта расхода.',
  'insight.onTrack': 'Идёте по плану: {v}% массы в неделю. Ничего менять не нужно.',
  'insight.tooFast': 'Темп {v}% в неделю быстрый. Добавьте 100–200 ккал, чтобы не терять мышцы.',
  'insight.tooSlow': 'Темп {v}% в неделю ниже плана. Подождите ещё неделю и проверьте, все ли дни внесены.',
  'insight.wrongDirection': 'Тренд идёт против цели ({v}% в неделю). Проверьте внесённые дни и порции, а затем решайте.',
  'insight.stable': 'Вес стабилен ({v}% в неделю). Всё в порядке.',
  'insight.maintainDrift': 'Вес дрейфует ({v}% в неделю). Скорректируйте калории на 100–150 ккал.',
};

const _en = <String, String>{
  'app': 'Girka',
  'tagline': 'Your weight, food and training, without the panic',
  'today': 'Today',
  'progress': 'Progress',
  'profile': 'Profile',
  'add': 'Log a day',
  'eaten': 'eaten',
  'of': 'of',
  'kcal': 'kcal',
  'calories': 'Calories',
  'protein': 'Protein',
  'carbs': 'Carbs',
  'fat': 'Fat',
  'g': 'g',
  'kg': 'kg',
  'steps': 'Steps',
  'weight': 'Weight',
  'trend': 'Trend',
  'perWeek': 'per week',
  'rhythm': 'Week rhythm',
  'rhythmNote': 'Gaps are normal: no streaks, no penalties.',
  'workouts': 'Workouts',
  'cycleDay': 'Cycle day',
  'cycleVsPrev': 'Vs the same day last cycle',
  'planTitle': 'Plan for today',
  'planFormula': 'Formula estimate: not enough data yet.',
  'planMeasured': 'Built on your measured expenditure.',
  'floorNote': 'Target raised to a safe minimum of calories.',
  'noWeight': 'Log your weight to see a plan.',
  'confidence': 'Confidence',
  'conf.high': 'high',
  'conf.medium': 'medium',
  'conf.low': 'low',
  'range14': '2 wk',
  'range28': '4 wk',
  'range90': '3 mo',
  'weightChart': 'Weight and trend',
  'energyTitle': 'Energy expenditure',
  'energyNote': 'Average intake minus weight change. It is an estimate: 7700 kcal per kg is approximate.',
  'energyNone': 'Not available yet: needs at least 10 closed food days and 6 weigh-ins in 4 weeks.',
  'avgIntake': 'Average intake',
  'daysCounted': 'days counted',
  'expenditure': 'Expenditure',
  'why': 'The evidence',
  'why1': 'Resistance training in a calorie deficit cuts fat the most and keeps lean mass (Lopez et al., Obesity Reviews 2022).',
  'why2': 'Protein of about 1.6 g per kg gives the main benefit; more is not shown to help (Morton et al., Br J Sports Med 2018).',
  'why3': 'A rate of up to 0.5–1% of body weight per week spares muscle better than fast loss (Garthe et al., 2011). Small samples.',
  'why4': 'Weight swings 1–2 kg a day, so decisions follow the trend, not a single weigh-in.',
  'dayEditor': 'Day',
  'dayClosed': 'Food for the day is fully logged',
  'cycleStartToday': 'Period started',
  'save': 'Save',
  'delete': 'Delete day',
  'cancel': 'Cancel',
  'profileTitle': 'Goals',
  'sex': 'Sex',
  'female': 'Female',
  'male': 'Male',
  'age': 'Age',
  'height': 'Height, cm',
  'goal': 'Goal',
  'goal.lose': 'Lose weight',
  'goal.maintain': 'Maintain',
  'goal.gain': 'Gain',
  'rate': 'Target rate',
  'trackCycle': 'Track cycle',
  'trackCycleNote': 'Cycle data stays on this device.',
  'dataTitle': 'Data',
  'import': 'Import from CSV',
  'importNote': 'Works with exports from MyFitnessPal, Cronometer, Hevy and spreadsheets: a date column is required.',
  'importDone': 'Days loaded: {n}. Rows skipped: {s}.',
  'importEmpty': 'No rows with a date were found in the file.',
  'importFail': 'Could not read the file.',
  'export': 'Copy CSV',
  'exportDone': 'CSV copied to the clipboard.',
  'demo': 'Load demo data',
  'demoNote': 'Replaces current entries with a 10-week example.',
  'clear': 'Delete all data',
  'clearAsk': 'Delete all entries from this device? This cannot be undone.',
  'language': 'Language',
  'langAuto': 'System',
  'privacy': 'All entries stay on this device. The app sends nothing anywhere. It does not replace a doctor.',
  'emptyTitle': 'Let us start with data',
  'emptyBody': 'Log a day by hand, import a CSV, or load the demo.',
  'loadDemo': 'Try the demo',
  'insight.addData': 'Log weight and food for a couple of days to get a trend and a plan.',
  'insight.needWeighins': 'Weigh in {n} more time(s) this week: a trend needs three weigh-ins.',
  'insight.closeDays': 'Mark fully logged food days: {n} more are needed to estimate expenditure.',
  'insight.onTrack': 'On plan: {v}% of body weight per week. No changes needed.',
  'insight.tooFast': 'A pace of {v}% per week is fast. Add 100–200 kcal to protect muscle.',
  'insight.tooSlow': 'A pace of {v}% per week is below plan. Wait another week and check that all days are logged.',
  'insight.wrongDirection': 'The trend is against your goal ({v}% per week). Check logged days and portions, then decide.',
  'insight.stable': 'Weight is stable ({v}% per week). All good.',
  'insight.maintainDrift': 'Weight is drifting ({v}% per week). Adjust calories by 100–150 kcal.',
};

class S {
  const S(this.code);
  final String code;

  static S of(BuildContext context, String? override) {
    final c = override ?? Localizations.localeOf(context).languageCode;
    return S(c == 'ru' ? 'ru' : 'en');
  }

  Map<String, String> get _m => code == 'ru' ? _ru : _en;

  String call(String key, [Map<String, Object> args = const {}]) {
    var s = _m[key] ?? _en[key] ?? key;
    args.forEach((k, v) => s = s.replaceAll('{$k}', v.toString()));
    return s;
  }

  String num1(double v) => v.toStringAsFixed(1).replaceAll('.', code == 'ru' ? ',' : '.');
  String num2(double v) => v.toStringAsFixed(2).replaceAll('.', code == 'ru' ? ',' : '.');

  String conf(Confidence c) => this('conf.${c.name}');

  String insight(Insight i) {
    final v = i.v == null ? '' : num1(i.v!.abs());
    return this('insight.${i.code.name}', {'n': i.n ?? 0, 'v': v});
  }

  String goal(Goal g) => this('goal.${g.name}');

  String dateShort(DateTime d) {
    const ru = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${(code == 'ru' ? ru : en)[d.month - 1]}';
  }

  String weekday(DateTime d) {
    const ru = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    const en = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return (code == 'ru' ? ru : en)[d.weekday - 1];
  }
}
