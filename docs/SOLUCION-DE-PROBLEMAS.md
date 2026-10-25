# Solución de problemas

## GitHub Actions falla en «Analyze Dart code»

El workflow genera archivos de plataforma Android mediante `flutter create`. Si se genera `test/widget_test.dart` de ejemplo, este puede referirse a una clase `MyApp` inexistente. La configuración de CI actual elimina ese archivo y declara dependencias de pruebas y lint.

Abrir el trabajo fallido y consultar la **primera línea con `error •`**. No confundir avisos de paquetes desactualizados con errores de compilación.

## GitHub Actions falla en «Build release APK»

Leer el primer error de Gradle o Dart. Comprobar versiones de Flutter, Java, plugins y permisos Android. No descargar ni instalar artefactos de una ejecución roja.

## El móvil no encuentra la ESP32

- Comprobar que la ESP32 está encendida y el firmware ofrece HTTP.
- Verificar que móvil y ESP32 estén en la misma red/subred, sin aislamiento de clientes.
- Usar la IP local correcta; `192.168.4.1` solo aplica si el dispositivo ofrece un AP con esa dirección.
- Revisar el puerto y el endpoint `/api/state`.

## La app conecta, pero los efectos no coinciden

Los identificadores numéricos de efectos y el formato del color necesitan coincidir con el firmware. Revisar [API.md](API.md).

## Bluetooth no configura WiFi

Comportamiento esperado en esta versión: únicamente hay descubrimiento experimental. No enviar contraseñas a servicios GATT sin protocolo autenticado.

## La tira parpadea o muestra colores erróneos

Desconectar alimentación antes de modificar conexiones. Revisar tierra común, nivel lógico, caída de tensión, orden RGB y protocolo real de la tira. Consultar [HARDWARE.md](HARDWARE.md).
