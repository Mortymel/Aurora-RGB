import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_led/editors.dart';
import 'package:aurora_led/light_visuals.dart';
import 'package:aurora_led/models.dart';

void main() {
  testWidgets(
    'Contraseña guardada se conserva hasta que el usuario elige cambiar',
    (tester) async {
      String? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordSetting(saved: true, onChanged: (v) => changed = v),
          ),
        ),
      );
      expect(find.text('Contraseña configurada'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(changed, isNull);
      await tester.tap(find.text('Cambiar'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'nueva-clave');
      expect(changed, 'nueva-clave');
      expect(find.textContaining('Borrar'), findsNothing);
    },
  );
  test('Arte de efectos utiliza sus paletas y patrones propios', () {
    List<int> samples(String effect) => List.generate(
      48,
      (i) => effectColor(Light(effect: effect), i / 48, .37).toARGB32(),
    );
    expect(samples('Fuego'), isNot(samples('Oceano')));
    expect(samples('Cometa'), isNot(samples('Respiracion')));
    expect(samples('Atardecer'), isNot(samples('Bosque')));
  });
}
