import json
from pathlib import Path
root = Path('web-flasher')
manifest = json.loads((root/'manifest.json').read_text(encoding='utf-8-sig'))
assert manifest['version'] == '0.8.0'
assert manifest['builds'][0]['chipFamily'] == 'ESP32'
assert manifest['builds'][0]['parts'] == [{'path': 'firmware.bin', 'offset': 0}]
merged = (root/'firmware.bin').read_bytes()
assert 0x10000 < len(merged) <= 4*1024*1024
for offset, source in [(0x1000, 'bootloader.bin'), (0x8000, 'partitions.bin'), (0x10000, 'firmware.bin')]:
    original = (Path('firmware/.pio/build/esp32dev')/source).read_bytes()
    assert merged[offset:offset+len(original)] == original, f'Merged image mismatch: {source}'
print(f'Firmware offsets, image and installer version verified: {len(merged)} bytes')
