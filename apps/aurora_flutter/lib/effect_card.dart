import 'package:flutter/material.dart';
import 'light_visuals.dart';
import 'models.dart';

class EffectCard extends StatelessWidget {
  const EffectCard({
    super.key,
    required this.name,
    required this.light,
    required this.selected,
    required this.favorite,
    required this.onFavorite,
    this.onApply,
  });
  final String name;
  final Light light;
  final bool selected, favorite;
  final VoidCallback onFavorite;
  final VoidCallback? onApply;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        width: 2,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Semantics(
              label: 'Aplicar $name',
              button: true,
              child: InkWell(
                onTap: onApply,
                child: SizedBox(
                  height: 104,
                  width: double.infinity,
                  child: CustomPaint(painter: EffectArtwork(name, light)),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                tooltip: favorite
                    ? 'Quitar favorito $name'
                    : 'Añadir favorito $name',
                onPressed: onFavorite,
                icon: Icon(
                  favorite ? Icons.star : Icons.star_outline,
                  size: 19,
                ),
              ),
            ),
            if (selected)
              const Positioned(
                bottom: 8,
                left: 10,
                child: Icon(Icons.check_circle, color: Colors.white, size: 20),
              ),
          ],
        ),
        InkWell(
          onTap: onApply,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  effectGroup(effectNames.indexOf(name)),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// A spatial/time sample of the actual preview renderer, rather than unrelated hues.
class EffectArtwork extends CustomPainter {
  EffectArtwork(this.name, this.light);
  final String name;
  final Light light;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff090c16),
    );
    final sample = Light(
      on: true,
      brightness: 255,
      r: light.r,
      g: light.g,
      b: light.b,
      effect: name,
    );
    for (var row = 0; row < 12; row++) {
      for (var col = 0; col < 48; col++) {
        final color = effectColor(sample, col / 48, .24 + row * .057);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              col * size.width / 48,
              row * size.height / 12,
              size.width / 48 + 1,
              size.height / 12 + 1,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = color,
        );
      }
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x66000000)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant EffectArtwork old) =>
      old.name != name || old.light.color.toString() != light.color.toString();
}
