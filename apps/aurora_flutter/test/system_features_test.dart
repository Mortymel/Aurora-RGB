import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_led/controller.dart';
import 'package:aurora_led/app_store.dart';
import 'package:aurora_led/models.dart';

void main() {
  test(
    'Deshacer recupera color, efecto, brillo y encendido anteriores',
    () async {
      final c = AuroraController(store: MemoryAppStore());
      addTearDown(c.dispose);
      await c.select(Device.demonstration);
      final previous = c.light.scene;
      await c.command('light', {'state': 'OFF', 'brightness': 22});
      await c.undo();
      expect(c.light.scene, previous);
      expect(c.light.on, true);
    },
  );
  test('Vista en vivo agrupa movimientos y mantiene el último color', () async {
    final c = AuroraController(store: MemoryAppStore());
    addTearDown(c.dispose);
    await c.select(Device.demonstration);
    c.beginLive();
    for (var i = 0; i < 100; i++) {
      c.stageLive({
        'color': {'r': i, 'g': 0, 'b': 255},
      });
    }
    await c.flushLive();
    expect(c.light.r, 99);
    expect(c.light.b, 255);
    c.endLive();
  });
  test('Horarios contradictorios se rechazan sin desconectar', () async {
    final c = AuroraController(store: MemoryAppStore());
    addTearDown(c.dispose);
    await c.select(Device.demonstration);
    final rules = List.generate(
      4,
      (i) => {'enabled': i < 2, 'on': i == 0, 'time': '20:00', 'days': 127},
    );
    await expectLater(
      c.command('config', {'schedules': rules}),
      throwsFormatException,
    );
    expect(c.connected, true);
    expect((c.config!['schedules'] as List)[0]['enabled'], false);
  });
}
