# Compilar y verificar Aurora

## Qué repositorio y qué carpeta

Repositorio: https://github.com/Mortymel/Aurora-RGB. La app está en la rama codex/aurora-flutter-android, carpeta apps/aurora_flutter. LEDWeb y el instalador están en main, bajo ledweb/ y web-flasher/aurora. La raíz lib/, firmware/ y pubspec.yaml corresponden al código heredado. No ejecutes flutter build desde esa raíz para generar Aurora.

## Android

Herramientas contrastadas: Flutter 3.47.8, Dart 3.13.7, Java 17 y Android SDK. Requiere Android API 24 o superior; el APK se compila con API objetivo 36. Ejemplo desde un clon limpio, en Bash:

~~~sh
git switch codex/aurora-flutter-android
cd apps/aurora_flutter
cp pubspec.lock pubspec.lock.saved
flutter create --platforms=android --org com.mortymel --project-name aurora_led --no-pub .
mv pubspec.lock.saved pubspec.lock
python3 scripts/configure_android.py
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --release
~~~

En PowerShell usa Copy-Item y Move-Item para conservar/restaurar el lockfile, y el ejecutable Python disponible. No omitas configure_android.py: configura permisos, backup, icono y el canal nativo de descubrimiento. Al regenerar Android, conserva siempre el lockfile de dependencias.

Salida: build/app/outputs/flutter-apk/app-release.apk. Identidad com.mortymel.aurora_led; referencia actual 1.1.1+5. El workflow Aurora Flutter Android repite análisis, pruebas, compilación y comprobaciones de identidad/versión/firma/hash.

## Firmware e instalador

Desde main, instala Arduino CLI, core esp32:esp32@3.3.12 con el índice de Espressif, NeoPixel 1.15.5, ArduinoJson 7.4.3 y PubSubClient 2.8. Sigue [FIRMWARE.md](FIRMWARE.md); la secuencia exacta está en .github/workflows/aurora-flasher.yml. Genera aurora_ui.h antes de compilar. Nunca copies un binario entre familias de chips.

En Windows, el compilador del core puede fallar con rutas largas. Usa una ubicación corta para SDK, cachés y proyecto, o la compilación Linux del workflow. Que el código compile en CI no garantiza que todas las instalaciones locales tengan las herramientas o rutas correctas.

## Releases y firma

Publish Aurora APK Release toma un artefacto de una compilación correcta por push de main o de la rama Aurora, comprueba identidad, versión y SHA-256, prepara una release en borrador y la publica al completar las subidas. No promociona builds de forks/PR por el evento workflow_run. El tag incluye versión y número de ejecución para identificar el origen. También puede ejecutarse manualmente para publicar la última compilación válida disponible.

El botón de descarga recomendado está en [Releases](https://github.com/Mortymel/Aurora-RGB/releases/latest). Actions conserva artefactos temporales como alternativa. Un APK release optimizado no significa que tenga una clave de producción: la firma actual es de prueba y puede cambiar entre entornos. Para distribuir actualizaciones estables se necesita conservar una clave privada propia fuera del repositorio.

## Qué verificar al cambiar código

Luz/API: autenticación, límites y errores. UI: 320/390 px, navegación, búsqueda, favoritos y selección al final del catálogo. Red: desconexión, cambio de dispositivo y ausencia de reenvíos tardíos. Firmware: ambos chips, cabeceras/particiones y hashes. Declarar por separado lo probado en placa, teléfono y broker reales.
