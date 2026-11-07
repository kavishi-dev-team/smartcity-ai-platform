import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../models/air_quality_model.dart';
import '../providers/safety_provider.dart';
import '../utils/safety_formatters.dart';
import '../widgets/aqi_indicator.dart';
import '../widgets/safety_message_view.dart';

class AirQualityHistoryScreen extends StatefulWidget {
  const AirQualityHistoryScreen({super.key});

  @override
  State<AirQualityHistoryScreen> createState() =>
      _AirQualityHistoryScreenState();
}

class _AirQualityHistoryScreenState extends State<AirQualityHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SafetyProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SafetyProvider>();
    final area = p.selectedReading?.area ?? 'Air Quality';

    return Scaffold(
      appBar: AppBar(title: Text('$area - History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'daily', label: Text('Daily')),
              ButtonSegment(value: 'weekly', label: Text('Weekly')),
              ButtonSegment(value: 'monthly', label: Text('Monthly')),
            ],
            selected: {p.historyPeriod},
            onSelectionChanged: (s) => p.loadHistory(period: s.first),
          ),
          const SizedBox(height: 16),
          _content(p),
        ],
      ),
    );
  }

  Widget _content(SafetyProvider p) {
    if (p.isLoadingHistory) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (p.historyError != null) {
      return SizedBox(
        height: 300,
        child: SafetyMessageView(
          icon: Icons.cloud_off,
          message: p.historyError!,
          actionLabel: 'Try again',
          onAction: () => p.loadHistory(),
        ),
      );
    }
    final h = p.history;
    if (h == null || h.points.isEmpty) {
      return const SizedBox(
        height: 300,
        child: SafetyMessageView(
          icon: Icons.show_chart,
          message: 'No history available.',
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Average', value: h.averageAqi)),
            Expanded(child: _StatCard(label: 'Lowest', value: h.minAqi)),
            Expanded(child: _StatCard(label: 'Highest', value: h.maxAqi)),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(h.period),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _AqiLineChartPainter(
                      points: h.points,
                      period: h.period,
                      lineColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _title(String period) {
    switch (period) {
      case 'weekly':
        return 'Daily average AQI - last 7 days';
      case 'monthly':
        return 'Daily average AQI - last 30 days';
      default:
        return 'AQI - last 24 hours';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: aqiColor(value),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple line chart, no extra packages needed.
class _AqiLineChartPainter extends CustomPainter {
  final List<AirQualityHistoryPoint> points;
  final String period;
  final Color lineColor;

  _AqiLineChartPainter({
    required this.points,
    required this.period,
    required this.lineColor,
  });

  TextPainter _label(String text) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10, color: AppColors.muted),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  String _xLabel(DateTime t) =>
      period == 'daily' ? formatHour(t) : formatShortDate(t);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 24.0;

    final w = size.width - left - right;
    final h = size.height - top - bottom;
    if (w <= 0 || h <= 0 || points.isEmpty) return;

    final highest = points.map((p) => p.aqi).reduce(math.max);
    final maxY = math.max(100, (highest / 50).ceil() * 50).toDouble();

    // Grid lines + y labels
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + h - (h * i / 4);
      canvas.drawLine(Offset(left, y), Offset(left + w, y), gridPaint);
      final tp = _label((maxY * i / 4).round().toString());
      tp.paint(canvas, Offset(left - tp.width - 6, y - tp.height / 2));
    }

    Offset pos(int i) {
      final x = points.length == 1
          ? left + w / 2
          : left + w * i / (points.length - 1);
      final y = top + h - (h * points[i].aqi / maxY);
      return Offset(x, y);
    }

    // Line + soft fill underneath
    final first = pos(0);
    final line = Path()..moveTo(first.dx, first.dy);
    for (var i = 1; i < points.length; i++) {
      final o = pos(i);
      line.lineTo(o.dx, o.dy);
    }
    final last = pos(points.length - 1);
    final fill = Path.from(line)
      ..lineTo(last.dx, top + h)
      ..lineTo(first.dx, top + h)
      ..close();

    canvas.drawPath(fill, Paint()..color = lineColor.withValues(alpha: 0.12));
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Dots when there are few points
    if (points.length <= 12) {
      for (var i = 0; i < points.length; i++) {
        canvas.drawCircle(pos(i), 4, Paint()..color = lineColor);
        canvas.drawCircle(pos(i), 2, Paint()..color = Colors.white);
      }
    }

    // X labels: first and last
    final firstLabel = _label(_xLabel(points.first.timestamp));
    firstLabel.paint(canvas, Offset(left, top + h + 6));
    if (points.length > 1) {
      final lastLabel = _label(_xLabel(points.last.timestamp));
      lastLabel.paint(canvas, Offset(left + w - lastLabel.width, top + h + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _AqiLineChartPainter old) =>
      old.points != points || old.period != period;
}
