import hashlib
import json
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
manifest = json.loads((root / 'manifest.json').read_text())
assert {b['chipFamily'] for b in manifest['builds']} == {'ESP32', 'ESP32-C6'}
images = []
for build in manifest['builds']:
    part, = build['parts']
    assert part['offset'] == 0
    file = root / part['path']
    assert file.resolve().parent == root
    data = file.read_bytes()
    assert len(data) == 4 * 1024 * 1024, 'Expected 4 MB merged flash image'
    boot_offset, chip = (0, 13) if build['chipFamily'] == 'ESP32-C6' else (0x1000, 0)
    assert data[boot_offset] == 0xe9, 'Invalid bootloader header'
    assert int.from_bytes(data[boot_offset+12:boot_offset+14], 'little') == chip, 'Wrong chip family'
    assert data[0x10000] == 0xe9, 'Application missing'
    assert int.from_bytes(data[0x1000c:0x1000e], 'little') == chip, 'Wrong application family'
    assert data[0x8000:0x8002] == b'\xaa\x50', 'Partition table missing'
    images.append({'chip': build['chipFamily'], 'file': part['path'], 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
(root / 'build-info.json').write_text(json.dumps({'version': manifest['version'], 'images': images}, indent=2)+'\n')
print('Validated both bootloaders, application headers, partitions, size and hashes.')
