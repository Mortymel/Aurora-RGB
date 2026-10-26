import 'dart:async';
import 'package:flutter/material.dart';
import 'ble_provisioning.dart';
import 'provisioning_protocol.dart';
import 'device_store.dart';
import 'lan_device_wizard.dart';
export 'lan_device_wizard.dart' show DiscoveredController, LanDeviceWizard;

class AddDeviceWizard extends StatefulWidget {
  final ProvisioningTransport? provisioning;
  final Future<List<DiscoveredController>> Function()? discoverControllers;
  const AddDeviceWizard({super.key, this.provisioning, this.discoverControllers});
  @override
  State<AddDeviceWizard> createState() => _AddDeviceWizardState();
}

class _AddDeviceWizardState extends State<AddDeviceWizard> {
  late final ProvisioningTransport transport = widget.provisioning ?? BleProvisioning();
  final form = GlobalKey<FormState>();
  final ssid = TextEditingController(), password = TextEditingController(), name = TextEditingController(), pixels = TextEditingController();
  List<BleController> devices = [];
  BleController? selected;
  bool busy = false, showPassword = false;
  String? error;
  String progress = '';
  int generation = 0;

  Future<void> scan() async {
    final current = ++generation;
    setState(() { busy = true; error = null; devices = []; progress = 'Buscando ESP32 cercanas…'; });
    try {
      final result = await transport.scan();
      if (mounted && current == generation) setState(() => devices = result);
    } catch (_) {
      if (mounted && current == generation) setState(() => error = 'No se pudo buscar. Activa Bluetooth, concede los permisos y, en Android 11 o anterior, activa la ubicación.');
    } finally {
      if (mounted && current == generation) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || selected == null) return;
    final config = ProvisioningConfig(ssid: ssid.text, password: password.text, name: name.text, pixels: int.parse(pixels.text));
    try { config.encode('validation'); } on FormatException catch (e) { setState(() => error = e.message); return; }
    final current = ++generation;
    setState(() { busy = true; error = null; progress = 'Enviando configuración y comprobando WiFi…'; });
    try {
      final result = await transport.provision(selected!, config);
      if (!mounted || current != generation) return;
      password.clear();
      Navigator.pop<StudioDevice>(context, result.toDevice());
    } catch (e) {
      if (mounted && current == generation) setState(() => error = e is StateError ? e.message.toString() : e is TimeoutException ? e.message : 'No se pudo configurar. Acerca el teléfono a la ESP32, acepta el emparejamiento Bluetooth y vuelve a intentar.');
    } finally {
      if (mounted && current == generation) setState(() => busy = false);
    }
  }

  Future<void> cancel() async {
    generation++;
    try { await transport.cancel(); } finally {
      if (mounted) setState(() { busy = false; progress = ''; });
    }
  }

  Future<void> addOnWifi() async {
    final device = await Navigator.push<StudioDevice>(context, MaterialPageRoute(builder: (_) => LanDeviceWizard(discoverControllers: widget.discoverControllers)));
    if (mounted && device != null) Navigator.pop<StudioDevice>(context, device);
  }

  @override
  void dispose() {
    generation++;
    unawaited(transport.cancel().catchError((Object _) {}));
    ssid.dispose(); password.dispose(); name.dispose(); pixels.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Añadir tira')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Configura tu ESP32', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      const Text('Enciende la ESP32 con el firmware 0.8.0. Bluetooth permite enviarle el WiFi, el nombre y la cantidad de LED.'),
      const SizedBox(height: 12),
      if (selected == null) ...[
        FilledButton.icon(onPressed: busy ? null : scan, icon: const Icon(Icons.bluetooth_searching), label: const Text('Buscar por Bluetooth')),
        for (final device in devices) Card(child: ListTile(
          leading: const Icon(Icons.lightbulb_outline), title: Text(device.name), subtitle: const Text('ESP32 lista para configurar'),
          onTap: busy ? null : () => setState(() { selected = device; error = null; }),
        )),
        if (!busy && devices.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Si no aparece, mantén BOOT pulsado durante 3 segundos después de encenderla. El modo de configuración dura 10 minutos.')),
        TextButton(onPressed: busy ? null : addOnWifi, child: const Text('Ya está conectada al WiFi')),
      ] else Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('ESP32: ${selected!.name}'),
        const SizedBox(height: 12),
        TextFormField(controller: ssid, enabled: !busy, decoration: const InputDecoration(labelText: 'Red WiFi (2,4 GHz)'),
          validator: (v) => v == null || v.isEmpty ? 'Introduce el nombre de tu red' : null),
        const SizedBox(height: 12),
        TextFormField(controller: password, enabled: !busy, obscureText: !showPassword, autocorrect: false, enableSuggestions: false,
          decoration: InputDecoration(labelText: 'Contraseña WiFi', helperText: 'Déjala vacía solo si tu red es abierta.', suffixIcon: IconButton(
            tooltip: showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña', onPressed: () => setState(() => showPassword = !showPassword), icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility)))),
        const SizedBox(height: 12),
        TextFormField(controller: name, enabled: !busy, decoration: const InputDecoration(labelText: 'Nombre de la tira'), validator: (v) => v == null || v.trim().isEmpty ? 'Introduce un nombre' : null),
        const SizedBox(height: 12),
        TextFormField(controller: pixels, enabled: !busy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad de LED / píxeles', helperText: 'Cuenta los grupos si tu tira los utiliza.'),
          validator: (v) { final count = int.tryParse(v ?? ''); return count == null || count < 1 || count > 1024 ? 'Introduce entre 1 y 1024 píxeles' : null; }),
        const SizedBox(height: 20),
        FilledButton(onPressed: busy ? null : save, child: const Text('Configurar y añadir tira')),
        TextButton(onPressed: busy ? null : () => setState(() { selected = null; password.clear(); error = null; }), child: const Text('Elegir otra ESP32')),
        const Text('Acepta el emparejamiento Bluetooth si Android lo solicita. El teléfono debe estar en la misma red WiFi para controlar la tira después.'),
      ])),
      if (busy) ...[
        const SizedBox(height: 12), const LinearProgressIndicator(), Text(progress),
        TextButton(onPressed: cancel, child: const Text('Cancelar operación')),
        const Text('Si los datos ya se enviaron, la ESP32 puede terminar la conexión aunque canceles en el teléfono.'),
      ],
      if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(error!, style: const TextStyle(color: Colors.orangeAccent))),
    ])),
  );
}
