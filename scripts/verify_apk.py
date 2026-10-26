import sys
from zipfile import ZipFile
from pathlib import Path
apk = Path(sys.argv[1])
with ZipFile(apk) as archive:
    assert archive.testzip() is None, 'Corrupt APK ZIP'
    names = set(archive.namelist())
    for required in ['AndroidManifest.xml', 'classes.dex', 'lib/arm64-v8a/libapp.so', 'lib/arm64-v8a/libflutter.so']:
        assert required in names, f'Missing APK entry: {required}'
    assert apk.stat().st_size > 1_000_000, 'Unexpectedly small APK'
print(f'APK structure verified: {apk.stat().st_size} bytes')
