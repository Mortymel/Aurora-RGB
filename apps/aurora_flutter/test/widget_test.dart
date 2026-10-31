import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_led/app_store.dart';
import 'package:aurora_led/controller.dart';
import 'package:aurora_led/main.dart';
import 'package:aurora_led/light_visuals.dart';
import 'package:aurora_led/effect_card.dart';

void main() {
  setUpAll(() async {
    final fonts = Directory(
      '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts',
    );
    for (final spec in [
      ('Roboto', 'roboto-regular.ttf'),
      ('MaterialIcons', 'materialicons-regular.otf'),
    ]) {
      final file = File('${fonts.path}/${spec.$2}');
      if (file.existsSync()) {
        final loader = FontLoader(spec.$1)
          ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
        await loader.load();
      }
    }
  });
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
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Ajuste preciso · RGB / HEX'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Ajuste preciso · RGB / HEX'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código HEX'),
      '#44AAFF',
    );
    await tester.ensureVisible(find.text('Aplicar color'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Aplicar color'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.light.hex, '#44AAFF');
    expect(controller.light.effect, 'Color fijo');
    await tester.tap(find.text('Horarios'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(StripPreview), findsNothing);
    expect(find.text('20:00'), findsWidgets);
    await tester.tap(find.text('Ajustes'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(StripPreview), findsNothing);
    expect(find.text('Home Assistant / MQTT'), findsNothing);
    expect(find.byTooltip('Apagar luz'), findsNothing);
    await tester.ensureVisible(find.text('Administrar mis luces'));
    await tester.tap(find.text('Administrar mis luces'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Configurar Escritorio'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Home Assistant / MQTT'), findsOneWidget);
    await tester.ensureVisible(find.text('Home Assistant / MQTT'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Home Assistant / MQTT'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('¿Dónde consigo estos datos?'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'IP o nombre del broker'),
      '192.168.1.10',
    );
    await tester.ensureVisible(find.text('Guardar'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Guardar'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.config?['mqtt_host'], '192.168.1.10');
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Efectos'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(StripPreview), findsNothing);
    expect(find.text('Color fijo'), findsWidgets);
    expect(find.byType(EffectCard).evaluate().length, lessThan(32));
    final gallery = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    gallery.position.jumpTo(gallery.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Gradiente vivo'), findsOneWidget);
    await tester.tap(find.text('Gradiente vivo'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.light.effect, 'Gradiente vivo');
    gallery.position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/screenshots/aurora-effects.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
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
