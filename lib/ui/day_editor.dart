import 'package:flutter/material.dart';

import '../core/models.dart';
import '../data/app_state.dart';
import 'app.dart';

Future<void> showDayEditor(BuildContext context, {DateTime? date}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => AppScope(
      state: AppScope.of(context),
      child: DayEditor(initial: date ?? AppScope.of(context).today),
    ),
  );
}

double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

class DayEditor extends StatefulWidget {
  const DayEditor({super.key, required this.initial});
  final DateTime initial;

  @override
  State<DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<DayEditor> {
  late DateTime _date = widget.initial;
  final _weight = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _steps = TextEditingController();
  int _workouts = 0;
  bool _closed = false;
  bool _cycleStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _fmt(num? v) => v == null ? '' : (v == v.roundToDouble() ? v.round().toString() : v.toString());

  void _load() {
    final e = AppScope.of(context).entryFor(_date);
    setState(() {
      _weight.text = _fmt(e?.weightKg);
      _kcal.text = _fmt(e?.kcal);
      _protein.text = _fmt(e?.proteinG);
      _carbs.text = _fmt(e?.carbsG);
      _fat.text = _fmt(e?.fatG);
      _steps.text = _fmt(e?.steps);
      _workouts = e?.workouts ?? 0;
      _closed = e?.closed ?? false;
      _cycleStart = e?.cycleStart ?? false;
    });
  }

  @override
  void dispose() {
    for (final c in [_weight, _kcal, _protein, _carbs, _fat, _steps]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = AppScope.of(context).today;
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: today,
    );
    if (d != null) {
      _date = dateOnly(d);
      _load();
    }
  }

  void _save() {
    final st = AppScope.of(context);
    final w = _parse(_weight.text);
    st.saveDay(DayEntry(
      date: fmtDate(_date),
      weightKg: w != null && w > 20 && w < 400 ? w : null,
      kcal: _parse(_kcal.text),
      proteinG: _parse(_protein.text),
      carbsG: _parse(_carbs.text),
      fatG: _parse(_fat.text),
      steps: _parse(_steps.text)?.round(),
      workouts: _workouts,
      closed: _closed,
      cycleStart: _cycleStart,
    ));
    Navigator.of(context).pop();
  }

  Widget _field(TextEditingController c, String label, {String? suffix, bool integer = false}) => TextField(
        controller: c,
        keyboardType: TextInputType.numberWithOptions(decimal: !integer),
        decoration: InputDecoration(labelText: label, suffixText: suffix, border: const OutlineInputBorder()),
      );

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final s = strings(context);
    final t = Theme.of(context).textTheme;
    final exists = st.entryFor(_date) != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(s('dayEditor'), style: t.titleLarge)),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(s.dateShort(_date)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _field(_weight, s('weight'), suffix: s('kg'))),
              const SizedBox(width: 12),
              Expanded(child: _field(_steps, s('steps'), integer: true)),
            ]),
            const SizedBox(height: 12),
            _field(_kcal, s('calories'), suffix: s('kcal')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_protein, s('protein'), suffix: s('g'))),
              const SizedBox(width: 12),
              Expanded(child: _field(_carbs, s('carbs'), suffix: s('g'))),
              const SizedBox(width: 12),
              Expanded(child: _field(_fat, s('fat'), suffix: s('g'))),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s('dayClosed')),
              value: _closed,
              onChanged: (v) => setState(() => _closed = v),
            ),
            Row(children: [
              Expanded(child: Text(s('workouts'), style: t.bodyLarge)),
              IconButton(
                onPressed: _workouts > 0 ? () => setState(() => _workouts--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_workouts', style: t.titleMedium),
              IconButton(onPressed: () => setState(() => _workouts++), icon: const Icon(Icons.add_circle_outline)),
            ]),
            if (st.profile.trackCycle)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s('cycleStartToday')),
                value: _cycleStart,
                onChanged: (v) => setState(() => _cycleStart = v),
              ),
            const SizedBox(height: 8),
            Row(children: [
              if (exists)
                TextButton(
                  onPressed: () {
                    st.deleteDay(fmtDate(_date));
                    Navigator.of(context).pop();
                  },
                  child: Text(s('delete')),
                ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s('cancel'))),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: Text(s('save'))),
            ]),
          ],
        ),
      ),
    );
  }
}
