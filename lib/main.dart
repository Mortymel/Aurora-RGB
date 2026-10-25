import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_api.dart';
import 'ble_provisioning.dart';
import 'scene_store.dart';
import 'device_store.dart';

const ink=Color(0xFF101216);
const panel=Color(0xFF1D2026);
const violet=Color(0xFF83D9BC);
const colors=<int>[0xFFFF5277,0xFFFFAD4D,0xFFFFE66B,0xFF49E6A1,0xFF39C9F7,0xFF736BFF,0xFFB87BFF,0xFFFF77D1,0xFFFFFFFF];
const effectNames=<String>['Fijo','Arcoíris','Respirar','Cometa','Chispas','Fuego','Olas','Barrido','Pulso','Confeti','Meteoros','Gradiente'];
const builtInScenes=<StudioScene>[
  StudioScene('Atardecer',0xFF914D,175,0,90),
  StudioScene('Océano',0x18B7FF,195,0,100),
  StudioScene('Aurora',0x60D8B4,170,1,110),
  StudioScene('Relax',0xAE78FF,95,4,55),
  StudioScene('Fiesta',0xFF3C99,240,1,210),
  StudioScene('Lectura',0xFFE3B0,220,0,100),
];

void main(){WidgetsFlutterBinding.ensureInitialized();runApp(const StudioApp());}
class StudioApp extends StatelessWidget {
  const StudioApp({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(
    title:"Morty's LED",debugShowCheckedModeBanner:false,
    theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:ink,
      colorScheme:ColorScheme.fromSeed(seedColor:violet,brightness:Brightness.dark),
      cardTheme:const CardThemeData(color:panel,margin:EdgeInsets.symmetric(vertical:7)),
      inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:panel,border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none))),
    home:const StudioShell());
}
class StudioShell extends StatefulWidget {const StudioShell({super.key});@override State<StudioShell> createState()=>_StudioShellState();}
class _StudioShellState extends State<StudioShell>{
  int page=0;
  String host='192.168.4.1',deviceName='Controlador LED',message='Sin conectar';
  DeviceApi? api;
  LedState? state;
  Timer? poll,nightTimer;
  DateTime? nightEnd;
  List<StudioScene> saved=[];
  List<StudioDevice> devices=[];
  String? selectedId;
  bool polling=false;
  int connectionGeneration=0;
  int devicePage=0;
  bool busy=false;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async{
    final p=await SharedPreferences.getInstance();
    saved=await SceneStore.load();
    devices=await DeviceStore.load();
    selectedId=await DeviceStore.selected();
    if(devices.isNotEmpty){final active=devices.where((d)=>d.id==selectedId).toList();final d=active.isEmpty?devices.first:active.first;host=d.host;deviceName=d.name;selectedId=d.id;}
    if(devices.isEmpty){host=p.getString('device_host')??host;deviceName=p.getString('device_name')??deviceName;}
    if(mounted)setState((){});
    if(devices.isNotEmpty){devicePage=devices.indexWhere((d)=>d.id==selectedId);if(devicePage<0)devicePage=0;await connect();}
  }
  Future<void> connect() async{
    poll?.cancel();
    final generation=++connectionGeneration;
    final target=host.trim();
    setState((){busy=true;message='Conectando…';});
    try{
      final a=DeviceApi(target);
      final s=await a.getState();
      final p=await SharedPreferences.getInstance();await p.setString('device_host',host.trim());
      if(!mounted||generation!=connectionGeneration)return;
      setState((){api=a;state=s;message='Conectado';});
      poll=Timer.periodic(const Duration(seconds:4),(_)=>refresh());
    }catch(e){if(mounted&&generation==connectionGeneration)setState((){api=null;state=null;message='Sin conexión';});}
    finally{if(mounted&&generation==connectionGeneration)setState(()=>busy=false);}
  }
  Future<void> refresh()async{
    if(polling||busy||api==null)return;
    polling=true;
    final current=api;
    try{final s=await current?.getState();if(mounted&&s!=null&&identical(current,api))setState((){state=s;message='Conectado';});}
    catch(_){if(mounted&&identical(current,api))setState(()=>message='Sin respuesta');}
    finally{polling=false;}
  }
  void notice(String text){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));}
  Future<void> send(Map<String,String> fields)async{
    final a=api;if(a==null){notice('Conecta una ESP32 para aplicar cambios');return;}
    try{final s=await a.control(fields);if(mounted&&identical(a,api))setState(()=>state=s);}
    catch(e){notice('No se pudo enviar el comando: $e');}
  }
  Future<void> apply(StudioScene s)async{
    await send({'power':'true','color':'0x${s.color.toRadixString(16).padLeft(6,'0')}',
      'brightness':'${s.brightness}','effect':'${s.effect}','speed':'${s.speed}'});
  }
  Future<void> addScene()async{
    final s=state;if(s==null){notice('Conecta una ESP32 antes de guardar una escena');return;}
    final controller=TextEditingController();
    final name=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Guardar escena'),
      content:TextField(controller:controller,maxLength:32,autofocus:true,decoration:const InputDecoration(labelText:'Nombre de la escena')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:const Text('Guardar'))]));
    controller.dispose();
    if(name==null||name.isEmpty)return;
    setState(()=>saved=[...saved,StudioScene(name,s.color,s.brightness,s.effect,s.speed)]);
    await SceneStore.save(saved);notice('Escena guardada en este teléfono');
  }
  Future<void> editDevice({StudioDevice? existing})async{
    final ip=TextEditingController(text:existing?.host??'');
    final name=TextEditingController(text:existing?.name??'');
    final result=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,showDragHandle:true,
      builder:(ctx)=>Padding(padding:EdgeInsets.fromLTRB(24,12,24,MediaQuery.viewInsetsOf(ctx).bottom+32),
        child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(existing==null?'Añadir controlador':'Editar controlador',style:Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height:10),
          const Text('Conecta el teléfono a la misma red WiFi que el controlador.',style:TextStyle(color:Colors.white60)),
          const SizedBox(height:20),
          TextField(controller:name,textCapitalization:TextCapitalization.sentences,
            decoration:const InputDecoration(labelText:'Nombre',hintText:'LED del salón')),
          const SizedBox(height:12),
          TextField(controller:ip,keyboardType:TextInputType.url,
            decoration:const InputDecoration(labelText:'Dirección IP',hintText:'192.168.1.50')),
          const SizedBox(height:20),
          SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:const Text('Guardar controlador'))),
        ])));
    if(result==true){
      final address=ip.text.trim();
      final uri=Uri.tryParse(address.contains('://')?address:'http://$address');
      if(uri==null||uri.host.isEmpty||uri.host.contains(' ')||!(uri.scheme=='http'||uri.scheme=='https')){
        notice('Introduce una dirección IP o un host válido');
      }else{
        final id=existing?.id??DateTime.now().microsecondsSinceEpoch.toString();
        final device=StudioDevice(id:id,name:name.text.trim().isEmpty?'Controlador LED':name.text.trim(),host:address);
        setState((){
          devices=[for(final d in devices)if(d.id!=id)d,device];
          selectedId=id;host=device.host;deviceName=device.name;api=null;state=null;message='Sin conectar';
          devicePage=devices.indexWhere((d)=>d.id==id);
        });
        await DeviceStore.save(devices);await DeviceStore.select(id);
        await connect();
      }
    }
    ip.dispose();name.dispose();
  }
  Future<void> selectDevice(StudioDevice d)async{
    if(selectedId==d.id&&api!=null)return;
    setState((){selectedId=d.id;host=d.host;deviceName=d.name;api=null;state=null;message='Sin conectar';
      devicePage=devices.indexWhere((x)=>x.id==d.id);});
    await DeviceStore.select(d.id);await connect();
  }
  Future<void> removeDevice(StudioDevice d)async{
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Eliminar controlador'),
      content:Text('¿Eliminar "${d.name}" de esta aplicación?'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),
        TextButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Eliminar'))]));
    if(ok!=true)return;
    setState((){
      devices=devices.where((x)=>x.id!=d.id).toList();
      if(selectedId==d.id){connectionGeneration++;poll?.cancel();api=null;state=null;message='Sin conectar';selectedId=null;}
    });
    await DeviceStore.save(devices);
    if(devices.isNotEmpty&&selectedId==null){await selectDevice(devices.first);}
    if(devices.isEmpty){final p=await SharedPreferences.getInstance();await p.remove('device_host');}
  }
  Widget devicesPage()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:Text('Controladores',style:Theme.of(context).textTheme.titleLarge)),
      FilledButton.icon(onPressed:()=>editDevice(),icon:const Icon(Icons.add),label:const Text('Añadir'))]),
    const SizedBox(height:10),
    if(devices.isEmpty)card(const ListTile(leading:Icon(Icons.router_outlined),
      title:Text('No hay controladores'),subtitle:Text('Añade una ESP32 conectada a tu red WiFi.'))),
    ...devices.map((d)=>Card(child:ListTile(
      onTap:()=>selectDevice(d),leading:Icon(Icons.lightbulb_outline,color:d.id==selectedId?violet:Colors.white54),
      title:Text(d.name),subtitle:Text('${d.host} · ${d.id==selectedId?message:'Guardado'}'),
      trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit'){editDevice(existing:d);}else{removeDevice(d);}},
        itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Editar')),PopupMenuItem(value:'delete',child:Text('Eliminar'))])))),
    const SizedBox(height:10),
    OutlinedButton.icon(onPressed:scanBle,icon:const Icon(Icons.bluetooth_searching),label:const Text('Buscar por Bluetooth')),
    const Padding(padding:EdgeInsets.all(8),child:Text('La búsqueda Bluetooth detecta dispositivos compatibles, pero todavía no configura el WiFi.',style:TextStyle(color:Colors.white54))),
  ]);
  Widget mqttPage()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    section('Home Assistant · MQTT'),
    card(const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Integración pendiente',style:TextStyle(fontSize:18,fontWeight:FontWeight.w600)),
      SizedBox(height:10),
      Text('Para usar Home Assistant, el firmware ESP32 debe conectarse a un broker MQTT y publicar su estado. La aplicación no puede activar esa función por sí sola.'),
      SizedBox(height:12),
      SelectableText('Tema sugerido: mostys-led/<id>/state\nComandos: mostys-led/<id>/set'),
      SizedBox(height:12),
      Text('No introduzcas credenciales MQTT en esta versión: aún no existe un canal seguro para enviarlas a la ESP32.',style:TextStyle(color:Colors.white60)),
    ])),
  ]);
  Future<void> scanBle()async{
    notice('Buscando dispositivos BLE RGBStudio…');
    try{final found=await BleProvisioning.scan();notice('Dispositivos encontrados: ${found.length}. El aprovisionamiento WiFi aún no está disponible.');}
    catch(e){notice('Bluetooth: $e');}
  }
  void startNightlight(int minutes){
    nightTimer?.cancel();nightEnd=DateTime.now().add(Duration(minutes:minutes));
    nightTimer=Timer(Duration(minutes:minutes),(){send({'power':'false'});if(mounted)setState(()=>nightEnd=null);});
    setState((){});notice('Apagado programado en $minutes minutos. Requiere mantener abierta la app.');
  }
  Widget section(String title,{Widget? trailing})=>Padding(padding:const EdgeInsets.fromLTRB(3,20,3,9),child:Row(children:[
    Expanded(child:Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700))),
    if(trailing!=null)trailing]));
  Widget card(Widget child)=>Card(child:Padding(padding:const EdgeInsets.all(17),child:child));
  Widget header()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text("MORTY'S LED",style:TextStyle(color:violet,letterSpacing:3,fontSize:12,fontWeight:FontWeight.bold)),
    const SizedBox(height:5),
    Row(children:[Expanded(child:Text(['Iluminación','Escenas','Efectos','Dispositivos'][page],style:const TextStyle(fontSize:29,fontWeight:FontWeight.w800))),
      const SizedBox.shrink()]),
  ]);
  Widget preview(LedState? s)=>Container(height:150,decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),
    gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[
      Color(s?.color??0xFF8C65E5).withValues(alpha:0.48),const Color(0xFF22253B),const Color(0xFF101322)])),
    child:Stack(children:[Positioned(left:18,right:18,top:36,child:Row(children:List.generate(24,(i)=>Expanded(child:Container(
      height:20,margin:const EdgeInsets.symmetric(horizontal:1),decoration:BoxDecoration(
        color:(s?.power??false)?HSVColor.fromAHSV(1,(i*360/24+(s?.effect??0)*20)%360,0.95,0.95).toColor():Colors.white12,
        borderRadius:BorderRadius.circular(5),boxShadow:(s?.power??false)?[BoxShadow(color:Color(s?.color??0xFF8C65E5).withValues(alpha:0.5),blurRadius:11)]:null)))))),
      Positioned(left:18,bottom:15,child:Text('${s?.pixels??320} PÍXELES  ·  VISTA ILUSTRATIVA',style:const TextStyle(fontSize:10,letterSpacing:1.2,color:Colors.white70)))]));
  Widget deviceCarousel(){
    if(devices.isEmpty)return card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Tus luces',style:TextStyle(fontSize:19,fontWeight:FontWeight.w600)),
      const SizedBox(height:8),const Text('Añade tu primera tira.',style:TextStyle(color:Colors.white60)),
      const SizedBox(height:12),
      FilledButton.icon(onPressed:()=>editDevice(),icon:const Icon(Icons.add),label:const Text('Añadir tira')),
    ]));
    final currentIndex=devices.indexWhere((d)=>d.id==selectedId);
    return Column(children:[
      SizedBox(height:290,child:PageView.builder(
        key:ValueKey('led-cards-${devices.map((d)=>d.id).join('-')}'),
        controller:PageController(initialPage:currentIndex<0?0:currentIndex,viewportFraction:0.96),
        itemCount:devices.length,
        onPageChanged:(i){if(i>=0&&i<devices.length){devicePage=i;selectDevice(devices[i]);}},
        itemBuilder:(context,i){
          final d=devices[i],active=d.id==selectedId;
          final current=active?state:null;
          return Padding(padding:const EdgeInsets.only(right:8),child:Card(
            child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                Icon(Icons.lightbulb_outline,color:active?violet:Colors.white54),
                const SizedBox(width:10),
                Expanded(child:Text(d.name,maxLines:1,overflow:TextOverflow.ellipsis,
                  style:const TextStyle(fontSize:19,fontWeight:FontWeight.w600))),
                IconButton(tooltip:'Cambiar nombre',onPressed:()=>editDevice(existing:d),icon:const Icon(Icons.edit_outlined,size:20)),
              ]),
              Text(active?message:d.host,style:const TextStyle(color:Colors.white60,fontSize:12)),
              const SizedBox(height:12),
              Expanded(child:Container(decoration:BoxDecoration(
                color:current?.power==true?Color(current!.color).withValues(alpha:0.28):const Color(0xFF272B32),
                borderRadius:BorderRadius.circular(16)),
                child:Center(child:Icon(Icons.lightbulb,color:current?.power==true?Color(current!.color):Colors.white24,size:60)))),
              const SizedBox(height:8),
              Row(children:[
                Expanded(child:Text(current==null?'Sin conexión':'Brillo ${(current.brightness*100/255).round()}%',
                  style:const TextStyle(color:Colors.white70))),
                Switch(value:current?.power??false,onChanged:current==null?null:(v)=>send({'power':'$v'})),
              ]),
            ]))));
        },
      )),
      if(devices.length>1)Padding(padding:const EdgeInsets.only(top:8),child:Row(
        mainAxisAlignment:MainAxisAlignment.center,children:List.generate(devices.length,(i)=>Container(
          width:i==devicePage?18:6,height:6,margin:const EdgeInsets.symmetric(horizontal:3),
          decoration:BoxDecoration(color:i==devicePage?violet:Colors.white24,borderRadius:BorderRadius.circular(5)))))),
      TextButton.icon(onPressed:()=>setState(()=>page=3),icon:const Icon(Icons.devices_other),label:const Text('Gestionar dispositivos')),
    ]);
  }
  Widget homePage(){
    final s=state;
    return Column(children:[
      deviceCarousel(),
      if(s!=null)card(Column(children:[
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          const Text('Brillo'),Text('${(s.brightness*100/255).round()}%')]),
        Slider(value:s.brightness.toDouble().clamp(0,255),max:255,divisions:255,
          onChanged:(v)=>setState(()=>state=LedState(power:s.power,brightness:v.round(),effect:s.effect,speed:s.speed,color:s.color,pixels:s.pixels,audioLevel:s.audioLevel,wifi:s.wifi)),
          onChangeEnd:(v)=>send({'brightness':'${v.round()}'})),
      ])),
      section('Colores'),
      card(Wrap(spacing:13,runSpacing:13,children:colors.map((c)=>InkWell(onTap:()=>send({'power':'true','color':'0x${(c&0xFFFFFF).toRadixString(16).padLeft(6,'0')}','effect':'0'}),
        child:Container(width:43,height:43,decoration:BoxDecoration(color:Color(c),shape:BoxShape.circle,border:Border.all(color:Colors.white24,width:2))))).toList())),
      section('Escenas',trailing:TextButton(onPressed:()=>setState(()=>page=1),child:const Text('Ver todas'))),
      SizedBox(height:130,child:ListView(scrollDirection:Axis.horizontal,children:builtInScenes.take(4).map((e)=>sceneTile(e)).toList())),
      section('Accesos rápidos'),
      card(Row(children:[Expanded(child:OutlinedButton.icon(onPressed:()=>startNightlight(30),icon:const Icon(Icons.bedtime_outlined),label:const Text('Apagar en 30m'))),
        const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:addScene,icon:const Icon(Icons.bookmark_add_outlined),label:const Text('Guardar escena')))])),
    ]);
  }
  Widget sceneTile(StudioScene scene,{bool removable=false})=>SizedBox(width:146,child:Card(clipBehavior:Clip.antiAlias,child:InkWell(
    onTap:()=>apply(scene),child:Container(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
      colors:[Color(scene.color).withValues(alpha:0.85),panel])),
      child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[const Icon(Icons.auto_awesome,size:19),const Spacer(),
          if(removable)InkWell(onTap:()async{setState(()=>saved=saved.where((e)=>!identical(e,scene)).toList());await SceneStore.save(saved);},
            child:const Icon(Icons.close,size:18))]),
        const Spacer(),Text(scene.name,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700)),
        const Text('Aplicar',style:TextStyle(fontSize:10,color:Colors.white70))]))))));
  Widget scenesPage()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const SizedBox.shrink(),
    section('Galería de ambientes'),
    GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.23,
      children:builtInScenes.map((s)=>sceneTile(s)).toList()),
    section('Mis escenas',trailing:TextButton.icon(onPressed:addScene,icon:const Icon(Icons.add),label:const Text('Guardar actual'))),
    if(saved.isEmpty)card(const Text('Todavía no tienes escenas guardadas. Conecta tu dispositivo y pulsa «Guardar actual».',style:TextStyle(color:Colors.white60))),
    if(saved.isNotEmpty)GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.23,
      children:saved.map((s)=>sceneTile(s,removable:true)).toList()),
    card(const Text('Las escenas personalizadas se guardan en este teléfono. Los efectos disponibles dependen del firmware de la ESP32.',style:TextStyle(color:Colors.white60,fontSize:12))),
  ]);
  Widget effectsPage(){
    final s=state;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Los efectos disponibles dependen del firmware instalado.',style:TextStyle(color:Colors.white60)),
      section('Efectos dinámicos'),
      ...List.generate(effectNames.length,(i)=>Card(child:ListTile(
        leading:CircleAvatar(backgroundColor:Color(colors[i%colors.length]).withValues(alpha:0.25),child:Icon([Icons.circle,Icons.gradient,Icons.local_fire_department,Icons.auto_awesome,Icons.blur_on,Icons.waves][i%6],color:Color(colors[i]))),
        title:Text(effectNames[i]),subtitle:Text(i==0?'Color constante':'Animación LED · modo $i'),
        trailing:Icon(s?.effect==i?Icons.check_circle:Icons.chevron_right,color:s?.effect==i?violet:Colors.white38),
        onTap:()=>send({'effect':'$i','power':'true'})))),
      section('Velocidad del efecto'),
      card(Column(children:[
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Velocidad'),Text('${s?.speed??100} / 255')]),
        Slider(value:(s?.speed??100).toDouble().clamp(1,255),min:1,max:255,divisions:254,
          onChanged:s==null?null:(v)=>setState(()=>state=LedState(power:s.power,brightness:s.brightness,effect:s.effect,speed:v.round(),color:s.color,pixels:s.pixels,audioLevel:s.audioLevel,wifi:s.wifi)),
          onChangeEnd:(v)=>send({'speed':'${v.round()}'}))])),
      card(const ListTile(leading:Icon(Icons.music_note_outlined,color:violet),title:Text('Modo música'),subtitle:Text('Próximamente · requiere firmware con INMP441 e I²S'))),
      card(const ListTile(leading:Icon(Icons.view_week_outlined,color:violet),title:Text('Segmentos RGBIC'),subtitle:Text('Próximamente · requiere API de segmentos en ESP32'))),
    ]);
  }
  Widget settingsPage()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    devicesPage(),
    section('Conexión'),
    card(Column(children:[
      ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.lightbulb_outline,color:violet),title:Text(deviceName),
        subtitle:Text('$host · $message'),trailing:IconButton(onPressed:()=>editDevice(existing:devices.where((d)=>d.id==selectedId).isEmpty?null:devices.firstWhere((d)=>d.id==selectedId)),icon:const Icon(Icons.edit_outlined))),
      const Divider(),ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.refresh,color:violet),
        title:const Text('Actualizar estado'),onTap:refresh),
      ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.bluetooth_searching,color:violet),
        title:const Text('Buscar por Bluetooth'),subtitle:const Text('Solo detección, sin configuración WiFi'),onTap:scanBle),
    ])),
    section('Temporizador local'),
    card(Column(children:[
      if(nightEnd!=null)Text('Apagado previsto: ${TimeOfDay.fromDateTime(nightEnd!).format(context)}'),
      Wrap(spacing:8,children:[15,30,60,120].map((n)=>ActionChip(label:Text('$n min'),onPressed:()=>startNightlight(n))).toList()),
      const SizedBox(height:8),const Text('El temporizador funciona en el teléfono y requiere mantener la aplicación abierta. No es una automatización del dispositivo.',style:TextStyle(color:Colors.white60,fontSize:12)),
      if(nightEnd!=null)TextButton(onPressed:(){nightTimer?.cancel();setState(()=>nightEnd=null);},child:const Text('Cancelar temporizador')),
    ])),
    mqttPage(),
    section('Acerca de'),
    card(const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text("Morty's LED · prototipo 0.3",style:TextStyle(fontWeight:FontWeight.bold)),
      SizedBox(height:8),Text('Control WiFi local. Sin nube ni cuenta. Escenas almacenadas localmente.',style:TextStyle(color:Colors.white70)),
      SizedBox(height:8),Text('BLE WiFi, música, segmentos, horarios persistentes y MQTT requieren firmware y desarrollo adicional.',style:TextStyle(color:Colors.amberAccent,fontSize:12)),
    ])),
  ]);
  @override Widget build(BuildContext context)=>Scaffold(
    body:SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(16,22,16,25),children:[
      header(),const SizedBox(height:15),[homePage,scenesPage,effectsPage,settingsPage][page]()])),
    bottomNavigationBar:NavigationBar(selectedIndex:page,onDestinationSelected:(i)=>setState(()=>page=i),
      destinations:const [
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Inicio'),
        NavigationDestination(icon:Icon(Icons.auto_awesome_outlined),selectedIcon:Icon(Icons.auto_awesome),label:'Escenas'),
        NavigationDestination(icon:Icon(Icons.blur_on_outlined),selectedIcon:Icon(Icons.blur_on),label:'Efectos'),
        NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings),label:'Dispositivos')]),
  );
  @override void dispose(){poll?.cancel();nightTimer?.cancel();super.dispose();}
}
