import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'controller.dart';
import 'editors.dart';
import 'models.dart';

Future<void> discoverControllers(
  BuildContext context,
  AuroraController controller,
) async {
  final client = MDnsClient();
  final devices = <String, Device>{};
  const channel = MethodChannel('aurora/network');
  bool cancelled = false;
  String? error;
  Future<void> search(StateSetter set) async {
    try {
      try {
        await channel.invokeMethod<void>('acquire');
      } on MissingPluginException {
        /* Flutter tests */
      }
      await client.start();
      await for (final ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_http._tcp.local'),
        timeout: const Duration(seconds: 5),
      )) {
        if (cancelled) break;
        await for (final service in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
          timeout: const Duration(seconds: 1),
        )) {
          if (!service.target.toLowerCase().startsWith('ledweb-')) continue;
          await for (final address in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(service.target),
            timeout: const Duration(seconds: 1),
          )) {
            if (cancelled) break;
            final host = address.address.address;
            set(
              () => devices[host] = Device(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                name: service.target.split('.').first,
                address: 'http://$host:${service.port}',
              ),
            );
          }
        }
      }
    } catch (_) {
      if (!cancelled) {
        set(
          () => error =
              'No se pudo buscar por Wi-Fi. Puedes añadir la IP manualmente.',
        );
      }
    } finally {
      client.stop();
      try {
        await channel.invokeMethod<void>('release');
      } catch (_) {}
      if (!cancelled) {
        set(
          () => error ??=
              'Búsqueda terminada. Si no aparece, añade la IP del router o 192.168.4.1 desde su punto de acceso.',
        );
      }
    }
  }

  bool started = false;
  Device? selected;
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, set) {
        if (!started) {
          started = true;
          Future<void>(
            () => search((fn) {
              if (!cancelled && context.mounted) set(fn);
            }),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Buscar ESP32',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (error == null) const LinearProgressIndicator(),
                ...devices.values.map(
                  (device) => ListTile(
                    leading: const Icon(Icons.memory),
                    title: Text(device.name),
                    subtitle: Text(device.address),
                    onTap: () {
                      selected = device;
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(error ?? 'Buscando controladores LEDWeb en tu Wi-Fi…'),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  cancelled = true;
  client.stop();
  if (context.mounted && selected != null) {
    await deviceEditor(context, controller, selected);
  }
}
