from pathlib import Path
import xml.etree.ElementTree as ET

manifest = Path('android/app/src/main/AndroidManifest.xml')
if not manifest.exists():
    raise SystemExit('AndroidManifest.xml not found; run flutter create first')
ET.register_namespace('android', 'http://schemas.android.com/apk/res/android')
ns = '{http://schemas.android.com/apk/res/android}'
root = ET.parse(manifest).getroot()
permissions = [
    ('android.permission.INTERNET', None),
    ('android.permission.ACCESS_NETWORK_STATE', None),
    ('android.permission.ACCESS_WIFI_STATE', None),
    ('android.permission.CHANGE_WIFI_MULTICAST_STATE', None),
    ('android.permission.BLUETOOTH_SCAN', None),
    ('android.permission.BLUETOOTH_CONNECT', None),
    ('android.permission.BLUETOOTH', '30'),
    ('android.permission.BLUETOOTH_ADMIN', '30'),
    ('android.permission.ACCESS_FINE_LOCATION', '30'),
]
for name, max_sdk in permissions:
    if not any(e.get(ns + 'name') == name for e in root.findall('uses-permission')):
        attributes = {ns + 'name': name}
        if name == 'android.permission.BLUETOOTH_SCAN':
            attributes[ns + 'usesPermissionFlags'] = 'neverForLocation'
        if max_sdk:
            attributes[ns + 'maxSdkVersion'] = max_sdk
        ET.SubElement(root, 'uses-permission', attributes)
application = root.find('application')
if application is None:
    raise SystemExit('Application element missing')
application.set(ns + 'usesCleartextTraffic', 'true')
application.set(ns + 'label', "Morty's LED")
manifest.write_text(ET.tostring(root, encoding='unicode') + '\n', encoding='utf-8')
print('Android permissions and LAN HTTP access configured')

