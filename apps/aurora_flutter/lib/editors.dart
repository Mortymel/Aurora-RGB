import 'color_wheel.dart';
import 'package:flutter/material.dart';
import 'controller.dart';
import 'models.dart';

class PasswordSetting extends StatefulWidget {
  const PasswordSetting({
    super.key,
    required this.saved,
    required this.onChanged,
  });
  final bool saved;
  final ValueChanged<String> onChanged;
  @override
  State<PasswordSetting> createState() => _PasswordSettingState();
}

class _PasswordSettingState extends State<PasswordSetting> {
  bool editing = false, visible = false;
  @override
  Widget build(BuildContext context) {
    if (widget.saved && !editing) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.lock_outline),
        title: const Text('Contraseña configurada'),
        trailing: TextButton(
          onPressed: () => setState(() => editing = true),
          child: const Text('Cambiar'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        obscureText: !visible,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: 'Contraseña',
          helperText: widget.saved
              ? 'Si no escribes una nueva, seguirá la actual.'
              : null,
          suffixIcon: IconButton(
            tooltip: visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
            onPressed: () => setState(() => visible = !visible),
            icon: Icon(
              visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> editSheet(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext, StateSetter) content,
  required Future<void> Function() save,
  String saveLabel = 'Guardar',
}) async {
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  ModalRoute<void>? route;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, set) {
        route = ModalRoute.of<void>(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height:
                (MediaQuery.sizeOf(context).height * .88 -
                        MediaQuery.viewInsetsOf(context).bottom)
                    .clamp(180.0, MediaQuery.sizeOf(context).height),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: busy ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Form(key: form, child: content(context, set)),
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy
                            ? null
                            : () async {
                                if (!form.currentState!.validate()) return;
                                set(() {
                                  busy = true;
                                  error = null;
                                });
                                try {
                                  await save();
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                } catch (e) {
                                  if (sheetContext.mounted) {
                                    set(
                                      () => error = e is FormatException
                                          ? e.message
                                          : e.toString(),
                                    );
                                  }
                                } finally {
                                  if (sheetContext.mounted) {
                                    set(() => busy = false);
                                  }
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(busy ? 'Guardando…' : saveLabel),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  await route?.completed;
}

Widget entry(
  String label,
  String value,
  ValueChanged<String> change, {
  bool secret = false,
  TextInputType? keyboard,
  int? maxLength,
  bool required = false,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: TextFormField(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    obscureText: secret,
    enableSuggestions: !secret,
    autocorrect: false,
    keyboardType: keyboard,
    maxLength: maxLength,
    buildCounter:
        (context, {required currentLength, required isFocused, maxLength}) =>
            null,
    onChanged: change,
    validator: required
        ? (v) => (v ?? '').trim().isEmpty ? 'Completa este campo' : null
        : null,
  ),
);

Future<void> deviceEditor(
  BuildContext context,
  AuroraController c, [
  Device? existing,
]) async {
  String name = existing?.name ?? '',
      host = existing?.address ?? '',
      user = existing?.user ?? 'admin',
      password = existing?.password ?? 'tiraesp32';
  bool visible = false;
  await editSheet(
    context,
    title: existing == null ? 'Añadir ESP32' : 'Editar controlador',
    saveLabel: 'Conectar y guardar',
    content: (context, set) => Column(
      children: [
        const ExpansionTile(
          title: Text('Primera conexión'),
          tilePadding: EdgeInsets.zero,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                '1. Instala LEDWeb 1.2 en la ESP32.\n2. Conecta el teléfono a LEDWeb-… (clave inicial: tiraesp32).\n3. Añade 192.168.4.1 con admin / tiraesp32, salvo que cambiaste esas claves.\n4. En Ajustes → Wi-Fi, configura tu red de 2,4 GHz.\n5. Vuelve a tu Wi-Fi y edita la IP con la asignada por el router.',
              ),
            ),
          ],
        ),
        entry(
          'Nombre de esta luz',
          name,
          (v) => name = v,
          required: true,
          maxLength: 32,
        ),
        entry(
          'IP o nombre .local',
          host,
          (v) => host = v,
          required: true,
          keyboard: TextInputType.url,
        ),
        entry(
          'Usuario del controlador',
          user,
          (v) => user = v,
          required: true,
          maxLength: 64,
        ),
        TextFormField(
          initialValue: password,
          obscureText: !visible,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Contraseña del controlador',
            suffixIcon: IconButton(
              tooltip: visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
              onPressed: () => set(() => visible = !visible),
              icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
            ),
          ),
          onChanged: (v) => password = v,
          validator: (v) =>
              (v ?? '').isEmpty ? 'Introduce la contraseña' : null,
        ),
        const SizedBox(height: 12),
        const Text(
          'Teléfono y ESP32 deben estar en la misma red. Las claves se guardan protegidas en Android.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
    save: () async {
      if (user.contains(':')) {
        throw const FormatException('El usuario no puede contener dos puntos.');
      }
      await c.add(
        Device(
          id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          name: name.trim(),
          address: controllerUri(host).toString(),
          user: user.trim(),
          password: password,
        ),
      );
    },
  );
}

Future<void> colorEditor(BuildContext context, AuroraController c) async {
  final hex = TextEditingController(text: c.light.hex);
  var r = c.light.r, g = c.light.g, b = c.light.b;
  try {
    await editSheet(
      context,
      title: 'Color',
      saveLabel: 'Aplicar color',
      content: (context, set) {
        Widget channel(
          String label,
          int value,
          ValueChanged<int> change,
        ) => Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(label)),
                Text('$value'),
              ],
            ),
            Slider(
              value: value.toDouble(),
              min: 0,
              max: 255,
              divisions: 255,
              label: '$value',
              onChanged: (v) => set(() {
                change(v.round());
                hex.text =
                    '#${[r, g, b].map((n) => n.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
              }),
            ),
          ],
        );
        return Column(
          children: [
            Container(
              height: 65,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, r, g, b),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            ColorWheel(
              color: Color.fromARGB(255, r, g, b),
              onChanged: (color) => set(() {
                r = (color.r * 255).round();
                g = (color.g * 255).round();
                b = (color.b * 255).round();
                hex.text =
                    '#${[r, g, b].map((v) => v.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
              }),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children:
                  [
                        Colors.white,
                        const Color(0xffffbf80),
                        Colors.red,
                        Colors.orange,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Colors.purple,
                      ]
                      .map(
                        (color) => IconButton(
                          onPressed: () => set(() {
                            r = (color.r * 255).round();
                            g = (color.g * 255).round();
                            b = (color.b * 255).round();
                            hex.text =
                                '#${[r, g, b].map((v) => v.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
                          }),
                          tooltip: 'Elegir tono',
                          icon: Icon(Icons.circle, color: color, size: 32),
                        ),
                      )
                      .toList(),
            ),
            ExpansionTile(
              title: const Text('Ajuste preciso · RGB / HEX'),
              children: [
                TextFormField(
                  controller: hex,
                  decoration: const InputDecoration(labelText: 'Código HEX'),
                  validator: (v) =>
                      RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v ?? '')
                      ? null
                      : 'Ejemplo: #B987D3',
                  onChanged: (v) {
                    if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) {
                      set(() {
                        r = int.parse(v.substring(1, 3), radix: 16);
                        g = int.parse(v.substring(3, 5), radix: 16);
                        b = int.parse(v.substring(5, 7), radix: 16);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                channel('Rojo', r, (v) => r = v),
                channel('Verde', g, (v) => g = v),
                channel('Azul', b, (v) => b = v),
              ],
            ),
            const Text(
              'Al aplicar un color se activa Color fijo.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
      },
      save: () => c.command('light', {
        'state': 'ON',
        'effect': 'Color fijo',
        'color': {'r': r, 'g': g, 'b': b},
      }),
    );
  } finally {
    hex.dispose();
  }
}

Future<void> timerEditor(BuildContext context, AuroraController c) async {
  final minutes = TextEditingController(text: '30');
  bool on = false;
  try {
    await editSheet(
      context,
      title: 'Temporizador',
      saveLabel: 'Programar',
      content: (context, set) => Column(
        children: [
          Wrap(
            spacing: 8,
            children: [15, 30, 60, 120]
                .map(
                  (v) => ActionChip(
                    label: Text(v < 60 ? '$v min' : '${v ~/ 60} h'),
                    onPressed: () => set(() => minutes.text = '$v'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Dentro de cuántos minutos',
            ),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 1 || n > 10080
                  ? 'De 1 a 10080 minutos'
                  : null;
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(on ? 'Encender la luz' : 'Apagar la luz'),
            value: on,
            onChanged: (v) => set(() => on = v),
          ),
          const Text(
            'Se ejecuta en la ESP32 aunque cierres la app. Se cancela al reiniciar la placa.',
            style: TextStyle(fontSize: 12),
          ),
          if (c.light.timer > 0)
            TextButton(
              onPressed: () async {
                try {
                  await c.command('timer', {'minutes': 0});
                  if (context.mounted) Navigator.pop(context);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.toString())));
                  }
                }
              },
              child: const Text('Cancelar cuenta atrás actual'),
            ),
        ],
      ),
      save: () =>
          c.command('timer', {'minutes': int.parse(minutes.text), 'on': on}),
    );
  } finally {
    minutes.dispose();
  }
}

Future<void> scheduleEditor(
  BuildContext context,
  AuroraController c,
  int index,
) async {
  final rule = Map<String, dynamic>.from(
    (c.config!['schedules'] as List)[index] as Map,
  );
  String time = rule['time'] as String;
  bool enabled = rule['enabled'] == true, on = rule['on'] == true;
  int days = rule['days'] as int;
  await editSheet(
    context,
    title: 'Horario ${index + 1}',
    content: (context, set) => Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hora'),
          trailing: Text(
            time,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          onTap: () async {
            final parts = time.split(':');
            final selected = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              ),
            );
            if (selected != null) {
              set(
                () => time =
                    '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}',
              );
            }
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Horario activo'),
          value: enabled,
          onChanged: (v) => set(() => enabled = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(on ? 'Encender' : 'Apagar'),
          value: on,
          onChanged: (v) => set(() => on = v),
        ),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Días de la semana'),
        ),
        Wrap(
          spacing: 5,
          children: List.generate(
            7,
            (i) => FilterChip(
              label: Text(['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'][i]),
              selected: (days & (1 << i)) != 0,
              onSelected: (v) =>
                  set(() => days = v ? days | (1 << i) : days & ~(1 << i)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'La hora sigue la zona del controlador. Al encender se utiliza el último ambiente elegido.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
    save: () async {
      if (days == 0) throw const FormatException('Selecciona al menos un día.');
      final rules = (c.config!['schedules'] as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
      rules[index] = {'enabled': enabled, 'on': on, 'time': time, 'days': days};
      await c.command('config', {'schedules': rules});
    },
  );
}

Future<void> stripEditor(BuildContext context, AuroraController c) async {
  final cfg = c.config!;
  String name = c.selected!.name, count = '${cfg['count']}';
  int pin = cfg['gpio'] as int;
  bool grb = cfg['grb'] == true;
  await editSheet(
    context,
    title: 'Tira y dispositivo',
    content: (context, set) => Column(
      children: [
        entry('Nombre', name, (v) => name = v, required: true, maxLength: 32),
        entry(
          'Número de píxeles',
          count,
          (v) => count = v,
          keyboard: TextInputType.number,
          required: true,
        ),
        const Text(
          'Tu tira: 160 píxeles por metro. 2 metros = 320.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: pin,
          decoration: const InputDecoration(labelText: 'GPIO de datos'),
          items: (cfg['available_pins'] as List)
              .map(
                (p) =>
                    DropdownMenuItem(value: p as int, child: Text('GPIO $p')),
              )
              .toList(),
          onChanged: (v) => pin = v!,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Orden de color'),
          subtitle: Text(grb ? 'GRB' : 'RGB'),
          value: grb,
          onChanged: (v) => set(() => grb = v),
        ),
        const Text(
          'Conecta DIN al GPIO elegido y utiliza un pin libre de tu placa.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
    save: () async {
      final n = int.tryParse(count);
      if (n == null || n < 1 || n > (cfg['max_count'] as int? ?? 1600)) {
        throw const FormatException('Número de píxeles fuera de rango.');
      }
      await c.command('config', {'count': n, 'gpio': pin, 'grb': grb});
      await c.rename(name.trim());
    },
  );
}

Future<void> wifiEditor(BuildContext context, AuroraController c) async {
  String ssid = c.config!['ssid'] as String, password = '';
  bool clear = false;
  await editSheet(
    context,
    title: 'Wi-Fi',
    content: (context, set) => Column(
      children: [
        entry(
          'Nombre de la red de 2,4 GHz',
          ssid,
          (v) => ssid = v,
          maxLength: 32,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Red con contraseña'),
          subtitle: Text(clear ? 'Red abierta' : 'Conexión protegida'),
          value: !clear,
          onChanged: (v) => set(() => clear = !v),
        ),
        if (!clear)
          PasswordSetting(
            saved: c.config!['wifi_password_set'] == true,
            onChanged: (v) => password = v,
          ),
        const Text(
          'Al cambiar de red puede cambiar la IP. Si no conecta, utiliza la red LEDWeb-… para recuperar el acceso.',
          style: TextStyle(fontSize: 12),
        ),
        if (c.selected!.demo) const Text('Modo demo: utiliza datos de prueba.'),
      ],
    ),
    save: () => c.command('config', {
      'ssid': ssid,
      'wifi_password': clear ? '' : password,
      'clear_wifi_password': clear,
    }),
  );
}

Future<void> mqttEditor(BuildContext context, AuroraController c) async {
  final cfg = c.config!;
  String host = cfg['mqtt_host'] as String,
      port = '${cfg['mqtt_port']}',
      user = cfg['mqtt_user'] as String,
      password = '';
  bool clear = false;
  await editSheet(
    context,
    title: 'Home Assistant / MQTT',
    content: (context, set) => Column(
      children: [
        const ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          title: Text('¿Dónde consigo estos datos?'),
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                '1. En Home Assistant OS instala e inicia Mosquitto broker desde Ajustes → Apps/Complementos.\n\n2. Crea un usuario MQTT en Ajustes → Personas → Usuarios. Activa el modo avanzado si no aparece.\n\n3. Busca la IP del equipo en Ajustes → Sistema → Red o en tu router.\n\n4. Configura la integración MQTT en Dispositivos y servicios, con descubrimiento habilitado.\n\n5. Introduce aquí la IP del broker, puerto 1883, usuario y contraseña. La tira aparecerá como Tira LED.\n\nSi usas otro broker, utiliza sus datos. No es el puerto web 8123 ni la contraseña Wi-Fi.',
              ),
            ),
          ],
        ),
        entry('IP o nombre del broker', host, (v) => host = v, maxLength: 128),
        entry(
          'Puerto',
          port,
          (v) => port = v,
          keyboard: TextInputType.number,
          required: true,
        ),
        entry('Usuario MQTT', user, (v) => user = v, maxLength: 128),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Usar usuario y contraseña'),
          subtitle: Text(clear ? 'Sin autenticación' : 'Acceso al broker MQTT'),
          value: !clear,
          onChanged: (v) => set(() => clear = !v),
        ),
        if (!clear)
          PasswordSetting(
            saved: c.config!['mqtt_password_set'] == true,
            onChanged: (v) => password = v,
          ),
        const Text(
          'Servidor vacío desactiva MQTT. La ESP32 conecta al broker; la app guarda su configuración. Conexión local sin TLS.',
          style: TextStyle(fontSize: 12),
        ),
        if (c.selected!.demo)
          const Text('Modo demo: no se conecta a un broker real.'),
      ],
    ),
    save: () async {
      final n = int.tryParse(port);
      if (n == null || n < 1 || n > 65535) {
        throw const FormatException('Puerto de 1 a 65535.');
      }
      await c.command('config', {
        'mqtt_host': host.trim(),
        'mqtt_port': n,
        'mqtt_user': clear ? '' : user,
        'mqtt_password': clear ? '' : password,
        'clear_mqtt_password': clear,
      });
    },
  );
}
