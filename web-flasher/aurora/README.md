# Web flasher de Aurora

[Instalador público](https://mortymel.github.io/ESP32-RGB-Studio-/). Publica LEDWeb 1.3.0 para ESP32-C6 y ESP32 clásico/WROOM de al menos 4 MB. Chrome/Edge de escritorio, HTTPS y cable USB de datos. La selección de familia es automática; las imágenes fusionadas van desde 0x0 y no son archivos OTA.

aurora-flasher.yml genera la interfaz web, instala herramientas fijadas, compila ambos chips, verifica cabeceras/particiones/tamaño, genera SHA-256, sube artefactos y despliega esta carpeta como raíz de GitHub Pages. build-info.json contiene versión y hashes. El workflow heredado no debe publicar sobre esta página.

[Primera conexión](../../docs/INSTALACION.md) · [Hardware](../../docs/HARDWARE.md) · [Auditoría](../../docs/AUDITORIA.md). No se ha verificado instalación USB en una placa física durante esta revisión.
