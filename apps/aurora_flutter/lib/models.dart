import 'dart:convert';

typedef Json = Map<String, dynamic>;

Uri controllerUri(String input) {
  final raw = input.trim();
  final uri = Uri.tryParse(raw.contains('://') ? raw : 'http://$raw');
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      uri.port < 1 ||
      uri.port > 65535) {
    throw const FormatException(
      'Introduce una IP o nombre .local, sin rutas ni contraseñas.',
    );
  }
  if (RegExp(r'^[\d.]+$').hasMatch(uri.host)) {
    final parts = uri.host.split('.');
    if (parts.length != 4 ||
        parts.any(
          (p) => int.tryParse(p) == null || int.parse(p) > 255 || p.isEmpty,
        )) {
      throw const FormatException(
        'La IP debe tener cuatro números entre 0 y 255.',
      );
    }
  } else if (!uri.host.contains('.') && !uri.host.contains(':')) {
    throw const FormatException(
      'Usa una IP o un nombre como ledweb-xxxxxx.local.',
    );
  }
  return uri.replace(path: '');
}

class Device {
  const Device({
    required this.id,
    required this.name,
    required this.address,
    this.user = 'admin',
    this.password = '',
    this.demo = false,
  });
  final String id, name, address, user, password;
  final bool demo;
  static const demonstration = Device(
    id: 'demo',
    name: 'Escritorio',
    address: '',
    demo: true,
  );
  Json toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'user': user,
    'password': password,
  };
  factory Device.fromJson(Json j) => Device(
    id: j['id'] as String,
    name: j['name'] as String,
    address: controllerUri(j['address'] as String).toString(),
    user: j['user'] as String,
    password: j['password'] as String,
  );
  Device rename(String name) => Device(
    id: id,
    name: name,
    address: address,
    user: user,
    password: password,
    demo: demo,
  );
}

class Light {
  const Light({
    this.on = false,
    this.brightness = 32,
    this.speed = 45,
    this.r = 255,
    this.g = 120,
    this.b = 35,
    this.effect = 'Color fijo',
    this.effects = const [],
    this.count = 320,
    this.wifi = false,
    this.mqtt = false,
    this.clock = '',
    this.clockValid = false,
    this.timer = 0,
  });
  final bool on, wifi, mqtt, clockValid;
  final int brightness, speed, r, g, b, count, timer;
  final String effect, clock;
  final List<String> effects;
  String get hex =>
      '#${[r, g, b].map((v) => v.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
  Json get color => {'r': r, 'g': g, 'b': b};
  Json get scene => {
    'state': 'ON',
    'effect': effect,
    'color': color,
    'brightness': brightness,
    'speed': speed,
  };
  factory Light.fromJson(Json j) {
    final effects = j['effects'];
    if (!['ON', 'OFF'].contains(j['state']) ||
        effects is! List ||
        effects.isEmpty ||
        effects.any((e) => e is! String) ||
        j['color'] is! Map ||
        !effects.contains(j['effect'])) {
      throw const FormatException(
        'Firmware incompatible. Instala LEDWeb 1.2 en esta ESP32.',
      );
    }
    int number(dynamic value, int min, int max) {
      if (value is! int || value < min || value > max) {
        throw const FormatException(
          'Respuesta del controlador fuera de rango.',
        );
      }
      return value;
    }

    return Light(
      on: j['state'] == 'ON',
      brightness: number(j['brightness'], 0, 255),
      speed: number(j['speed'], 1, 100),
      r: number(j['color']['r'], 0, 255),
      g: number(j['color']['g'], 0, 255),
      b: number(j['color']['b'], 0, 255),
      effect: j['effect'] as String,
      effects: List<String>.from(effects),
      count: number(j['count'], 1, 1600),
      wifi: j['wifi'] == true,
      mqtt: j['mqtt'] == true,
      clock: j['clock'] as String? ?? '',
      clockValid: j['clock_valid'] == true,
      timer: j['timer_remaining'] as int? ?? 0,
    );
  }
}

Json cloneJson(Json value) => jsonDecode(jsonEncode(value)) as Json;
const effectNames = [
  'Color fijo',
  'Arcoiris',
  'Barrido arcoiris',
  'Respiracion',
  'Cometa',
  'Teatro',
  'Confeti',
  'Destellos',
  'Fuego',
  'Oceano',
  'Aurora',
  'Escaner',
  'Degradado',
  'Onda de color',
  'Estrobo',
  'Atardecer',
  'Sakura',
  'Bosque',
  'Lava',
  'Mar profundo',
  'Plasma',
  'Galaxia',
  'Luciernagas',
  'Lluvia arcoiris',
  'Meteoros',
  'Chispas doradas',
  'Luces navidenas',
  'Caramelos',
  'Amanecer',
  'Olas neon',
  'Doble cometa',
  'Gradiente vivo',
];
String effectGroup(int i) =>
    {0, 3, 8, 9, 10, 12, 13, 15, 16, 17, 18, 19, 20, 21, 28, 31}.contains(i)
    ? 'Ambiente'
    : {4, 11, 23, 24, 29, 30}.contains(i)
    ? 'Movimiento'
    : 'Fiesta';
