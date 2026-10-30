# Interfaz web de LEDWeb

Esta carpeta contiene HTML, CSS, JavaScript, transporte del mismo origen y vista previa para la interfaz alojada en la ESP32. Es independiente de la app Android Flutter.

Desde la raíz del repositorio ejecuta `node ledweb/scripts/build-aurora.cjs` para generar ledweb/firmware/LEDWeb/aurora_ui.h. El header se incluye al compilar LEDWeb 1.3; no se carga un sistema de archivos aparte. Abre la IP de la ESP32 con las credenciales de config.h; /classic conserva la interfaz alternativa de LEDWeb.

Para Android usa el [proyecto Flutter](https://github.com/Mortymel/Aurora-RGB/tree/codex/aurora-flutter-android/apps/aurora_flutter). [Documentación de Aurora](../../../docs/README.md).
