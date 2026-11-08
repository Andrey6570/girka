import 'package:flutter/material.dart';

import '../core/analytics.dart';
import '../core/models.dart';
import '../data/app_state.dart';
import '../l10n.dart';
import 'app.dart';
import 'widgets.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _range = 28;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final s = strings(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final from = st.today.subtract(Duration(days: _range - 1));
    final series = trendSeries(st.entries).where((p) => !p.date.isBefore(from)).toList();
    final cycleStarts = st.profile.trackCycle ? Cycle(st.entries).starts.where((d) => !d.isBefore(from)).toList() : <DateTime>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        Text(s('progress'), style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 14, label: Text(s('range14'))),
            ButtonSegment(value: 28, label: Text(s('range28'))),
            ButtonSegment(value: 90, label: Text(s('range90'))),
          ],
          selected: {_range},
          onSelectionChanged: (v) => setState(() => _range = v.first),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s('weightChart'), style: t.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: series.length < 2
                    ? Center(child: Text(s('noWeight')))
                    : CustomPaint(
                        size: Size.infinite,
                        painter: WeightChartPainter(
                          points: series,
                          start: from,
                          end: st.today,
                          cycleStarts: cycleStarts,
                          line: cs.primary,
                          dots: cs.outline,
                          grid: cs.outlineVariant.withValues(alpha: 0.5),
                          text: cs.onSurfaceVariant,
                          marker: cs.tertiary,
                          labelStart: s.dateShort(from),
                          labelEnd: s.dateShort(st.today),
                          font: DefaultTextStyle.of(context).style,
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _EnergyCard(st: st, s: s),
        const SizedBox(height: 12),
        Panel(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(s('why'), style: t.titleMedium),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final k in ['why1', 'why2', 'why3', 'why4'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(s(k), style: t.bodyMedium?.copyWith(height: 1.35)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EnergyCard extends StatelessWidget {
  const _EnergyCard({required this.st, required this.s});
  final AppState st;
  final S s;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final e = st.energy;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(s('energyTitle'), style: t.titleMedium)),
              if (e.expenditureKcal != null) ConfidenceChip(label: '${s('confidence')}: ${s.conf(e.confidence)}'),
            ],
          ),
          const SizedBox(height: 8),
          if (e.expenditureKcal == null)
            Text(s('energyNone'), style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
          else ...[
            Text(
              '${e.expenditureKcal!.round()} ${s('kcal')}',
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              '${s('avgIntake')}: ${e.avgIntakeKcal!.round()} ${s('kcal')} · ${e.intakeDays} ${s('daysCounted')}',
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(s('energyNote'), style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class WeightChartPainter extends CustomPainter {
  WeightChartPainter({
    required this.points,
    required this.start,
    required this.end,
    required this.cycleStarts,
    required this.line,
    required this.dots,
    required this.grid,
    required this.text,
    required this.marker,
    required this.labelStart,
    required this.labelEnd,
    required this.font,
  });

  final List<TrendPoint> points;
  final DateTime start;
  final DateTime end;
  final List<DateTime> cycleStarts;
  final Color line;
  final Color dots;
  final Color grid;
  final Color text;
  final Color marker;
  final String labelStart;
  final String labelEnd;
  final TextStyle font;

  TextPainter _tp(String s, {TextAlign align = TextAlign.left}) => TextPainter(
        text: TextSpan(text: s, style: font.copyWith(color: text, fontSize: 11)),
        textDirection: TextDirection.ltr,
        textAlign: align,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0, bottom = 20.0, top = 6.0;
    final w = size.width - left;
    final h = size.height - bottom - top;
    var lo = double.infinity, hi = -double.infinity;
    for (final p in points) {
      lo = lo < p.weight ? lo : p.weight;
      hi = hi > p.weight ? hi : p.weight;
      lo = lo < p.trend ? lo : p.trend;
      hi = hi > p.trend ? hi : p.trend;
    }
    final pad = (hi - lo) < 1 ? 0.5 : (hi - lo) * 0.1;
    lo -= pad;
    hi += pad;
    final span = daysBetween(start, end).clamp(1, 100000);
    double x(DateTime d) => left + w * daysBetween(start, d) / span;
    double y(double v) => top + h * (1 - (v - lo) / (hi - lo));

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final v = lo + (hi - lo) * i / 3;
      final yy = y(v);
      canvas.drawLine(Offset(left, yy), Offset(size.width, yy), gridPaint);
      final tp = _tp(v.toStringAsFixed(1));
      tp.paint(canvas, Offset(left - tp.width - 6, yy - tp.height / 2));
    }
    final a = _tp(labelStart);
    a.paint(canvas, Offset(left, size.height - a.height));
    final b = _tp(labelEnd);
    b.paint(canvas, Offset(size.width - b.width, size.height - b.height));

    final markPaint = Paint()
      ..color = marker.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    for (final d in cycleStarts) {
      final xx = x(d);
      for (var yy = top; yy < top + h; yy += 8) {
        canvas.drawLine(Offset(xx, yy), Offset(xx, yy + 4), markPaint);
      }
    }

    final dotPaint = Paint()..color = dots.withValues(alpha: 0.7);
    for (final p in points) {
      canvas.drawCircle(Offset(x(p.date), y(p.weight)), 2.5, dotPaint);
    }
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = Offset(x(points[i].date), y(points[i].trend));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(WeightChartPainter o) =>
      o.points != points || o.start != start || o.end != end || o.line != line || o.cycleStarts != cycleStarts;
}
