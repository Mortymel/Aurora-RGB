import os
import runpy
import tempfile
import unittest
from pathlib import Path
import xml.etree.ElementTree as ET

class AndroidConfigurationTest(unittest.TestCase):
    def test_permissions_are_correct_and_configuration_is_idempotent(self):
        script = Path(__file__).with_name('configure_android.py').resolve()
        previous = Path.cwd()
        with tempfile.TemporaryDirectory(dir=previous) as directory:
            try:
                assert Path(directory).resolve().is_relative_to(previous.resolve())
                os.chdir(directory)
                manifest = Path('android/app/src/main/AndroidManifest.xml')
                manifest.parent.mkdir(parents=True)
                manifest.write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application/></manifest>', encoding='utf-8')
                runpy.run_path(str(script))
                first = manifest.read_text(encoding='utf-8')
                runpy.run_path(str(script))
                self.assertEqual(first, manifest.read_text(encoding='utf-8'))
                root = ET.fromstring(first); ns = '{http://schemas.android.com/apk/res/android}'
                permissions = {e.get(ns+'name'):e for e in root.findall('uses-permission')}
                self.assertEqual(len(permissions),len(root.findall('uses-permission')))
                self.assertEqual(permissions['android.permission.BLUETOOTH_SCAN'].get(ns+'usesPermissionFlags'),'neverForLocation')
                self.assertEqual(permissions['android.permission.ACCESS_FINE_LOCATION'].get(ns+'maxSdkVersion'),'30')
                self.assertIn('android.permission.CHANGE_WIFI_MULTICAST_STATE',permissions)
                self.assertEqual(root.find('application').get(ns+'usesCleartextTraffic'),'true')
            finally:
                os.chdir(previous)

if __name__ == '__main__': unittest.main()
