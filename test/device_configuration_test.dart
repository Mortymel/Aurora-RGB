import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esp32_rgb_studio/device_store.dart';
import 'package:esp32_rgb_studio/main.dart';

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

  testWidgets('Adding an ESP32 validates, sends and saves its LED count', (tester) async {
    var count=1;
    final posted=<Map<String,String>>[];
    await http.runWithClient(() async {
      await tester.pumpWidget(const StudioApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir tira'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField,'Nombre'),'Salón');
      await tester.enterText(find.byType(TextFormField).at(0),'192.168.1.10');
      for(final invalid in ['', '0', '1025', '2.5', 'abc']) {
        await tester.enterText(find.byType(TextFormField).at(1),invalid);
        await tester.ensureVisible(find.text('Guardar controlador'));
        await tester.tap(find.text('Guardar controlador'));
        await tester.pumpAndSettle();
        expect(find.text('Introduce un entero entre 1 y 1024'),findsOneWidget);
        expect(posted,isEmpty);
      }
      await tester.enterText(find.byType(TextFormField).at(1),'60');
      await tester.tap(find.text('Guardar controlador'));
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
