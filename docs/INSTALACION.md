# Instalar Aurora y conectar una ESP32

## Requisitos

Android 7.0 o superior. Para flashear: Chrome o Edge de escritorio con Web Serial, conexión HTTPS, cable USB de datos y una placa ESP32-C6 o ESP32 clásico/WROOM con flash de al menos 4 MB. No existe un único binario para todas las familias ESP32.

## Firmware

Abre el [web flasher](https://mortymel.github.io/Aurora-RGB/), desconecta la tira durante la instalación, conecta la placa por USB y cierra el monitor serie. Pulsa Conectar e instalar y elige el puerto. El instalador detecta el chip. La instalación puede borrar el programa y la configuración anteriores.

Si no entra en descarga, mantén BOOT, pulsa RESET y suelta BOOT cuando empiece a conectar. Los controladores USB dependen de la placa; consulta su fabricante si no aparece un puerto.

## APK

Abre [la última versión en Releases](https://github.com/Mortymel/Aurora-RGB/releases/latest). En Assets descarga el archivo `.apk` y, si quieres comprobarlo, su `.sha256`. Instala el APK en Android y autoriza esa fuente si se solicita. Puedes entrar en Probar sin placa. Cada release identifica la compilación y el commit de origen.

El workflow Publish Aurora APK Release publica automáticamente los APK verificados de compilaciones correctas por push a main o a la rama de Aurora. Las compilaciones de pull requests no se promocionan por ese evento. Actions conserva sus artefactos temporales como alternativa.

El APK tiene firma de prueba. Si una versión anterior tiene otra firma, Android puede rechazar la actualización. Desinstalar elimina las credenciales y preferencias locales: anota las direcciones y asegúrate de conocer tus claves antes de hacerlo. No se proporciona todavía actualización estable desde Google Play.

## Verificar la descarga

Si quieres verificar la descarga en Windows, abre PowerShell en la carpeta del APK y su archivo `.sha256`:

```powershell
$file = 'Aurora-1.1.1.apk'
$expected = ((Get-Content ($file + '.sha256')) -split '\s+')[0]
(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLower() -eq $expected
```

El resultado debe ser `True`. Usa el nombre de archivo de la versión que hayas descargado. Si no coincide, descarga otra vez desde Releases antes de instalar.

## Conectar el teléfono y la placa

1. Reinicia la ESP32 y conecta el teléfono a `LEDWeb-…`, clave inicial `tiraesp32`.
2. En Añadir ESP32 introduce nombre, `192.168.4.1`, usuario `admin` y contraseña inicial `tiraesp32`. Si compilaste con otras claves, usa esas.
3. En Ajustes → Wi-Fi guarda tu SSID de 2,4 GHz y su contraseña.
4. Vuelve a tu Wi-Fi habitual. Busca la IP asignada en el router o monitor serie a 115200 baudios.
5. Edita IP y credenciales en Aurora o usa Buscar en mi Wi-Fi. Una reserva DHCP evita cambios de IP.

Alternativa de configuración: abre `http://192.168.4.1` en el navegador desde el AP. Si no conecta a tu Wi-Fi, la placa mantiene/abre el AP de recuperación.

## Ajustes iniciales

320 píxeles, GPIO4 y GRB. La tira indicada tiene 160 píxeles por metro; dos metros corresponden a 320. Elige un GPIO libre real y prueba rojo/verde/azul a brillo bajo para comprobar el orden RGB/GRB. El arranque es apagado salvo que habilites recuperación del estado en LEDWeb 1.3.

[Hardware](HARDWARE.md) · [Problemas](SOLUCION-DE-PROBLEMAS.md).
