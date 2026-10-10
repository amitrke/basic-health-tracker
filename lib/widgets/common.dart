import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A white rounded card with the standard padding.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A card's title row with an optional trailing widget.
class CardHeader extends StatelessWidget {
  const CardHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?trailing,
      ],
    );
  }
}

/// A small grey label above a bold value.
class Stat extends StatelessWidget {
  const Stat({super.key, required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: p.muted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color ?? p.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// The calorie ring: [progress] of 1 is a full circle.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.progress,
    required this.value,
    required this.caption,
    this.size = 150,
  });

  final double progress;
  final String value;
  final String caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          track: p.line,
          color: progress > 1 ? p.burn : p.accent,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: p.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text(
                caption,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
  });

  final double progress;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    final sweep = progress.clamp(0.0, 1.0) * math.pi * 2;
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      base
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// A labelled bar of [value] out of [goal].
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    required this.track,
  });

  final String label;
  final int value;
  final int goal;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fraction = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Dot(color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$value',
                    style: TextStyle(fontWeight: FontWeight.w800, color: p.ink),
                  ),
                  TextSpan(text: ' / $goal g'),
                ],
              ),
              style: TextStyle(color: p.muted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            color: color,
            backgroundColor: track,
          ),
        ),
      ],
    );
  }
}

class Dot extends StatelessWidget {
  const Dot(this.color, {super.key, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// "P 12 · C 30 · F 8" in macro colours, skipping unknown ones.
class MacroLine extends StatelessWidget {
  const MacroLine({super.key, this.protein, this.carbs, this.fat});

  final int? protein;
  final int? carbs;
  final int? fat;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // The light macro colours are too pale for small text on white.
    final carbsText = dark ? p.carbs : const Color(0xFFA8620F);
    final fatText = dark ? p.fat : const Color(0xFF8445B5);
    final parts = [
      if (protein != null) ('P $protein', p.protein),
      if (carbs != null) ('C $carbs', carbsText),
      if (fat != null) ('F $fat', fatText),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      children: [
        for (final (text, color) in parts)
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
      ],
    );
  }
}

/// A tiny line chart with no axes.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.width = 120,
    this.height = 48,
  });

  final List<double> values;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _LinePainter(
          values: values,
          color: context.palette.accent,
          fill: false,
        ),
      ),
    );
  }
}

/// A line chart of [values] over time, with min and max labels.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.values,
    required this.startLabel,
    required this.endLabel,
    required this.formatY,
    this.height = 180,
  });

  final List<double> values;
  final String startLabel;
  final String endLabel;
  final String Function(double) formatY;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final small = TextStyle(
      fontSize: 11,
      color: p.muted,
      fontWeight: FontWeight.w600,
    );
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatY(hi), style: small),
                  Text(formatY(lo), style: small),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomPaint(
                  painter: _LinePainter(
                    values: values,
                    color: p.accent,
                    fill: true,
                    grid: p.line,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(startLabel, style: small),
            Text(endLabel, style: small),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.color,
    required this.fill,
    this.grid,
  });

  final List<double> values;
  final Color color;
  final bool fill;
  final Color? grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const pad = 6.0;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    Offset at(int i) => Offset(
      pad + (values.length == 1 ? w : w * i / (values.length - 1)),
      pad + h * (1 - (values[i] - lo) / span),
    );

    if (grid != null) {
      final g = Paint()
        ..color = grid!
        ..strokeWidth = 1;
      for (final y in [pad, pad + h / 2, pad + h]) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
      }
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    if (fill && values.length > 1) {
      final area = Path.from(path)
        ..lineTo(at(values.length - 1).dx, size.height)
        ..lineTo(at(0).dx, size.height)
        ..close();
      canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.12));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(at(values.length - 1), 4.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.color != color;
}
