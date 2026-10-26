import 'dart:async';
import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'device_api.dart';
import 'device_store.dart';

class DiscoveredController {
  final String host;
  final LedState state;
  const DiscoveredController(this.host, this.state);
}

class LanDeviceWizard extends StatefulWidget {
  const LanDeviceWizard({super.key, this.discoverControllers});
  final Future<List<DiscoveredController>> Function()? discoverControllers;
  @override
  State<LanDeviceWizard> createState() => _LanDeviceWizardState();
}

class _LanDeviceWizardState extends State<LanDeviceWizard> {
  final name = TextEditingController();
  final ip = TextEditingController();
  final pixels = TextEditingController();
  final form = GlobalKey<FormState>();
  final found = <DiscoveredController>[];
  bool scanning = false;
  bool manual = false;
  String? error;
  DiscoveredController? selected;
  int scanGeneration = 0;
  MDnsClient? activeMdns;

  void cancelScan() {
    scanGeneration++;
    activeMdns?.stop();
    activeMdns = null;
  }

  void useManualConfiguration() {
    cancelScan();
    setState(() { scanning = false; manual = true; selected = null; });
  }

  @override
  void initState() {
    super.initState();
    scan();
  }

  Future<void> scan() async {
    cancelScan();
    final generation = scanGeneration;
    setState(() { scanning = true; error = null; found.clear(); });
    final discover = widget.discoverControllers;
    if (discover != null) {
      try {
        final devices = await discover();
        if (mounted && generation == scanGeneration) {
          setState(() => found.addAll(devices));
        }
      } catch (_) {
        if (mounted && generation == scanGeneration) {
          setState(() => error = 'No se pudo buscar en esta red. Usa la configuración manual.');
        }
      } finally {
        if (mounted && generation == scanGeneration) setState(() => scanning = false);
      }
      return;
    }
    final mdns = MDnsClient();
    activeMdns = mdns;
    try {
      await mdns.start();
      if (!mounted || generation != scanGeneration) return;
      final hosts = <String>{};
      final services = mdns.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_http._tcp.local'),
      );
      await for (final ptr in services.timeout(
        const Duration(seconds: 6),
        onTimeout: (sink) => sink.close(),
      )) {
        if (!mounted || generation != scanGeneration) break;
        if (!ptr.domainName.toLowerCase().contains('mortys-')) continue;
        await for (final srv in mdns.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        ).timeout(const Duration(seconds: 2), onTimeout: (sink) => sink.close())) {
          await for (final addr in mdns.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          ).timeout(const Duration(seconds: 2), onTimeout: (sink) => sink.close())) {
            final host = addr.address.address;
            if (!hosts.add(host)) continue;
            try {
              final state = await DeviceApi(host).getState();
              if (mounted && generation == scanGeneration) {
                setState(() => found.add(DiscoveredController(host, state)));
              }
            } catch (_) { /* Ignore unrelated or unreachable services. */ }
          }
        }
      }
    } catch (_) {
      if (mounted && generation == scanGeneration) {
        setState(() => error = 'No se pudo buscar en esta red. Usa la configuración manual.');
      }
    } finally {
      mdns.stop();
      if (identical(activeMdns, mdns)) activeMdns = null;
      if (mounted && generation == scanGeneration) setState(() => scanning = false);
    }
  }

  void choose(DiscoveredController device) {
    cancelScan();
    setState(() {
      scanning = false;
      selected = device;
      ip.text = device.host;
      pixels.text = device.state.pixels.toString();
      manual = false;
    });
  }

  void save() {
    if (!form.currentState!.validate()) return;
    final address = ip.text.trim();
    final device = StudioDevice(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.text.trim().isEmpty ? 'Mi tira LED' : name.text.trim(),
      host: address,
      pixels: int.parse(pixels.text.trim()),
    );
    Navigator.pop(context, device);
  }

  @override
  void dispose() {
    cancelScan();
    name.dispose();
    ip.dispose();
    pixels.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Añadir tira')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Conecta tu iluminación', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Busca controladores Morty\'s LED conectados a la misma red WiFi.'),
      const SizedBox(height: 20),
      if (selected == null && !manual) ...[
        if (scanning) const LinearProgressIndicator(),
        if (scanning) const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Buscando controladores en tu red…'),
        ),
        for (final device in found)
          Card(child: ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: Text('Morty\'s LED · ${device.host}'),
            subtitle: Text('${device.state.pixels} píxeles detectados'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => choose(device),
          )),
        if (!scanning && found.isEmpty)
          const Card(child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No encontramos controladores. Comprueba que la ESP32 esté encendida y conectada a tu WiFi.'),
          )),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.orangeAccent)),
        OutlinedButton.icon(onPressed: scanning ? null : scan, icon: const Icon(Icons.refresh), label: const Text('Buscar de nuevo')),
        const SizedBox(height: 12),
        const Text('Para configurar una ESP32 nueva, vuelve al asistente Bluetooth. Esta búsqueda es para controladores que ya están en tu red WiFi.'),
        const SizedBox(height: 12),
        TextButton(onPressed: useManualConfiguration, child: const Text('Configuración manual')),
      ] else ...[
        Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (selected != null) ...[
            Text('Controlador encontrado: ${selected!.host}'),
            TextButton(onPressed: () => setState(() => selected = null), child: const Text('Elegir otro controlador')),
          ],
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nombre de la tira', hintText: 'LED del salón')),
          const SizedBox(height: 12),
          TextFormField(
            controller: ip,
            readOnly: selected != null,
            decoration: const InputDecoration(labelText: 'Dirección IP o nombre de red'),
            validator: (value) {
              final address = value?.trim() ?? '';
              final uri = Uri.tryParse(address.contains('://') ? address : 'http://$address');
              return uri == null || uri.host.isEmpty || uri.host.contains(' ') || !['http','https'].contains(uri.scheme)
                  ? 'Introduce una dirección válida' : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: pixels,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Píxeles direccionables', helperText: 'Cuenta los grupos, no los LED individuales, si tu tira los utiliza.'),
            validator: (value) {
              final n = int.tryParse(value?.trim() ?? '');
              return n == null || n < 1 || n > StudioDevice.maxPixels ? 'Entre 1 y ${StudioDevice.maxPixels} píxeles' : null;
            },
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: save, child: const Text('Guardar tira')),
        ])),
      ],
    ])),
  );
}

