import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudioScene {
  final String name;
  final int color, brightness, effect, speed;
  const StudioScene(this.name, this.color, this.brightness, this.effect, this.speed);
  Map<String, dynamic> toJson() => {'name':name,'color':color,'brightness':brightness,'effect':effect,'speed':speed};
  factory StudioScene.fromJson(Map<String,dynamic> v) => StudioScene(
    v['name'] as String? ?? 'Escena', (v['color'] as num?)?.toInt() ?? 0xA020F0,
    (v['brightness'] as num?)?.toInt() ?? 180,(v['effect'] as num?)?.toInt() ?? 0,
    (v['speed'] as num?)?.toInt() ?? 100,
  );
}
class SceneStore {
  static const key='studio_scenes_v1';
  static Future<List<StudioScene>> load() async {
    final p=await SharedPreferences.getInstance();
    try {final raw=p.getString(key); if(raw==null)return [];
      return (jsonDecode(raw) as List).map((e)=>StudioScene.fromJson(Map<String,dynamic>.from(e as Map))).toList();
    } catch(_){return [];}
  }
  static Future<void> save(List<StudioScene> scenes) async {
    final p=await SharedPreferences.getInstance();
    await p.setString(key,jsonEncode(scenes.map((e)=>e.toJson()).toList()));
  }
}
