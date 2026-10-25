import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MqttSettings {
  final bool enabled;
  final String broker,username,baseTopic,discoveryPrefix;
  final int port;
  const MqttSettings({this.enabled=false,this.broker='',this.username='',this.port=1883,this.baseTopic='mostysled',this.discoveryPrefix='homeassistant'});
  Map<String,dynamic> toJson()=>{'enabled':enabled,'broker':broker,'username':username,'port':port,'baseTopic':baseTopic,'discoveryPrefix':discoveryPrefix};
  factory MqttSettings.fromJson(Map<String,dynamic> v)=>MqttSettings(
    enabled:v['enabled']==true,broker:v['broker']?.toString()??'',
    username:v['username']?.toString()??'',port:(v['port'] as num?)?.toInt()??1883,
    baseTopic:v['baseTopic']?.toString()??'mostysled',
    discoveryPrefix:v['discoveryPrefix']?.toString()??'homeassistant');
}
class MqttStore {
  static Future<MqttSettings> load()async{
    final p=await SharedPreferences.getInstance();
    try {return MqttSettings.fromJson(Map<String,dynamic>.from(jsonDecode(p.getString('mqtt_settings_v1')??'{}') as Map));}
    catch(_){return const MqttSettings();}
  }
  static Future<void> save(MqttSettings value)async=>(await SharedPreferences.getInstance()).setString('mqtt_settings_v1',jsonEncode(value.toJson()));
}
