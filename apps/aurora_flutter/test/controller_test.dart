import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_led/app_store.dart';
import 'package:aurora_led/controller.dart';
import 'package:aurora_led/device_api.dart';
import 'package:aurora_led/models.dart';

class FakeApi extends DeviceApi {
  final demos = <String, DemoApi>{};
  Completer<Json>? pending;
  bool fail = false;
  final writes = <String>[];
  @override
  Future<Json> request(Device d, String route, [Json? body]) async {
    if (fail) throw const ApiException('Sin conexión');
    if (body != null) writes.add('${d.id}:$route');
    if (route == 'state' && pending != null) {
      final hold = pending!;
      pending = null;
      return hold.future;
    }
    return demos.putIfAbsent(d.id, DemoApi.new).request(d, route, body);
  }
}

void main() {
  const first = Device(
    id: 'first',
    name: 'Uno',
    address: 'http://192.168.1.20',
    password: 'private',
  );
  const second = Device(
    id: 'second',
    name: 'Dos',
    address: 'http://192.168.1.21',
    password: 'private2',
  );
  test(
    'Alta validada, restauración y credenciales conservadas en almacén',
    () async {
      final store = MemoryAppStore(), api = FakeApi();
      final controller = AuroraController(store: store, api: api);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.add(first);
      expect(controller.connected, true);
      expect(controller.selected?.id, 'first');
      final restored = AuroraController(store: store, api: api);
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.selected?.password, 'private');
      expect(restored.config?['count'], 320);
    },
  );
  test('Respuesta vieja de sondeo no contamina otro controlador', () async {
    final api = FakeApi();
    final controller = AuroraController(store: MemoryAppStore(), api: api);
    addTearDown(controller.dispose);
    await controller.add(first);
    final pending = Completer<Json>();
    api.pending = pending;
    final refresh = controller.refresh();
    await Future<void>.delayed(Duration.zero);
    await controller.add(second);
    await controller.command('light', {'brightness': 17});
    pending.complete(await DemoApi().request(first, 'state'));
    await refresh;
    expect(controller.selected?.id, 'second');
    expect(controller.light.brightness, 17);
    expect(api.writes, ['second:light']);
  });
  test(
    'Fallo de conexión conserva estado confirmado y no reenvía órdenes',
    () async {
      final api = FakeApi();
      final c = AuroraController(store: MemoryAppStore(), api: api);
      addTearDown(c.dispose);
      await c.add(first);
      final old = c.light.brightness;
      api.fail = true;
      await expectLater(
        c.command('light', {'brightness': 8}),
        throwsA(isA<ApiException>()),
      );
      expect(c.light.brightness, old);
      expect(c.connected, false);
      api.fail = false;
      await c.refresh();
      expect(c.connected, true);
      expect(api.writes, isEmpty);
    },
  );
  test('Demo: configuración, horarios, temporizador y ambientes', () async {
    final store = MemoryAppStore();
    final controller = AuroraController(store: store);
    addTearDown(controller.dispose);
    await controller.select(Device.demonstration);
    await controller.command('config', {'count': 640});
    expect(controller.light.count, 640);
    await controller.command('timer', {'minutes': 1, 'on': false});
    expect(controller.light.timer, greaterThan(50));
    await controller.command('timer', {'minutes': 0});
    expect(controller.light.timer, 0);
    await controller.saveScene('Mi ambiente');
    expect(controller.scenes.single['name'], 'Mi ambiente');
    expect(store.data['devices'], isEmpty);
  });
}
