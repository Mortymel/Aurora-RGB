import 'package:flutter/material.dart';
import 'controller.dart';

class AppSettings extends StatelessWidget {
  const AppSettings({
    super.key,
    required this.controller,
    required this.onDevices,
  });
  final AuroraController controller;
  final VoidCallback onDevices;
  Widget block(
    BuildContext context,
    IconData icon,
    String title,
    Widget child,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Ajustes', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 22),
      block(
        context,
        Icons.palette_outlined,
        'Apariencia',
        Row(
          children: [
            for (final option in [
              ('light', 'Claro', Icons.wb_sunny_outlined),
              ('dark', 'Oscuro', Icons.dark_mode_outlined),
              ('system', 'Sistema', Icons.phone_android),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Semantics(
                    selected: controller.appearance == option.$1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        backgroundColor: controller.appearance == option.$1
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        side: BorderSide(
                          color: controller.appearance == option.$1
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => controller.theme(option.$1),
                      child: Column(
                        children: [
                          Container(
                            height: 58,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: option.$1 == 'dark'
                                  ? const Color(0xff101724)
                                  : const Color(0xfff4f2fa),
                              gradient: option.$1 == 'system'
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xfff4f2fa),
                                        Color(0xff101724),
                                      ],
                                      stops: [.5, .5],
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 6,
                                  width: 20,
                                  color: const Color(0xffa58acb),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 6,
                                  color: option.$1 == 'dark'
                                      ? const Color(0xff3a455b)
                                      : const Color(0xffd6cee6),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  height: 6,
                                  width: 30,
                                  color: const Color(0xffa59bb8),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Icon(option.$3, size: 16),
                          const SizedBox(height: 4),
                          Text(option.$2, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      block(
        context,
        Icons.light_outlined,
        'Dispositivos',
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Administrar mis luces'),
          subtitle: Text(
            '${controller.devices.length + (controller.selected?.demo == true ? 1 : 0)} luces guardadas',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onDevices,
        ),
      ),
      const SizedBox(height: 16),
      block(
        context,
        Icons.help_outline,
        'Ayuda',
        const Column(
          children: [
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Conectar una luz'),
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Conecta el teléfono y la ESP32 a la misma red Wi-Fi. Abre Mis luces y pulsa Añadir luz para buscar controladores Aurora. Si no aparece, puedes introducir su IP manualmente.',
                  ),
                ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Configurar Home Assistant'),
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'En Mis luces, pulsa el engranaje junto a la tira y abre Home Assistant / MQTT. Usa la IP y las credenciales de tu broker. Cada ESP32 conserva su propia configuración.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Center(child: Text('Aurora 1.2.1', style: TextStyle(fontSize: 12))),
    ],
  );
}
