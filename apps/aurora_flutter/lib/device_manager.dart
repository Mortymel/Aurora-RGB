import 'package:flutter/material.dart';
import 'app_store.dart';
import 'controller.dart';
import 'discovery.dart';
import 'editors.dart';
import 'floating_page.dart';
import 'models.dart';

Future<void> showDeviceManager(
  BuildContext context,
  AuroraController controller,
) => showDialog<void>(
  context: context,
  builder: (dialogContext) => Dialog(
    clipBehavior: Clip.antiAlias,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
    child: SizedBox(
      width: 480,
      height: MediaQuery.sizeOf(dialogContext).height * .82,
      child: DeviceWindowScope(
        close: () => Navigator.of(dialogContext).pop(),
        child: Navigator(
          onGenerateRoute: (_) => windowRoute<void>(
            (context) => _DeviceList(controller: controller),
          ),
        ),
      ),
    ),
  ),
);

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.controller});
  final AuroraController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final devices = [
        ...controller.devices,
        if (controller.selected?.demo == true) controller.selected!,
      ];
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            const WindowHeading(title: 'Mis luces'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  ...devices.map(
                    (device) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.light_outlined),
                        title: Text(device.name),
                        subtitle: Text(
                          device.demo ? 'Demostración' : device.address,
                        ),
                        onTap: controller.busy
                            ? null
                            : () async {
                                await controller.select(device);
                                if (context.mounted) {
                                  DeviceWindowScope.of(context)!.close();
                                }
                              },
                        trailing: IconButton(
                          tooltip: 'Configurar ${device.name}',
                          onPressed: controller.busy
                              ? null
                              : () => Navigator.of(context).push<void>(
                                  windowRoute<void>(
                                    (_) => _DeviceSettings(
                                      parent: controller,
                                      device: device,
                                    ),
                                  ),
                                ),
                          icon: const Icon(Icons.settings_outlined),
                        ),
                      ),
                    ),
                  ),
                  if (devices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Añade tu primera luz para empezar.'),
                    ),
                  FilledButton.icon(
                    onPressed: controller.busy
                        ? null
                        : () => discoverControllers(context, controller),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir luz'),
                  ),
                  TextButton(
                    onPressed: controller.busy
                        ? null
                        : () => deviceEditor(context, controller),
                    child: const Text('Introducir IP manualmente'),
                  ),
                  if (controller.selected?.demo != true)
                    TextButton(
                      onPressed: () async {
                        await controller.select(Device.demonstration);
                        if (context.mounted) {
                          DeviceWindowScope.of(context)!.close();
                        }
                      },
                      child: const Text('Probar sin placa'),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _DeviceSettings extends StatefulWidget {
  const _DeviceSettings({required this.parent, required this.device});
  final AuroraController parent;
  final Device device;
  @override
  State<_DeviceSettings> createState() => _DeviceSettingsState();
}

class _DeviceSettingsState extends State<_DeviceSettings> {
  late final AuroraController session;
  @override
  void initState() {
    super.initState();
    session = AuroraController(
      store: MemoryAppStore(),
      api: widget.parent.api,
      demoApi: widget.parent.demoApi,
    );
    session.select(widget.device);
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  Future<void> edit(
    Future<void> Function(BuildContext, AuroraController) editor,
  ) async {
    await editor(context, session);
    if (!mounted) return;
    final device = session.selected;
    if (device != null) await widget.parent.acceptDeviceSettings(device);
  }

  Widget option(
    IconData icon,
    String title,
    String subtitle,
    Future<void> Function(BuildContext, AuroraController) editor,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: session.connected && !session.busy ? () => edit(editor) : null,
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final device = session.selected ?? widget.device, cfg = session.config;
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            WindowHeading(
              title: 'Ajustes de ${device.name}',
              busy: session.busy,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Text(
                    device.demo ? 'Demostración' : device.address,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  if (session.busy && cfg == null)
                    const Center(child: CircularProgressIndicator()),
                  if (session.error != null)
                    Text(
                      session.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (cfg != null) ...[
                    option(
                      Icons.memory,
                      'Configuración de la tira',
                      '${cfg['count']} píxeles · GPIO ${cfg['gpio']} · ${cfg['grb'] == true ? 'GRB' : 'RGB'}',
                      stripEditor,
                    ),
                    option(
                      Icons.wifi,
                      'Wi-Fi',
                      cfg['ssid'] as String,
                      wifiEditor,
                    ),
                    option(
                      Icons.hub_outlined,
                      'Home Assistant / MQTT',
                      (cfg['mqtt_host'] as String).isEmpty
                          ? 'Sin configurar'
                          : cfg['mqtt_host'] as String,
                      mqttEditor,
                    ),
                    option(
                      Icons.tune,
                      'Control y recuperación',
                      'Brillo máximo, dirección y encendido suave',
                      policyEditor,
                    ),
                    option(
                      Icons.monitor_heart_outlined,
                      'Diagnóstico',
                      'Conexión, reloj y firmware',
                      diagnosticsEditor,
                    ),
                  ],
                  if (!device.demo) ...[
                    const Divider(height: 32),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.router_outlined),
                      title: const Text('IP y acceso al controlador'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: session.busy
                          ? null
                          : () async {
                              await deviceEditor(context, session, device);
                              if (mounted && session.selected != null) {
                                await widget.parent.acceptDeviceSettings(
                                  session.selected!,
                                );
                              }
                            },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.link_off),
                      label: const Text('Quitar de Mis luces'),
                      onPressed: session.busy
                          ? null
                          : () async {
                              final confirmed = await floatingPage<bool>(
                                context,
                                builder: (context) => Column(
                                  children: [
                                    const WindowHeading(title: 'Quitar luz'),
                                    const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text(
                                        'Se quitará de esta app. El ESP32 conservará su configuración.',
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Quitar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await widget.parent.remove(device);
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
