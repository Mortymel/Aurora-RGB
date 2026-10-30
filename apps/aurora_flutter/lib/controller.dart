import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_store.dart';
import 'device_api.dart';
import 'models.dart';

class AuroraController extends ChangeNotifier {
  AuroraController({required this.store, DeviceApi? api, DemoApi? demoApi})
    : api = api ?? LanApi(),
      demoApi = demoApi ?? DemoApi();
  final AppStore store;
  final DeviceApi api;
  final DemoApi demoApi;
  List<Device> devices = [];
  Device? selected;
  Light light = const Light();
  Json? config;
  String? error;
  String appearance = 'system';
  Set<String> favorites = {'Atardecer', 'Galaxia', 'Sakura', 'Mar profundo'};
  List<Json> scenes = [];
  bool connected = false,
      busy = false,
      loading = true,
      active = true,
      _disposed = false,
      _polling = false;
  int _generation = 0, _revision = 0;
  Timer? _timer;
  Future<void> _storageQueue = Future.value();
  DeviceApi _api(Device device) => device.demo ? demoApi : api;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    try {
      final data = await store.load();
      devices = (data['devices'] as List? ?? [])
          .map((d) => Device.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList();
      appearance = ['system', 'light', 'dark'].contains(data['appearance'])
          ? data['appearance'] as String
          : 'system';
      if (data['favorites'] is List) {
        favorites = Set<String>.from(data['favorites'] as List);
      }
      scenes = (data['scenes'] as List? ?? [])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
      final id = data['selected'];
      if (devices.isNotEmpty) {
        await select(
          devices.firstWhere((d) => d.id == id, orElse: () => devices.first),
        );
      }
    } catch (_) {
      error =
          'No se pudieron cargar los datos guardados. Puedes volver a añadir tu ESP32.';
    } finally {
      loading = false;
      _notify();
      _schedulePoll();
    }
  }

  Future<void> _persist() {
    final data = {
      'devices': devices.map((d) => d.toJson()).toList(),
      'selected': selected?.demo == true ? null : selected?.id,
      'appearance': appearance,
      'favorites': favorites.toList(),
      'scenes': scenes,
    };
    final snapshot = cloneJson(data);
    _storageQueue = _storageQueue
        .catchError((Object _) {})
        .then((_) => store.save(snapshot));
    return _storageQueue;
  }

  void _schedulePoll() {
    _timer?.cancel();
    if (_disposed || !active) return;
    _timer = Timer(const Duration(seconds: 3), () async {
      await refresh();
      _schedulePoll();
    });
  }

  void setActive(bool value) {
    active = value;
    if (value) {
      unawaited(refresh());
      _schedulePoll();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> select(Device device) async {
    if (busy) {
      throw const ApiException('Espera a que termine la acción actual.');
    }
    final generation = ++_generation;
    selected = device;
    connected = false;
    config = null;
    light = const Light();
    error = null;
    busy = true;
    _notify();
    try {
      final result = await _read(device);
      if (generation != _generation || _disposed) return;
      config = result.$1;
      light = result.$2;
      connected = true;
      await _persist();
    } catch (e) {
      if (generation == _generation) error = _message(e);
    } finally {
      if (generation == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<(Json, Light)> _read(Device device) async {
    final conf = await _api(device).request(device, 'config');
    if (conf['schedules'] is! List ||
        (conf['schedules'] as List).length != 4 ||
        conf['available_pins'] is! List ||
        conf['gpio'] is! int) {
      throw const ApiException(
        'Firmware incompatible. Instala LEDWeb 1.2 en esta ESP32.',
      );
    }
    return (conf, Light.fromJson(await _api(device).request(device, 'state')));
  }

  Future<void> add(Device device) async {
    if (busy) {
      throw const ApiException('Espera a que termine la acción actual.');
    }
    busy = true;
    _notify();
    try {
      final result = await _read(device);
      devices =
          devices
              .where((d) => d.id != device.id && d.address != device.address)
              .toList()
            ..add(device);
      selected = device;
      _generation++;
      config = result.$1;
      light = result.$2;
      connected = true;
      error = null;
      await _persist();
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> remove(Device device) async {
    if (busy) {
      throw const ApiException('Espera a que termine la acción actual.');
    }
    devices.removeWhere((d) => d.id == device.id);
    if (selected?.id == device.id) {
      _generation++;
      selected = null;
      config = null;
      connected = false;
      light = const Light();
      error = null;
    }
    await _persist();
    _notify();
  }

  Future<void> rename(String name) async {
    final device = selected;
    if (device == null) return;
    selected = device.rename(name);
    devices = devices.map((d) => d.id == device.id ? selected! : d).toList();
    await _persist();
    _notify();
  }

  Future<void> refresh() async {
    final device = selected;
    if (device == null || busy || _polling || !active || _disposed) return;
    final generation = _generation, revision = _revision;
    _polling = true;
    try {
      final result = config == null ? await _read(device) : null;
      final next =
          result?.$2 ??
          Light.fromJson(await _api(device).request(device, 'state'));
      if (generation != _generation || revision != _revision || _disposed) {
        return;
      }
      if (result != null) config = result.$1;
      light = next;
      connected = true;
      error = null;
    } catch (e) {
      if (generation == _generation && revision == _revision) {
        connected = false;
        error = _message(e);
      }
    } finally {
      _polling = false;
      _notify();
    }
  }

  Future<void> command(String route, Json patch) async {
    final device = selected;
    if (device == null || !connected) {
      throw const ApiException(
        'Conecta un controlador antes de enviar órdenes.',
      );
    }
    if (busy) {
      throw const ApiException('Espera a que termine la acción actual.');
    }
    busy = true;
    _revision++;
    error = null;
    _notify();
    try {
      Json body = patch;
      if (route == 'config') {
        final latest = await _api(device).request(device, 'config');
        body = {...latest, 'wifi_password': '', 'mqtt_password': '', ...patch};
      }
      final result = await _api(device).request(device, route, body);
      if (route == 'config') {
        config = {...body}
          ..remove('wifi_password')
          ..remove('mqtt_password');
        if (result['reconnecting'] == true) {
          connected = false;
          error =
              'Configuración guardada. Reconectando; si cambia la IP, edita el controlador.';
          return;
        }
      }
      light = Light.fromJson(await _api(device).request(device, 'state'));
      connected = true;
    } catch (e) {
      connected = false;
      error = _message(e);
      rethrow;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> theme(String value) async {
    appearance = value;
    _notify();
    await _persist();
  }

  Future<void> favorite(String value) async {
    favorites.contains(value) ? favorites.remove(value) : favorites.add(value);
    _notify();
    await _persist();
  }

  Future<void> saveScene(String name) async {
    if (scenes.length >= 50) {
      throw const ApiException(
        'Puedes guardar hasta 50 ambientes. Elimina uno para añadir otro.',
      );
    }
    scenes.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': name,
      ...light.scene,
    });
    await _persist();
    _notify();
  }

  Future<void> deleteScene(String id) async {
    scenes.removeWhere((s) => s['id'] == id);
    await _persist();
    _notify();
  }

  String _message(Object e) => e is FormatException ? e.message : e.toString();
  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    super.dispose();
  }
}
