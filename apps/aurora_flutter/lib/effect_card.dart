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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: effectSwatch(name, light),
                      ),
                    ),
                  ),
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

// Static swatches: no animation or per-pixel effect simulation in the gallery.
List<Color> effectSwatch(String name, Light light) {
  final index = effectNames.indexOf(name), base = rgb(light);
  if (index == 0) return [base, base];
  if (index == 1) {
    return [
      Colors.red,
      Colors.yellow,
      Colors.green,
      Colors.cyan,
      Colors.blue,
      Colors.purple,
    ];
  }
  if (index == 2 || index == 23) {
    return [
      Colors.purple,
      Colors.blue,
      Colors.cyan,
      Colors.green,
      Colors.yellow,
      Colors.red,
    ];
  }
  if ([3, 4, 5, 7, 11, 12, 13, 14, 30].contains(index)) {
    return [shade(base, .12), base, shade(base, .45)];
  }
  final paletteIndex = switch (index) {
    8 || 18 || 25 => 3,
    9 || 19 => 4,
    10 || 17 || 22 => 2,
    15 => 0,
    16 => 1,
    26 => 5,
    27 => 6,
    28 => 7,
    _ => 0,
  };
  if (index == 20 || index == 29 || index == 31) {
    return [
      const Color(0xff6436cc),
      const Color(0xffe762c1),
      const Color(0xff49d3d7),
    ];
  }
  if (index == 21) {
    return [
      const Color(0xff110d2e),
      const Color(0xff674393),
      const Color(0xffb8a3dd),
    ];
  }
  return palettes[paletteIndex];
}
