"""Apply Aurora Android settings after `flutter create --platforms=android .`."""
from pathlib import Path
import xml.etree.ElementTree as ET

ns = '{http://schemas.android.com/apk/res/android}'
ET.register_namespace('android', ns[1:-1])
manifest = Path('android/app/src/main/AndroidManifest.xml')
root = ET.parse(manifest).getroot()
for permission in ['android.permission.INTERNET', 'android.permission.ACCESS_NETWORK_STATE', 'android.permission.CHANGE_WIFI_MULTICAST_STATE', 'android.permission.ACCESS_WIFI_STATE']:
    if not any(item.get(ns + 'name') == permission for item in root.findall('uses-permission')):
        ET.SubElement(root, 'uses-permission', {ns + 'name': permission})
app = root.find('application')
assert app is not None
for key, value in {'label': 'Aurora', 'allowBackup': 'false', 'fullBackupContent': 'false',
                   'dataExtractionRules': '@xml/data_extraction_rules',
                   'usesCleartextTraffic': 'true', 'icon': '@drawable/aurora_icon'}.items():
    app.set(ns + key, value)
manifest.write_text(ET.tostring(root, encoding='unicode') + '\n', encoding='utf-8')
resources = manifest.parent / 'res'
(resources / 'xml').mkdir(exist_ok=True)
(resources / 'xml/data_extraction_rules.xml').write_text('''<data-extraction-rules>
  <cloud-backup><exclude domain="root" path="."/><exclude domain="sharedpref" path="."/><exclude domain="file" path="."/><exclude domain="database" path="."/></cloud-backup>
  <device-transfer><exclude domain="root" path="."/><exclude domain="sharedpref" path="."/><exclude domain="file" path="."/><exclude domain="database" path="."/></device-transfer>
</data-extraction-rules>\n''', encoding='utf-8')
(resources / 'drawable/aurora_icon.xml').write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
  <path android:fillColor="#F3F2F8" android:pathData="M0,0h108v108h-108z"/>
  <path android:fillColor="#7959C5" android:pathData="M54,23a31,31 0,1 0,0 62a31,31 0,1 0,0 -62"/>
  <path android:fillColor="#B987D3" android:pathData="M45,29a22,22 0,1 0,0 44a22,22 0,1 0,0 -44"/>
  <path android:fillColor="#EEE8FB" android:pathData="M61,35l4,11l11,4l-11,4l-4,11l-4,-11l-11,-4l11,-4z"/>
</vector>\n''', encoding='utf-8')
assert app.get(ns + 'allowBackup') == 'false'
assert app.get(ns + 'label') == 'Aurora'
print('Aurora: Internet/LAN, backup disabled, native launcher icon configured.')
activity=manifest.parent / 'kotlin/com/mortymel/aurora_led/MainActivity.kt'
activity.parent.mkdir(parents=True,exist_ok=True)
activity.write_text('''package com.mortymel.aurora_led
import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
class MainActivity: FlutterActivity() {
 private var multicast: WifiManager.MulticastLock? = null
 override fun configureFlutterEngine(engine: FlutterEngine) {
  super.configureFlutterEngine(engine)
  MethodChannel(engine.dartExecutor.binaryMessenger,"aurora/network").setMethodCallHandler { call,result ->
   when(call.method) {
    "acquire" -> { if(multicast==null) { val manager=applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager; multicast=manager.createMulticastLock("aurora-discovery").apply { setReferenceCounted(false); acquire() } }; result.success(null) }
    "release" -> { if(multicast?.isHeld==true)multicast?.release(); multicast=null; result.success(null) }
    else -> result.notImplemented()
   }
  }
 }
 override fun onDestroy() { if(multicast?.isHeld==true)multicast?.release(); multicast=null; super.onDestroy() }
}
''',encoding='utf-8')
