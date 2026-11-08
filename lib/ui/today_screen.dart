import 'package:flutter/material.dart';

import '../core/analytics.dart';
import '../data/app_state.dart';
import 'app.dart';
import 'widgets.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final s = strings(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final children = <Widget>[
      Text(s('app'), style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
      Text(s('tagline'), style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 16),
    ];

    if (st.entries.isEmpty) {
      children.add(Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s('emptyTitle'), style: t.titleLarge),
            const SizedBox(height: 8),
            Text(s('emptyBody')),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: st.loadDemo, child: Text(s('loadDemo'))),
          ],
        ),
      ));
    } else {
      children
        ..add(_InsightCard(st: st))
        ..add(const SizedBox(height: 12))
        ..add(_PlanCard(st: st))
        ..add(const SizedBox(height: 12))
        ..add(_WeightCard(st: st));
      if (st.profile.trackCycle) {
        final cycle = Cycle(st.entries);
        final day = cycle.dayOf(st.today);
        if (day != null) {
          children
            ..add(const SizedBox(height: 12))
            ..add(_CycleCard(st: st, cycle: cycle, day: day));
        }
      }
      children
        ..add(const SizedBox(height: 12))
        ..add(_RhythmCard(st: st));
    }
    children.add(const SizedBox(height: 88));
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), children: children);
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.st});
  final AppState st;

  @override
  Widget build(BuildContext context) {
    final s = strings(context);
    final cs = Theme.of(context).colorScheme;
    return Panel(
      color: cs.primaryContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: cs.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.insight(st.insight),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onPrimaryContainer, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.st});
  final AppState st;

  @override
  Widget build(BuildContext context) {
    final s = strings(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final targets = st.targets;
    final e = st.entryFor(st.today);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s('planTitle'), style: t.titleMedium),
          const SizedBox(height: 12),
          if (targets == null)
            Text(s('noWeight'))
          else ...[
            Row(
              children: [
                CalorieRing(
                  value: e?.kcal ?? 0,
                  target: targets.kcal.toDouble(),
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(e?.kcal ?? 0).round()}', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${s('of')} ${targets.kcal}', style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      Text(s('kcal'), style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      MacroBar(label: s('protein'), value: e?.proteinG ?? 0, target: targets.proteinG.toDouble(), unit: s('g')),
                      MacroBar(label: s('carbs'), value: e?.carbsG ?? 0, target: targets.carbsG.toDouble(), unit: s('g')),
                      MacroBar(label: s('fat'), value: e?.fatG ?? 0, target: targets.fatG.toDouble(), unit: s('g')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    targets.fromMeasured ? s('planMeasured') : s('planFormula'),
                    style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                if (targets.fromMeasured) ConfidenceChip(label: '${s('confidence')}: ${s.conf(st.energy.confidence)}'),
              ],
            ),
            if (targets.floorApplied)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(s('floorNote'), style: t.bodySmall?.copyWith(color: cs.error)),
              ),
          ],
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.st});
  final AppState st;

  @override
  Widget build(BuildContext context) {
    final s = strings(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final series = trendSeries(st.entries);
    final rate = st.rate;
    final e = st.entryFor(st.today);
    return Panel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s('trend'), style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                Text(
                  series.isEmpty ? '—' : '${s.num1(series.last.trend)} ${s('kg')}',
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (rate.available)
                  Text(
                    '${rate.kgPerWeek! > 0 ? '+' : ''}${s.num2(rate.kgPerWeek!)} ${s('kg')} ${s('perWeek')}',
                    style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                if (rate.available) ConfidenceChip(label: '${s('confidence')}: ${s.conf(rate.confidence)}'),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s('steps'), style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                Text('${e?.steps ?? '—'}', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleCard extends StatelessWidget {
  const _CycleCard({required this.st, required this.cycle, required this.day});
  final AppState st;
  final Cycle cycle;
  final int day;

  @override
  Widget build(BuildContext context) {
    final s = strings(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final cmp = compareWithPreviousCycle(st.entries, cycle, st.today);
    return Panel(
      child: Row(
        children: [
          Icon(Icons.circle_outlined, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s('cycleDay')} $day', style: t.titleMedium),
                if (cmp != null)
                  Text(
                    '${s('cycleVsPrev')}: ${cmp.diffKg > 0 ? '+' : ''}${s.num1(cmp.diffKg)} ${s('kg')}',
                    style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RhythmCard extends StatelessWidget {
  const _RhythmCard({required this.st});
  final AppState st;

  @override
  Widget build(BuildContext context) {
    final s = strings(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final days = [for (var i = 6; i >= 0; i--) st.today.subtract(Duration(days: i))];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s('rhythm'), style: t.titleMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in days) _Dot(day: d, st: st, cs: cs, label: s.weekday(d)),
            ],
          ),
          const SizedBox(height: 8),
          Text(s('rhythmNote'), style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.day, required this.st, required this.cs, required this.label});
  final DateTime day;
  final AppState st;
  final ColorScheme cs;
  final String label;

  @override
  Widget build(BuildContext context) {
    final e = st.entryFor(day);
    final logged = e?.kcal != null;
    final lifted = (e?.workouts ?? 0) > 0;
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: logged ? cs.primary : Colors.transparent,
            border: Border.all(color: logged ? cs.primary : cs.outlineVariant, width: 1.5),
          ),
          child: lifted ? Icon(Icons.fitness_center, size: 14, color: logged ? cs.onPrimary : cs.primary) : null,
        ),
      ],
    );
  }
}
