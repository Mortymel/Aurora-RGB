# Aurora Android 1.1.1

App nativa Flutter para ESP32 con LEDWeb 1.3.0. Código actual: [rama Aurora](https://github.com/Mortymel/Aurora-RGB/tree/codex/aurora-flutter-android/apps/aurora_flutter). Integración en [PR #1](https://github.com/Mortymel/Aurora-RGB/pull/1); no asumir que el código de la app está fusionado en main. El Flutter de la raíz es heredado.

## Uso

Rueda de color, vista en vivo, 32 efectos, favoritos y ambientes, deshacer, cuatro horarios, cuenta atrás, varios controladores, IP/mDNS, Wi-Fi/MQTT y diagnóstico. LEDWeb 1.3 añade límite de brillo, dirección invertida, transición de encendido/apagado y recuperación optativa del estado persistido. La demo permite navegar sin placa; sus acciones se evalúan con la app activa.

[Instalar firmware](https://mortymel.github.io/Aurora-RGB/) · [Guía completa](https://github.com/Mortymel/Aurora-RGB/blob/main/docs/INSTALACION.md) · [API](https://github.com/Mortymel/Aurora-RGB/blob/main/docs/API.md) · [Auditoría](AUDIT.md).

## Compilar

Flutter 3.47.8 / Dart 3.13.7, Java 17 y Android SDK. Android mínimo API 24 (7.0), destino API 36. Desde la rama de Aurora, dentro de apps/aurora_flutter, en Bash:

~~~sh
cp pubspec.lock pubspec.lock.saved
flutter create --platforms=android --org com.mortymel --project-name aurora_led --no-pub .
mv pubspec.lock.saved pubspec.lock
python3 scripts/configure_android.py
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --release
~~~

En PowerShell usa Copy-Item y Move-Item para conservar/restaurar el lockfile. El script Python configura manifiesto, icono, exclusión de backup y el canal nativo para el bloqueo multicast. No omitirlo al regenerar Android.

Salida: build/app/outputs/flutter-apk/app-release.apk. Identidad: com.mortymel.aurora_led, versión 1.1.1+5. El workflow aurora-android.yml verifica análisis, pruebas, firma, versión y SHA-256 y publica el artefacto Aurora-Flutter-Android-1.1.1.

## Seguridad y límites

Las credenciales se guardan con flutter_secure_storage. Android declara Internet, estado de red/Wi-Fi y multicast; no necesita Bluetooth, ubicación, cámara ni micrófono. HTTP Basic en la LAN y MQTT sin TLS no cifran el tráfico. No exponer el controlador a Internet.

El APK utiliza firma de prueba del entorno: no hay una clave estable de distribución ni publicación en Google Play. Otra firma puede exigir reinstalar y perder preferencias locales. No publicar keystores o contraseñas en Git.

16 pruebas aprobadas y análisis sin incidencias. Falta validar en teléfono/router/placa/tira y broker reales. No se incluyen OTA, grupos, segmentos, widgets, horarios solares ni escena específica por horario.

## Rendimiento de Efectos en 1.1.1

Se retira la tira animada de esa pestaña y el muestreo de píxeles por tarjeta. El catálogo usa carga progresiva y separación de repintados. Las pruebas comprueban que no se montan las 32 tarjetas de golpe y que se puede llegar al último efecto y aplicarlo. No se ha medido la tasa de cuadros en todos los teléfonos. La simulación animada permanece solo en Mi luz; el firmware no cambia por esta corrección.
