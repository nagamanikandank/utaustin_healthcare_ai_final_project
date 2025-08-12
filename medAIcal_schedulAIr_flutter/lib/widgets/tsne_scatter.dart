import 'package:flutter/material.dart';
import '../core/models/patient.dart';

class TsneScatter extends StatelessWidget {
  final List<KeywordPoint> points;

  const TsneScatter({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _ScatterPainter(points),
        child: Container(),
      ),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  final List<KeywordPoint> points;
  _ScatterPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint axisPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 1;

    final double padding = 16;
    final Rect plot = Rect.fromLTWH(
        padding, padding, size.width - 2 * padding, size.height - 2 * padding);

    // Draw border
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(plot, const Radius.circular(8)),
      borderPaint,
    );

    // Axes at 0 (middle)
    final double x0 = plot.left + plot.width / 2;
    final double y0 = plot.top + plot.height / 2;
    canvas.drawLine(Offset(plot.left, y0), Offset(plot.right, y0), axisPaint);
    canvas.drawLine(Offset(x0, plot.top), Offset(x0, plot.bottom), axisPaint);

    // Draw points and labels
    final Paint pointPaint = Paint()..color = const Color(0xFF1565C0);
    for (final p in points) {
      // Normalize -1..1 -> plot
      final double px = plot.left + ((p.x + 1) / 2) * plot.width;
      final double py = plot.top + ((1 - (p.y + 1) / 2)) * plot.height;

      canvas.drawCircle(Offset(px, py), 4, pointPaint);

      final textSpan = TextSpan(
        text: ' ${p.label}',
        style: const TextStyle(color: Colors.black87, fontSize: 12),
      );
      final tp = TextPainter(
          text: textSpan, textDirection: TextDirection.ltr, maxLines: 1);
      tp.layout(minWidth: 0, maxWidth: plot.width);
      tp.paint(canvas, Offset(px + 6, py - 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
