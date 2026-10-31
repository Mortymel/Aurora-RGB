import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_led/app_store.dart';
import 'package:aurora_led/controller.dart';
import 'package:aurora_led/device_api.dart';
import 'package:aurora_led/main.dart';
import 'package:aurora_led/models.dart';

class SeparateBoards extends DeviceApi {
  final boards = <String, DemoApi>{};
  final writes = <String>[];
  @override
  Future<Json> request(Device device, String route, [Json? body]) {
    if (body != null) writes.add('${device.id}:$route');
    return boards
        .putIfAbsent(device.id, DemoApi.new)
        .request(device, route, body);
  }
}

void main() {
  testWidgets(
    'Una ventana con regreso; MQTT de otra luz no cambia la seleccionada',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const first = Device(
        id: 'one',
        name: 'Escritorio',
        address: 'http://192.168.1.20',
      );
      const second = Device(
        id: 'two',
        name: 'Dormitorio',
        address: 'http://192.168.1.21',
      );
      final api = SeparateBoards();
      final store = MemoryAppStore()
        ..data = {
          'devices': [first.toJson(), second.toJson()],
          'selected': 'one',
        };
      final controller = AuroraController(store: store, api: api);
      await tester.pumpWidget(AuroraApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Escritorio'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('Configurar Dormitorio'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.selected?.id, 'one');
      await tester.tap(find.text('Home Assistant / MQTT'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsOneWidget);
      expect(find.text('Contraseña configurada'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'IP o nombre del broker'),
        '192.168.1.100',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.writes, ['two:config']);
      expect(controller.selected?.id, 'one');
      expect(controller.config?['mqtt_host'], '');
      expect(api.boards['two']!.config['mqtt_host'], '192.168.1.100');
      await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mis luces'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Dialog), findsNothing);
      expect(controller.selected?.id, 'one');
      await tester.tap(find.text('Ajustes'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Escritorio'), findsNothing);
      expect(find.byTooltip('Apagar luz'), findsNothing);
      expect(find.text('Vista compacta'), findsNothing);
      expect(find.text('Al abrir Aurora'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
