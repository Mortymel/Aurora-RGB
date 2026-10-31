import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

Color rgb(Light l) => Color.fromARGB(255, l.r, l.g, l.b);
Color shade(Color c, double factor) => Color.fromARGB(
  255,
  (c.r * 255 * factor).round().clamp(0, 255),
  (c.g * 255 * factor).round().clamp(0, 255),
  (c.b * 255 * factor).round().clamp(0, 255),
);
const palettes = [
  [Color(0xff21004b), Color(0xffd81b68), Color(0xffff732b), Color(0xffffd09a)],
  [Color(0xff4d164f), Color(0xffd84f9f), Color(0xffffa6c6), Color(0xffffe8d7)],
  [Color(0xff001c12), Color(0xff00683f), Color(0xff59b943), Color(0xffb5db5c)],
  [Color(0xff150005), Color(0xff8a0613), Color(0xffff3e08), Color(0xffffc02a)],
  [Color(0xff01071e), Color(0xff042f6b), Color(0xff007eaa), Color(0xff5cebd8)],
  [Color(0xff8b0010), Color(0xffe52b21), Color(0xffffe8ba), Color(0xff07824b)],
  [Color(0xffff428d), Color(0xffffdce9), Color(0xff7ee8ee), Color(0xfff9f4ff)],
  [Color(0xff180e44), Color(0xff9d306e), Color(0xffff7d4d), Color(0xffffe8b0)],
];
Color palette(int index, double position) {
  final p = (position % 1) * 4, i = p.floor();
  return Color.lerp(
    palettes[index][i % 4],
    palettes[index][(i + 1) % 4],
    p - i,
  )!;
}

Color hue(double h) => HSVColor.fromAHSV(1, (h % 1) * 360, .9, 1).toColor();
Color effectColor(Light light, double x, double t) {
  final i = effectNames.indexOf(light.effect),
      base = rgb(light),
      wave = (math.sin(t * math.pi * 2) + 1) / 2;
  double trail(double head) =>
      math.pow((1 - ((head - x) % 1) * 6).clamp(0, 1), 2).toDouble();
  switch (i) {
    case 0:
      return base;
    case 1:
      return hue(x);
    case 2:
      return hue(x - t * .2);
    case 3:
      return shade(base, .08 + .92 * wave);
    case 4:
      return shade(base, trail(t % 1));
    case 5:
      return ((x * 60 - t * 8).floor() % 3) == 0 ? base : Colors.black;
    case 6:
      return shade(
        hue(x + t * .13),
        math.pow((math.sin(x * 173 + t * 9) + 1) / 2, 16).toDouble(),
      );
    case 7:
      return shade(
        base,
        math.pow((math.sin(x * 233 + t * 13) + 1) / 2, 24).toDouble(),
      );
    case 8:
      return palette(3, (x * .2 + math.sin(x * 25 + t * 6) * .15 + .55) % 1);
    case 9:
      return palette(4, x * .4 + t * .08);
    case 10:
      return Color.lerp(
        const Color(0xff25dc9e),
        const Color(0xff9456da),
        (math.sin(x * 12 + t) + 1) / 2,
      )!;
    case 11:
      return shade(base, (1 - (x - wave).abs() * 12).clamp(0, 1));
    case 12:
      return shade(base, .12 + .88 * x);
    case 13:
      return shade(base, .1 + .9 * (math.sin(x * 18 - t * 5) + 1) / 2);
    case 14:
      return (t * 5).floor() % 2 == 0 ? base : Colors.black;
    case 15:
      return palette(0, x * .75 + t * .04);
    case 16:
      return palette(1, x * .8 + t * .025);
    case 17:
      return palette(2, x * .6 + t * .03);
    case 18:
      return palette(3, x * .55 + math.sin(t * .6 + x * 5) * .15);
    case 19:
      return palette(4, x * .8 + t * .04);
    case 20:
      return hue((math.sin(x * 8 + t) + math.sin(x * 14 - t * .8) + 2) / 4);
    case 21:
      return Color.lerp(
        const Color(0xff211149),
        const Color(0xffc4a2ef),
        math.pow((math.sin(x * 155 + t) + 1) / 2, 25).toDouble(),
      )!;
    case 22:
      return Color.lerp(
        const Color(0xff082719),
        const Color(0xffffda70),
        math.pow((math.sin(x * 132 + t * 2) + 1) / 2, 20).toDouble(),
      )!;
    case 23:
      return shade(hue(x - t * .2), trail(t % 1));
    case 24:
      return shade(
        hue(x + t * .1),
        math.max(
          trail(t % 1),
          math.max(trail((t + .33) % 1), trail((t + .66) % 1)),
        ),
      );
    case 25:
      return shade(
        const Color(0xffffb13f),
        math.pow((math.sin(x * 170 + t * 6) + 1) / 2, 12).toDouble(),
      );
    case 26:
      return palette(5, x + t * .04);
    case 27:
      return palette(6, x + t * .06);
    case 28:
      return palette(7, x * .5 + t * .02);
    case 29:
      return hue(x + math.sin(x * 9 + t * 3) * .15 + t * .08);
    case 30:
      return Color.lerp(
        shade(base, trail(t % 1)),
        shade(hue(t * .07), trail((1 - t) % 1)),
        .5,
      )!;
    case 31:
      return Color.lerp(hue(t * .06), hue(t * .06 + .4), x)!;
    default:
      return base;
  }
}

class ColorOrb extends StatelessWidget {
  const ColorOrb({
    super.key,
    required this.color,
    required this.onTap,
    this.size = 190,
    this.showLabel = true,
  });
  final double size;
  final bool showLabel;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cambiar color de la luz',
    button: true,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .22),
              blurRadius: 32,
              offset: const Offset(0, 15),
            ),
          ],
          gradient: RadialGradient(
            center: const Alignment(-.4, -.45),
            radius: 1,
            colors: [color, shade(color, .82), shade(color, .39)],
            stops: const [0, .42, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: .45)),
                  ),
                ),
              ),
            ),
            if (showLabel)
              Align(
                alignment: const Alignment(0, .65),
                child: Text(
                  'Elegir color',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.computeLuminance() > .55
                        ? const Color(0xff202233)
                        : Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class StripPreview extends StatefulWidget {
  const StripPreview({super.key, required this.light});
  final Light light;
  @override
  State<StripPreview> createState() => _StripPreviewState();
}

class _StripPreviewState extends State<StripPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 120),
  )..repeat();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      animation.stop();
    } else if (!animation.isAnimating) {
      animation.repeat();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'VISTA PREVIA',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.6),
                ),
              ),
              Text(
                '${widget.light.count} px',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              height: 45,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) => CustomPaint(
                  painter: _StripPainter(widget.light, animation.value * 120),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.light.on ? widget.light.effect : 'Luz apagada',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                widget.light.on
                    ? '${(widget.light.brightness / 255 * 100).round()}%'
                    : 'Apagada',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StripPainter extends CustomPainter {
  _StripPainter(this.light, this.time);
  final Light light;
  final double time;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff090c16),
    );
    for (var i = 0; i < 72; i++) {
      final color = shade(
        effectColor(light, i / 72, time * (.08 + light.speed * .025)),
        light.on ? light.brightness / 255 : 0,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * size.width / 72,
            size.height * .28,
            size.width / 72 * .85,
            size.height * .44,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StripPainter old) =>
      old.light != light || old.time != time;
}
