import 'discovery.dart';
import 'effect_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'controller.dart';
import 'editors.dart';
import 'light_visuals.dart';
import 'models.dart';

class AuroraHome extends StatefulWidget {
  const AuroraHome({super.key, required this.controller});
  final AuroraController controller;
  @override
  State<AuroraHome> createState() => _AuroraHomeState();
}

class _AuroraHomeState extends State<AuroraHome> {
  AuroraController get c => widget.controller;
  int tab = 0;
  String filter = 'Todos', query = '';
  bool get ready => c.connected && !c.busy;
  Future<void> act(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is FormatException ? e.message : e.toString()),
          ),
        );
      }
    }
  }

  Future<void> controllers() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => ListenableBuilder(
        listenable: c,
        builder: (context, child) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mis controladores',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: c.busy
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await discoverControllers(this.context, c);
                        },
                  icon: const Icon(Icons.wifi_find),
                  label: const Text('Buscar ESP32 en Wi-Fi'),
                ),
                ...c.devices.map(
                  (d) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.memory),
                    title: Text(d.name),
                    subtitle: Text(d.address),
                    selected: c.selected?.id == d.id,
                    onTap: c.busy
                        ? null
                        : () async {
                            await c.select(d);
                            if (context.mounted) Navigator.pop(context);
                          },
                    trailing: IconButton(
                      tooltip: 'Editar ${d.name}',
                      onPressed: c.busy
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await deviceEditor(this.context, c, d);
                            },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: c.busy
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await deviceEditor(this.context, c);
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir ESP32'),
                ),
                TextButton(
                  onPressed: c.busy
                      ? null
                      : () async {
                          await c.select(Device.demonstration);
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: const Text('Explorar demostración'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (c.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEDWEB / AURORA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          onPressed: c.busy ? null : controllers,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  c.selected?.name ?? 'Tus luces',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: c.light.on ? 'Apagar luz' : 'Encender luz',
                    onPressed: ready
                        ? () => act(
                            () => c.command('light', {
                              'state': c.light.on ? 'OFF' : 'ON',
                            }),
                          )
                        : null,
                    icon: const Icon(Icons.power_settings_new),
                    iconSize: 27,
                  ),
                ],
              ),
            ),
            if (c.selected != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 7,
                      color: c.connected
                          ? const Color(0xff34846b)
                          : Colors.orange,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        c.selected!.demo
                            ? 'Demostración · dispositivo simulado'
                            : c.connected
                            ? (c.light.wifi
                                  ? 'Conectado por Wi-Fi'
                                  : 'Conectado al punto de acceso')
                            : 'Sin conexión',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    if (c.busy)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            if (c.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.error!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Reintentar conexión',
                          onPressed: c.busy ? null : () => c.refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: c.selected == null
                  ? welcome()
                  : RefreshIndicator(
                      onRefresh: c.refresh,
                      child: tab == 1 && c.config != null
                          ? effects()
                          : ListView(
                              key: ValueKey(tab),
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                12,
                                24,
                                28,
                              ),
                              children: [
                                if (tab == 0 && c.config != null) ...[
                                  StripPreview(light: c.light),
                                  const SizedBox(height: 24),
                                ],
                                if (c.config == null) ...[
                                  const SizedBox(height: 40),
                                  const Text('Esperando al controlador…'),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: c.busy
                                        ? null
                                        : () => deviceEditor(
                                            context,
                                            c,
                                            c.selected,
                                          ),
                                    child: const Text(
                                      'Revisar IP y credenciales',
                                    ),
                                  ),
                                ] else
                                  switch (tab) {
                                    0 => home(),
                                    1 => effects(),
                                    2 => schedules(),
                                    _ => settings(),
                                  },
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Mi luz',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Efectos',
          ),
          NavigationDestination(icon: Icon(Icons.schedule), label: 'Horarios'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Ajustes'),
        ],
      ),
    );
  }

  Widget welcome() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          ColorOrb(
            color: const Color(0xffb987d3),
            onTap: () => deviceEditor(context, c),
          ),
          const SizedBox(height: 36),
          Text(
            'Tu luz, en Aurora',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Añade tu ESP32 para controlar su tira por Wi-Fi.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => deviceEditor(context, c),
            icon: const Icon(Icons.add),
            label: const Text('Añadir ESP32'),
          ),
          OutlinedButton.icon(
            onPressed: () => discoverControllers(context, c),
            icon: const Icon(Icons.wifi_find),
            label: const Text('Buscar en mi Wi-Fi'),
          ),
          TextButton(
            onPressed: () => c.select(Device.demonstration),
            child: const Text('Probar sin placa'),
          ),
        ],
      ),
    ),
  );
  Widget title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
  Widget home() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Color', style: Theme.of(context).textTheme.titleLarge),
          Text(
            c.light.hex,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Center(
        child: ColorOrb(
          color: rgb(c.light),
          onTap: ready ? () => colorEditor(context, c) : null,
        ),
      ),
      const SizedBox(height: 26),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [0xffb987d3, 0xffe5aa83, 0xff7aafd4, 0xff8fc3ac, 0xffe5c9db]
            .map((value) {
              final color = Color(value);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Semantics(
                  label: 'Elegir color ${value.toRadixString(16).substring(2)}',
                  button: true,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: ready
                        ? () => act(
                            () => c.command('light', {
                              'state': 'ON',
                              'effect': 'Color fijo',
                              'color': {
                                'r': (color.r * 255).round(),
                                'g': (color.g * 255).round(),
                                'b': (color.b * 255).round(),
                              },
                            }),
                          )
                        : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          width: 4,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(),
      ),
      const SizedBox(height: 20),
      ValueSlider(
        label: 'Intensidad',
        value: c.light.brightness,
        max: 255,
        min: 0,
        percent: true,
        enabled: ready,
        onCommit: (v) => act(() => c.command('light', {'brightness': v})),
      ),
      ValueSlider(
        label: 'Velocidad del efecto',
        value: c.light.speed,
        max: 100,
        min: 1,
        enabled: ready,
        onCommit: (v) => act(() => c.command('light', {'speed': v})),
      ),
      tile(
        Icons.schedule,
        'Temporizador',
        c.light.timer > 0
            ? 'Acción en ${(c.light.timer / 60).ceil()} min'
            : 'Encender o apagar después de un tiempo',
        ready ? () => timerEditor(context, c) : null,
      ),
      OutlinedButton.icon(
        onPressed: ready ? saveScene : null,
        icon: const Icon(Icons.star_outline),
        label: const Text('Guardar este ambiente'),
      ),
      TextButton.icon(
        onPressed: ready && c.undoSnapshot != null ? () => act(c.undo) : null,
        icon: const Icon(Icons.undo),
        label: const Text('Deshacer último cambio'),
      ),
      const SizedBox(height: 28),
      Row(
        children: [
          Expanded(
            child: Text(
              'Tus ambientes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              tab = 1;
              filter = 'Favoritos';
            }),
            child: const Text('Ver todos'),
          ),
        ],
      ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: c.light.effects
            .where(c.favorites.contains)
            .take(4)
            .map(
              (name) => SizedBox(
                width: (MediaQuery.sizeOf(context).width - 60) / 2,
                child: Semantics(
                  button: true,
                  label: 'Aplicar $name',
                  child: InkWell(
                    onTap: ready
                        ? () => act(
                            () => c.command('light', {
                              'state': 'ON',
                              'effect': name,
                            }),
                          )
                        : null,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 110,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors:
                              palettes[(effectNames.indexOf(name) - 15).abs() %
                                  palettes.length],
                        ),
                      ),
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
  Future<void> saveScene() async {
    String name = c.light.effect;
    await editSheet(
      context,
      title: 'Guardar ambiente',
      content: (context, set) =>
          entry('Nombre', name, (v) => name = v, maxLength: 32, required: true),
      save: () => c.saveScene(name.trim()),
    );
  }

  Widget effects() {
    final visible = c.light.effects
        .where(
          (name) =>
              name.toLowerCase().contains(query.toLowerCase()) &&
              (filter == 'Todos' ||
                  filter == 'Favoritos' && c.favorites.contains(name) ||
                  effectGroup(effectNames.indexOf(name)) == filter),
        )
        .toList();
    final saved = filter == 'Favoritos' ? c.scenes : <Json>[];
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return CustomScrollView(
      scrollCacheExtent: ScrollCacheExtent.pixels(180),
      key: const PageStorageKey('effects-gallery'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title('Efectos'),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar efecto…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  children:
                      ['Todos', 'Ambiente', 'Movimiento', 'Fiesta', 'Favoritos']
                          .map(
                            (name) => ChoiceChip(
                              label: Text(name),
                              selected: filter == name,
                              onSelected: (_) => setState(() => filter = name),
                            ),
                          )
                          .toList(),
                ),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No hay coincidencias.'),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid.builder(
            itemCount: visible.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 142 + 54 * scale,
            ),
            itemBuilder: (context, index) {
              final name = visible[index];
              return RepaintBoundary(
                child: EffectCard(
                  key: ValueKey(name),
                  name: name,
                  light: c.light,
                  selected: c.light.effect == name,
                  favorite: c.favorites.contains(name),
                  onFavorite: () => act(() => c.favorite(name)),
                  onApply: ready
                      ? () => act(
                          () => c.command('light', {
                            'state': 'ON',
                            'effect': name,
                          }),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        if (saved.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverToBoxAdapter(child: title('Ambientes guardados')),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: saved.length,
            itemBuilder: (context, index) {
              final scene = saved[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(scene['name'] as String),
                subtitle: Text(scene['effect'] as String),
                onTap: ready
                    ? () => act(
                        () => c.command('light', {
                          'state': 'ON',
                          'effect': scene['effect'],
                          'color': scene['color'],
                          'brightness': scene['brightness'],
                          'speed': scene['speed'],
                        }),
                      )
                    : null,
                trailing: IconButton(
                  tooltip: 'Eliminar ambiente',
                  onPressed: () =>
                      act(() => c.deleteScene(scene['id'] as String)),
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  Widget schedules() {
    final cfg = c.config!, rules = cfg['schedules'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title('Horarios'),
        Card(
          child: ListTile(
            title: Text(c.light.clockValid ? c.light.clock : 'Sin sincronizar'),
            subtitle: Text(
              'UTC ${(cfg['utc_offset'] as int) / 60} · desplazamiento fijo',
            ),
            trailing: IconButton(
              tooltip: 'Sincronizar reloj',
              onPressed: ready
                  ? () => act(
                      () => c.command('clock', {
                        'epoch': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      }),
                    )
                  : null,
              icon: const Icon(Icons.sync),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(4, (i) {
          final rule = rules[i] as Map;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(
                rule['time'] as String,
                style: const TextStyle(fontSize: 27),
              ),
              subtitle: Text(
                '${rule['on'] == true ? 'Encender' : 'Apagar'} · ${dayText(rule['days'] as int)}',
              ),
              onTap: ready ? () => scheduleEditor(context, c, i) : null,
              trailing: Switch(
                value: rule['enabled'] == true,
                onChanged: ready
                    ? (value) => act(() async {
                        final next = rules
                            .map((s) => Map<String, dynamic>.from(s as Map))
                            .toList();
                        next[i]['enabled'] = value;
                        await c.command('config', {'schedules': next});
                      })
                    : null,
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        const Text(
          'Los horarios se ejecutan en la ESP32 aunque cierres la app. Necesita tener la hora sincronizada.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 18),
        tile(
          Icons.schedule,
          'Cuenta atrás',
          c.light.timer > 0
              ? '${(c.light.timer / 60).ceil()} min restantes'
              : 'Sin temporizador',
          ready ? () => timerEditor(context, c) : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          key: ValueKey(cfg['utc_offset']),
          initialValue: cfg['utc_offset'] as int,
          decoration: const InputDecoration(labelText: 'Zona horaria'),
          items:
              ({
                    -720,
                    -480,
                    -420,
                    -360,
                    -300,
                    -240,
                    -180,
                    0,
                    60,
                    120,
                    330,
                    480,
                    540,
                    600,
                    720,
                    840,
                    cfg['utc_offset'] as int,
                  }.toList()..sort())
                  .map(
                    (offset) => DropdownMenuItem(
                      value: offset,
                      child: Text(
                        'UTC ${offset >= 0 ? '+' : '−'}${(offset.abs() ~/ 60).toString().padLeft(2, '0')}:${(offset.abs() % 60).toString().padLeft(2, '0')}',
                      ),
                    ),
                  )
                  .toList(),
          onChanged: ready
              ? (value) => act(() => c.command('config', {'utc_offset': value}))
              : null,
        ),
        const SizedBox(height: 10),
        const Text(
          'No se ajusta automáticamente al horario de verano.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget settings() {
    final cfg = c.config!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title('Ajustes'),
        tile(
          Icons.health_and_safety_outlined,
          'Control y recuperación',
          'Brillo máximo, transiciones y estado al reiniciar',
          ready ? () => policyEditor(context, c) : null,
        ),
        tile(
          Icons.info_outline,
          'Diagnóstico',
          'IP, Wi-Fi, MQTT y firmware',
          ready ? () => diagnosticsEditor(context, c) : null,
        ),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: const Icon(Icons.memory, size: 36),
            title: Text(c.selected!.name),
            subtitle: Text(
              '${cfg['chip'] ?? 'ESP32'} · ${cfg['count']} píxeles',
            ),
          ),
        ),
        const SizedBox(height: 20),
        tile(
          Icons.devices,
          'Mis controladores',
          'Añadir o cambiar de ESP32',
          controllers,
        ),
        if (!c.selected!.demo)
          tile(
            Icons.edit_outlined,
            'IP y credenciales',
            c.selected!.address,
            c.busy ? null : () => deviceEditor(context, c, c.selected),
          ),
        tile(
          Icons.light_outlined,
          'Tira y dispositivo',
          '${cfg['count']} píxeles · GPIO ${cfg['gpio']} · ${cfg['grb'] == true ? 'GRB' : 'RGB'}',
          ready ? () => stripEditor(context, c) : null,
        ),
        tile(
          Icons.wifi,
          'Conexión Wi-Fi',
          cfg['ssid'] as String,
          ready ? () => wifiEditor(context, c) : null,
        ),
        tile(
          Icons.hub_outlined,
          'Home Assistant / MQTT',
          c.light.mqtt ? 'Conectado' : 'Desconectado',
          ready ? () => mqttEditor(context, c) : null,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          key: ValueKey(c.appearance),
          initialValue: c.appearance,
          decoration: const InputDecoration(labelText: 'Apariencia'),
          items: const [
            DropdownMenuItem(value: 'system', child: Text('Automática')),
            DropdownMenuItem(value: 'light', child: Text('Clara')),
            DropdownMenuItem(value: 'dark', child: Text('Oscura')),
          ],
          onChanged: (value) => act(() => c.theme(value!)),
        ),
        const SizedBox(height: 16),
        tile(
          Icons.info_outline,
          'Acerca de Aurora',
          'Android · Flutter · 1.1.1',
          () => showAboutDialog(
            context: context,
            applicationName: 'Aurora',
            applicationVersion: '1.1.1',
            children: [
              const Text(
                'App nativa para ESP32 con LEDWeb 1.2. La vista previa aproxima el efecto; la esfera representa el color seleccionado. Control local por Wi-Fi. Los horarios pertenecen a la ESP32.',
              ),
              if (c.selected!.demo)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'La demo no controla hardware ni conecta a MQTT. Sus horarios se evalúan mientras la app está activa.',
                  ),
                ),
            ],
          ),
        ),
        if (!c.selected!.demo)
          TextButton.icon(
            onPressed: c.busy
                ? null
                : () => act(() async {
                    final remove = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Quitar de la app?'),
                        content: const Text(
                          'Se eliminarán la dirección y las credenciales guardadas. La ESP32 conservará su configuración.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Quitar'),
                          ),
                        ],
                      ),
                    );
                    if (remove == true) await c.remove(c.selected!);
                  }),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Quitar controlador de la app'),
          ),
      ],
    );
  }

  Widget tile(
    IconData icon,
    String name,
    String description,
    VoidCallback? onTap,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(name),
    subtitle: description.isEmpty ? null : Text(description),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
    enabled: onTap != null,
  );
  String dayText(int days) => days == 127
      ? 'Todos los días'
      : List.generate(
          7,
          (i) => days & (1 << i) != 0
              ? ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'][i]
              : '',
        ).where((s) => s.isNotEmpty).join(' · ');
}

class ValueSlider extends StatefulWidget {
  const ValueSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onCommit,
    this.percent = false,
  });
  final String label;
  final int value, min, max;
  final bool enabled, percent;
  final ValueChanged<int> onCommit;
  @override
  State<ValueSlider> createState() => _ValueSliderState();
}

class _ValueSliderState extends State<ValueSlider> {
  double? drag;
  @override
  void didUpdateWidget(covariant ValueSlider old) {
    super.didUpdateWidget(old);
    if (!widget.enabled) drag = null;
  }

  @override
  Widget build(BuildContext context) {
    final value = drag ?? widget.value.toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.label)),
              Text(
                widget.percent
                    ? '${(value / 255 * 100).round()}%'
                    : '${value.round()}',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          Slider(
            value: value.clamp(widget.min.toDouble(), widget.max.toDouble()),
            min: widget.min.toDouble(),
            max: widget.max.toDouble(),
            divisions: widget.max - widget.min,
            semanticFormatterCallback: (v) => widget.percent
                ? '${(v / 255 * 100).round()} por ciento'
                : '${v.round()}',
            onChanged: widget.enabled ? (v) => setState(() => drag = v) : null,
            onChangeEnd: widget.enabled
                ? (v) {
                    setState(() => drag = null);
                    widget.onCommit(v.round());
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
