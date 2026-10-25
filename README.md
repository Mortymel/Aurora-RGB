# ESP32 RGB Studio

Flutter Android app for ESP32-WROOM-32 RGB LED controller (320 pixels).

The app controls firmware v0.1 over local Wi-Fi. Bluetooth scanning is experimental; secure Wi-Fi provisioning is not implemented in the ESP32 firmware yet.

## Android APK
Go to Actions > Android APK > Run workflow. When successful, download the APK artifact.

The build creates Android platform scaffolding with `flutter create`, configures permissions, and compiles a release APK. This code has not yet been build-tested.

## Local development
`flutter create --platforms=android --project-name esp32_rgb_studio .`
`python3 scripts/configure_android.py`
`flutter pub get`
`flutter run`
