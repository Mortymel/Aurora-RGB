import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudioDevice {
  final String id, name, host;
  const StudioDevice({required this.id,required this.name,required this.host});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'host':host};
  factory StudioDevice.fromJson(Map<String,dynamic> j)=>StudioDevice(
    id:j['id']?.toString()??'',name:j['name']?.toString()??'Dispositivo',
    host:j['host']?.toString()??'');
}
class DeviceStore {
  static const _key='studio_devices_v1',_selected='studio_selected_v1';
  static Future<List<StudioDevice>> load()async{
    final p=await SharedPreferences.getInstance();
    try{
      final raw=p.getString(_key);
      if(raw!=null)return (jsonDecode(raw) as List).map((e)=>StudioDevice.fromJson(Map<String,dynamic>.from(e as Map))).where((d)=>d.host.isNotEmpty).toList();
    }catch(_){}
    final old=p.getString('device_host');
    if(old==null||old.isEmpty)return [];
    final migrated=[StudioDevice(id:'legacy',name:p.getString('device_name')??'Mi tira RGB',host:old)];
    await save(migrated);
    return migrated;
  }
  static Future<void> save(List<StudioDevice> devices)async{
    final p=await SharedPreferences.getInstance();
    await p.setString(_key,jsonEncode(devices.map((e)=>e.toJson()).toList()));
  }
  static Future<String?> selected()async=>(await SharedPreferences.getInstance()).getString(_selected);
  static Future<void> select(String id)async=>(await SharedPreferences.getInstance()).setString(_selected,id);
}
