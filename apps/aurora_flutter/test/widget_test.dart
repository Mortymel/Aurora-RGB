import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_led/app_store.dart';
import 'package:aurora_led/controller.dart';
import 'package:aurora_led/main.dart';
import 'package:aurora_led/light_visuals.dart';

void main() {
  testWidgets('Aurora nativa: alta, demo, pantallas y visibilidad de la tira', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AuroraController(store: MemoryAppStore());
    const captureKey = Key('native-capture');
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: AuroraApp(controller: controller),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Añadir ESP32'), findsOneWidget);
    await tester.tap(find.text('Probar sin placa'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(StripPreview), findsOneWidget);
    expect(find.byType(ColorOrb), findsOneWidget);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/screenshots').createSync(recursive: true);
      File(
        'build/screenshots/aurora-native.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
    await tester.tap(find.byType(ColorOrb));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código HEX'),
      '#44AAFF',
    );
    await tester.ensureVisible(find.text('Aplicar color'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Aplicar color'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.light.hex, '#44AAFF');
    expect(controller.light.effect, 'Color fijo');
    await tester.tap(find.text('Horarios'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(StripPreview), findsNothing);
    expect(find.text('20:00'), findsWidgets);
    await tester.tap(find.text('Ajustes'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(StripPreview), findsNothing);
    expect(find.text('Home Assistant / MQTT'), findsOneWidget);
    await tester.ensureVisible(find.text('Home Assistant / MQTT'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Home Assistant / MQTT'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('¿Dónde consigo estos datos?'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'IP o nombre del broker'),
      '192.168.1.10',
    );
    await tester.ensureVisible(find.text('Guardar'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Guardar'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.config?['mqtt_host'], '192.168.1.10');
    await tester.tap(find.text('Efectos'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(StripPreview), findsOneWidget);
    expect(find.text('Color fijo'), findsWidgets);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(320, 740);
    await tester.tap(find.text('Mi luz'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  test('Esfera mantiene proporción de canales al sombrear', () {
    const color = Color(0xff44aaff);
    final result = shade(color, .6);
    expect(result.r / result.b, closeTo(color.r / color.b, .01));
    expect(result.g / result.b, closeTo(color.g / color.b, .01));
  });
}
