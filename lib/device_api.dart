import 'dart:convert';
import 'package:http/http.dart' as http;

class LedState {
  final bool power;
  final int brightness, effect, speed, color, pixels, audioLevel;
  final String wifi;
  const LedState({required this.power, required this.brightness, required this.effect, required this.speed, required this.color, required this.pixels, required this.audioLevel, required this.wifi});
  factory LedState.fromJson(Map<String, dynamic> v) => LedState(
    power: v['power'] == true,
    brightness: (v['brightness'] as num?)?.toInt() ?? 128,
    effect: (v['effect'] as num?)?.toInt() ?? 0,
    speed: (v['speed'] as num?)?.toInt() ?? 100,
    color: (v['color'] as num?)?.toInt() ?? 0xA020F0,
    pixels: (v['pixels'] as num?)?.toInt() ?? 0,
    audioLevel: (v['audioLevel'] as num?)?.toInt() ?? 0,
    wifi: v['wifi']?.toString() ?? '',
  );
}
class DeviceApi {
  final String host;
  const DeviceApi(this.host);
  Uri get base => Uri.parse(host.startsWith('http') ? host : 'http://$host');
  Uri endpoint(String path) => base.replace(path: path);
  Future<LedState> getState() async {
    final response = await http.get(endpoint('/api/state')).timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    return LedState.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  Future<LedState> control(Map<String, String> fields) async {
    final response = await http.post(endpoint('/api/control'), body: fields).timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    return LedState.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
