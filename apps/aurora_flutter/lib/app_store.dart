import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models.dart';

abstract class AppStore {
  Future<Json> load();
  Future<void> save(Json data);
}

class SecureAppStore implements AppStore {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  @override
  Future<Json> load() async {
    final raw = await storage.read(key: 'aurora.v1');
    return raw == null ? {} : jsonDecode(raw) as Json;
  }

  @override
  Future<void> save(Json data) =>
      storage.write(key: 'aurora.v1', value: jsonEncode(data));
}

class MemoryAppStore implements AppStore {
  Json data = {};
  @override
  Future<Json> load() async => cloneJson(data);
  @override
  Future<void> save(Json value) async {
    data = cloneJson(value);
  }
}
