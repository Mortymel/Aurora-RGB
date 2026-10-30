# Aurora web flasher

LEDWeb 1.3 añade límite físico de brillo, transiciones de encendido/apagado, dirección invertida, recuperación opcional del estado persistido y diagnóstico. Aurora Android 1.1 permite configurar estas opciones. El diseño del instalador comparte el aspecto claro/oscuro y las tarjetas de Aurora.

Página pública: https://mortymel.github.io/ESP32-RGB-Studio-/

Usar Chrome o Edge de escritorio, cable USB de datos y puerto serie libre. El manifiesto selecciona automáticamente ESP32-C6 o ESP32 clásico; ambos binarios fusionados se escriben desde 0x0 y requieren flash de 4 MB o más.

Después: conectar el teléfono a LEDWeb-… (clave inicial tiraesp32), añadir 192.168.4.1 en Aurora con admin/tiraesp32 y configurar el Wi-Fi de 2,4 GHz. Cambiar luego la dirección por la IP asignada en el router. Las claves propias de administrador/AP se establecen al compilar config.h.

El workflow aurora-flasher.yml compila las dos familias, verifica sus cabeceras, particiones y tamaño, genera SHA-256 y publica GitHub Pages. El workflow del firmware anterior conserva sus artefactos de descarga pero ya no publica sobre esta página.

No se ha verificado la instalación en una placa física en esta sesión. La instalación puede borrar firmware y ajustes. No confundir los binarios fusionados del instalador con un archivo OTA.
