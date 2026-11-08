import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models.dart';
import '../data/app_state.dart';
import 'app.dart';
import 'widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _import(BuildContext context, AppState st) async {
    final s = strings(context);
    try {
      final file = await FilePicker.pickFile();
      if (file == null) return;
      final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      final r = st.importText(text);
      if (!context.mounted) return;
      _toast(
        context,
        r.entries.isEmpty ? s('importEmpty') : s('importDone', {'n': r.entries.length, 's': r.skipped}),
      );
    } catch (_) {
      if (context.mounted) _toast(context, s('importFail'));
    }
  }

  Future<void> _clear(BuildContext context, AppState st) async {
    final s = strings(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(s('clearAsk')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s('clear'))),
        ],
      ),
    );
    if (ok == true) st.clear();
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final s = strings(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final p = st.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(s('profile'), style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s('profileTitle'), style: t.titleMedium),
              const SizedBox(height: 12),
              Text(s('sex'), style: t.labelMedium),
              const SizedBox(height: 4),
              SegmentedButton<Sex>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: Sex.female, label: Text(s('female'))),
                  ButtonSegment(value: Sex.male, label: Text(s('male'))),
                ],
                selected: {p.sex},
                onSelectionChanged: (v) => st.setProfile(p.copyWith(sex: v.first)),
              ),
              const SizedBox(height: 12),
              Text(s('goal'), style: t.labelMedium),
              const SizedBox(height: 4),
              SegmentedButton<Goal>(
                showSelectedIcon: false,
                segments: [
                  for (final g in Goal.values) ButtonSegment(value: g, label: Text(s.goal(g))),
                ],
                selected: {p.goal},
                onSelectionChanged: (v) => st.setProfile(p.copyWith(goal: v.first)),
              ),
              const SizedBox(height: 12),
              _Slider(
                label: s('age'),
                value: p.age.toDouble(),
                min: 16,
                max: 80,
                divisions: 64,
                display: '${p.age}',
                onChanged: (v) => st.setProfile(p.copyWith(age: v.round())),
              ),
              _Slider(
                label: s('height'),
                value: p.heightCm,
                min: 140,
                max: 210,
                divisions: 70,
                display: '${p.heightCm.round()}',
                onChanged: (v) => st.setProfile(p.copyWith(heightCm: v.roundToDouble())),
              ),
              if (p.goal != Goal.maintain)
                _Slider(
                  label: s('rate'),
                  value: p.ratePctPerWeek,
                  min: 0.25,
                  max: 1.0,
                  divisions: 15,
                  display: '${s.num2(p.ratePctPerWeek)}% ${s('perWeek')}',
                  onChanged: (v) => st.setProfile(p.copyWith(ratePctPerWeek: double.parse(v.toStringAsFixed(2)))),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s('trackCycle')),
                subtitle: Text(s('trackCycleNote')),
                value: p.trackCycle,
                onChanged: (v) => st.setProfile(p.copyWith(trackCycle: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s('dataTitle'), style: t.titleMedium),
              const SizedBox(height: 4),
              Text(s('importNote'), style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _import(context, st),
                    icon: const Icon(Icons.upload_file),
                    label: Text(s('import')),
                  ),
                  OutlinedButton.icon(
                    onPressed: st.entries.isEmpty
                        ? null
                        : () async {
                            await Clipboard.setData(ClipboardData(text: st.csv()));
                            if (context.mounted) _toast(context, s('exportDone'));
                          },
                    icon: const Icon(Icons.copy),
                    label: Text(s('export')),
                  ),
                ],
              ),
              const Divider(height: 28),
              OutlinedButton(onPressed: st.loadDemo, child: Text(s('demo'))),
              const SizedBox(height: 4),
              Text(s('demoNote'), style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: st.entries.isEmpty ? null : () => _clear(context, st),
                style: TextButton.styleFrom(foregroundColor: cs.error),
                child: Text(s('clear')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Row(
            children: [
              Expanded(child: Text(s('language'), style: t.titleMedium)),
              DropdownButton<String?>(
                value: st.lang,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(s('langAuto'))),
                  const DropdownMenuItem(value: 'ru', child: Text('Русский')),
                  const DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: st.setLang,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(s('privacy'), style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label, style: t.labelMedium), Text(display, style: t.labelMedium)],
        ),
        Slider(value: value.clamp(min, max), min: min, max: max, divisions: divisions, onChanged: onChanged),
      ],
    );
  }
}
