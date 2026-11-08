import 'dart:math' as math;

import 'package:flutter/material.dart';

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.color, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: color ?? cs.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: padding, child: child),
    );
  }
}

class CalorieRing extends StatelessWidget {
  const CalorieRing({super.key, required this.value, required this.target, required this.center, this.size = 132});

  final double value;
  final double target;
  final Widget center;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: target <= 0 ? 0 : value / target,
          track: cs.outlineVariant.withValues(alpha: 0.5),
          color: cs.primary,
          over: cs.tertiary,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.track, required this.color, required this.over});

  final double progress;
  final Color track;
  final Color color;
  final Color over;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 12.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(w / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, base..color = track);
    final p = progress.clamp(0.0, 1.0);
    if (p > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * p, false, base..color = progress > 1.05 ? over : color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress || o.color != color || o.track != track;
}

class MacroBar extends StatelessWidget {
  const MacroBar({super.key, required this.label, required this.value, required this.target, required this.unit});

  final String label;
  final double value;
  final double target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final p = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label, style: t.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text('${value.round()} / ${target.round()} $unit', style: t.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: p, minHeight: 6, backgroundColor: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}

class ConfidenceChip extends StatelessWidget {
  const ConfidenceChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSecondaryContainer)),
    );
  }
}
