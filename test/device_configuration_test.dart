import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esp32_rgb_studio/device_store.dart';
import 'package:esp32_rgb_studio/main.dart';
import 'package:esp32_rgb_studio/add_device_wizard.dart';
import 'package:esp32_rgb_studio/device_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Each controller retains its own count; legacy devices have no invented count', () async {
    await DeviceStore.save(const [
      StudioDevice(id:'a',name:'Salón',host:'192.168.1.10',pixels:1),
      StudioDevice(id:'b',name:'Pasillo',host:'192.168.1.11',pixels:1024),
    ]);
    final devices=await DeviceStore.load();
    expect(devices.map((d)=>d.pixels),[1,1024]);
    expect(StudioDevice.fromJson({'id':'legacy','host':'192.168.1.12'}).pixels,isNull);
  });

  testWidgets('Discovery pre-fills the address and controller pixel count', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AddDeviceWizard(
      discoverControllers: () async => [
        DiscoveredController('192.168.1.20', LedState.fromJson({'pixels': 120})),
      ],
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('120 píxeles detectados'));
    await tester.pumpAndSettle();
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields[1].controller!.text, '192.168.1.20');
    expect(fields[1].readOnly, isTrue);
    expect(fields[2].controller!.text, '120');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Manual mode ignores a late discovery result', (tester) async {
    final discovery = Completer<List<DiscoveredController>>();
    await tester.pumpWidget(MaterialApp(home: AddDeviceWizard(
      discoverControllers: () => discovery.future,
    )));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.ensureVisible(find.text('Configuración manual'));
    await tester.tap(find.text('Configuración manual'));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    discovery.complete([
      DiscoveredController('192.168.1.20', LedState.fromJson({'pixels': 120})),
    ]);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3));
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields[1].controller!.text, isEmpty);
    expect(fields[2].controller!.text, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Closing the wizard ignores a late discovery failure', (tester) async {
    final discovery = Completer<List<DiscoveredController>>();
    await tester.pumpWidget(MaterialApp(home: AddDeviceWizard(
      discoverControllers: () => discovery.future,
    )));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    discovery.completeError(StateError('Network unavailable'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Adding an ESP32 validates, sends and saves its LED count', (tester) async {
    var count=1;
    final posted=<Map<String,String>>[];
    await http.runWithClient(() async {
      await tester.pumpWidget(StudioApp(discoverControllers: () async => []));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir tira'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Configuración manual'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField,'Nombre de la tira'),'Salón');
      await tester.enterText(find.byType(TextFormField).at(1),'192.168.1.10');
      for(final invalid in ['', '0', '1025', '2.5', 'abc']) {
        await tester.enterText(find.byType(TextFormField).at(2),invalid);
        await tester.ensureVisible(find.text('Guardar tira'));
        await tester.tap(find.text('Guardar tira'));
        await tester.pumpAndSettle();
        expect(find.text('Entre 1 y 1024 píxeles'),findsOneWidget);
        expect(posted,isEmpty);
      }
      await tester.enterText(find.byType(TextFormField).at(2),'60');
      await tester.tap(find.text('Guardar tira'));
      await tester.pumpAndSettle();
      expect(posted.single,{'pixels':'60'});
      expect(count,60);
      expect((await DeviceStore.load()).single.pixels,60);
      expect(find.text('Conectado'),findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink()); // Dispose the polling timer.
      await tester.pumpAndSettle();
    }, () => MockClient((request) async {
      if(request.method=='POST') {
        posted.add(request.bodyFields);
        count=int.parse(request.bodyFields['pixels']!);
      }
      return http.Response(jsonEncode({'power':true,'pixels':count}),200,
        headers:{'content-type':'application/json'});
    }));
  });
}
