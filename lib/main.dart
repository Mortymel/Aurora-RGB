import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_api.dart';
import 'ble_provisioning.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const RgbStudioApp()); }
class RgbStudioApp extends StatelessWidget {
  const RgbStudioApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ESP32 RGB Studio',
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF101322),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA78BFA), brightness: Brightness.dark),
      cardTheme: const CardThemeData(color: Color(0xFF1D2235)),
    ),
    home: const StudioHome(),
  );
}
class StudioHome extends StatefulWidget { const StudioHome({super.key}); @override State<StudioHome> createState() => _StudioHomeState(); }
class _StudioHomeState extends State<StudioHome> {
  static const effects = ['Color fijo','Arcoíris','Fuego','Chispas','Respiración','Olas'];
  static const palette = [0xFFFF1744,0xFFFF9100,0xFFFFEA00,0xFF00E676,0xFF00B0FF,0xFF7C4DFF,0xFFFF4081,0xFFFFFFFF];
  final hostController = TextEditingController(text:'192.168.4.1');
  DeviceApi? api;
  LedState? current;
  Timer? poll;
  bool busy = false;
  String status = 'Sin conexión';
  @override void initState(){super.initState(); _restore();}
  Future<void> _restore() async {
    final p=await SharedPreferences.getInstance();
    final host=p.getString('device_host');
    if(host!=null){hostController.text=host; await _connect();}
  }
  Future<void> _connect() async {
    poll?.cancel();
    final host=hostController.text.trim();
    if(host.isEmpty)return;
    setState((){busy=true;status='Conectando…';});
    try{
      final candidate=DeviceApi(host);
      final state=await candidate.getState();
      final p=await SharedPreferences.getInstance(); await p.setString('device_host',host);
      if(!mounted)return;
      setState((){api=candidate;current=state;status='Conectado · ${state.wifi}';});
      poll=Timer.periodic(const Duration(seconds: 3), (_)=>_refresh());
    }catch(e){if(mounted)setState((){status='No conectado: $e';});}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> _refresh() async {
    try { final next=await api?.getState(); if(mounted&&next!=null)setState((){current=next;status='Conectado · ${next.wifi}';}); }
    catch(_){if(mounted)setState(()=>status='Conexión interrumpida');}
  }
  Future<void> _send(Map<String,String> fields) async {
    final client=api; if(client==null)return;
    try {final next=await client.control(fields); if(mounted)setState(()=>current=next);}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Error: $e')));}
  }
  Future<void> _bleDialog() async {
    showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Configurar por Bluetooth'),
      content:const Text('El escaneo BLE está disponible. La configuración segura del WiFi necesita una actualización del firmware ESP32.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cerrar')),
        TextButton(onPressed:()async{Navigator.pop(ctx);try{final found=await BleProvisioning.scan();if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Dispositivos RGBStudio encontrados: ${found.length}')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('BLE: $e')));}},child:const Text('Buscar dispositivos'))],
    ));
  }
  Widget tile(Widget child)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:child));
  @override Widget build(BuildContext context){
    final s=current;
    return Scaffold(appBar:AppBar(backgroundColor:Colors.transparent,title:const Text('✦ ESP32 RGB Studio'),actions:[IconButton(tooltip:'Bluetooth',onPressed:_bleDialog,icon:const Icon(Icons.bluetooth_searching))]),
      body:ListView(padding:const EdgeInsets.all(14),children:[
        tile(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Controlador ESP32-WROOM-32',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
          const SizedBox(height:8),Text(status,style:TextStyle(color:s==null?Colors.orangeAccent:Colors.greenAccent)),
          const SizedBox(height:10),TextField(controller:hostController,decoration:const InputDecoration(labelText:'IP o nombre local de la ESP32',hintText:'192.168.1.50',prefixIcon:Icon(Icons.wifi))),
          const SizedBox(height:10),FilledButton.icon(onPressed:busy?null:_connect,icon:const Icon(Icons.link),label:Text(busy?'Conectando…':'Conectar por WiFi')),
          const Text('La app y la ESP32 deben estar en la misma red. En modo AP usa 192.168.4.1.',style:TextStyle(fontSize:12,color:Colors.white60)),
        ])),
        if(s!=null)...[
          tile(Column(children:[
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('Tira LED · ${s.pixels} píxeles',style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),Switch(value:s.power,onChanged:(v)=>_send({'power':v.toString()}))]),
            const SizedBox(height:12),SizedBox(height:45,child:Row(children:List.generate(32,(i)=>Expanded(child:Container(margin:const EdgeInsets.symmetric(horizontal:1),decoration:BoxDecoration(color:HSVColor.fromAHSV(1,i*360/32,1,s.power?0.9:0.15).toColor(),borderRadius:BorderRadius.circular(3)))))),),
            const SizedBox(height:15),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Brillo'),Text('${(s.brightness*100/255).round()}%')]),
            Slider(value:s.brightness.toDouble().clamp(0,255),max:255,divisions:255,onChanged:(v)=>setState(()=>current=LedState(power:s.power,brightness:v.round(),effect:s.effect,speed:s.speed,color:s.color,pixels:s.pixels,audioLevel:s.audioLevel,wifi:s.wifi)),onChangeEnd:(v)=>_send({'brightness':v.round().toString()})),
            const Align(alignment:Alignment.centerLeft,child:Text('Colores rápidos')),
            Wrap(spacing:9,runSpacing:9,children:palette.map((c)=>InkWell(onTap:()=>_send({'color':'0x${(c&0xFFFFFF).toRadixString(16).padLeft(6,'0')}','effect':'0'}),child:CircleAvatar(radius:18,backgroundColor:Color(c)))).toList()),
          ])),
          tile(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Efectos',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),const SizedBox(height:10),
            Wrap(spacing:8,runSpacing:8,children:List.generate(effects.length,(i)=>ChoiceChip(label:Text(effects[i]),selected:s.effect==i,onSelected:(_)=>_send({'effect':'$i'}))),),
            const SizedBox(height:10),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Velocidad'),Text('${s.speed}/255')]),
            Slider(value:s.speed.toDouble().clamp(1,255),min:1,max:255,divisions:254,onChanged:(v)=>setState(()=>current=LedState(power:s.power,brightness:s.brightness,effect:s.effect,speed:v.round(),color:s.color,pixels:s.pixels,audioLevel:s.audioLevel,wifi:s.wifi)),onChangeEnd:(v)=>_send({'speed':v.round().toString()})),
          ])),
          tile(const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Música · próximamente',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),SizedBox(height:6),Text('Pendiente del firmware INMP441 con I2S y FFT.',style:TextStyle(color:Colors.white70))])),
        ],
        tile(ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.bluetooth,color:Color(0xFFA78BFA)),title:const Text('Agregar dispositivo por BLE'),subtitle:const Text('Descubrimiento disponible; aprovisionamiento pendiente'),trailing:const Icon(Icons.chevron_right),onTap:_bleDialog)),
      ]),
    );
  }
  @override void dispose(){poll?.cancel();hostController.dispose();super.dispose();}
}
