# Instalación y compilación Android

## APK mediante GitHub Actions

1. Abrir la pestaña **Actions** del repositorio.
2. Elegir **Android APK**.
3. Pulsar **Run workflow** (rama `main`).
4. Esperar a que la ejecución termine en verde.
5. En la página de esa ejecución, descargar el artefacto **ESP32-RGB-Studio-Android-APK**.
6. Descomprimir el artefacto y transferir `app-release.apk` al móvil Android.
7. Instalar el APK autorizando, si es necesario, la instalación desde esa fuente.

**Aviso:** mientras la ejecución no termine correctamente, no hay APK verificado. El APK de CI usa la firma de depuración/release predeterminada del entorno Flutter; **no** es una distribución firmada para Play Store. La firma de producción requerirá un keystore gestionado como secreto.

## Desarrollo local

Requisitos: Flutter estable, Android SDK y dispositivo/emulador Android.

```bash
git clone https://github.com/Mortymel/ESP32-RGB-Studio-.git
cd ESP32-RGB-Studio-
flutter create --platforms=android --project-name esp32_rgb_studio .
python3 scripts/configure_android.py
flutter pub get
flutter analyze --no-fatal-infos
flutter run
```

La orden `flutter create` genera la carpeta `android/` durante el build. El proyecto conserva deliberadamente la configuración Android como script para facilitar las pruebas iniciales.

## Conectar la ESP32

1. Alimentar correctamente la ESP32 y la tira.
2. Conectar el móvil a la misma red WiFi que la ESP32.
3. En Android, abrir **Dispositivos → Añadir**, introducir nombre, IP local y **Cantidad de LED / píxeles** (1–1024).
4. Pulsar **Guardar controlador**. La app conecta, aplica la cantidad y comprueba la respuesta. Se puede cambiar en **Editar controlador**; si está desconectado, se aplicará al reconectar.
5. Si el firmware implementa los endpoints compatibles, aparecerá el estado y los controles.

La IP `192.168.4.1` es un valor inicial orientativo para modo punto de acceso; no implica que el firmware actual active ese modo.

## Bluetooth

El botón Bluetooth intenta buscar dispositivos anunciados como `RGBStudio...`. La app **no puede configurar el WiFi por BLE todavía**: esa función necesita firmware nuevo, protocolo de características GATT y medidas de seguridad.
