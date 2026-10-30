import 'dart:math' as math;
import 'package:flutter/material.dart';

class ColorWheel extends StatelessWidget {
  const ColorWheel({super.key, required this.color, required this.onChanged});
  final Color color;
  final ValueChanged<Color> onChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = math.min(250.0, constraints.maxWidth);
      void pick(Offset position) {
        final offset = position - Offset(size / 2, size / 2);
        final hue =
            (math.atan2(offset.dy, offset.dx) * 180 / math.pi + 360) % 360;
        final saturation = (offset.distance / (size / 2)).clamp(0.0, 1.0);
        onChanged(
          HSVColor.fromAHSV(
            1,
            hue,
            saturation,
            HSVColor.fromColor(color).value == 0
                ? 1
                : HSVColor.fromColor(color).value,
          ).toColor(),
        );
      }

      return Center(
        child: Semantics(
          label: 'Rueda de color: toca o arrastra para elegir un tono',
          child: GestureDetector(
            onPanDown: (d) => pick(d.localPosition),
            onPanUpdate: (d) => pick(d.localPosition),
            child: CustomPaint(
              size: Size.square(size),
              painter: _WheelPainter(color),
            ),
          ),
        ),
      );
    },
  );
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size,
        center = bounds.center,
        radius = size.width / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Colors.red,
            Colors.yellow,
            Colors.green,
            Colors.cyan,
            Colors.blue,
            Color(0xffff00ff),
            Colors.red,
          ],
        ).createShader(bounds),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0x00ffffff)],
        ).createShader(bounds),
    );
    final hsv = HSVColor.fromColor(color), angle = hsv.hue * math.pi / 180;
    final cursor =
        center +
        Offset(math.cos(angle), math.sin(angle)) *
            (radius * hsv.saturation * .96);
    canvas.drawCircle(cursor, 11, Paint()..color = Colors.black38);
    canvas.drawCircle(cursor, 8, Paint()..color = color);
    canvas.drawCircle(
      cursor,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.color != color;
}
