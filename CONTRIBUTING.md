# Contribuir a Aurora

Trabaja sobre las rutas y versiones del [README](README.md). La app actual está en su rama/PR; el Flutter raíz pertenece al código heredado.

1. Describe el problema y una reproducción concreta en un issue. Incluye versión, placa, Android y si ocurre en demo o hardware.
2. Usa una rama descriptiva; no incluyas credenciales, tokens, config.local.h, claves de firma, cachés ni binarios de herramientas.
3. Para app: dentro de apps/aurora_flutter ejecuta flutter pub get, flutter analyze y flutter test con Flutter 3.47.8. Al regenerar Android conserva pubspec.lock antes de flutter create, restáuralo después y ejecuta scripts/configure_android.py. El workflow implementa esa secuencia.
4. Para firmware: genera el header web y compila C6 y ESP32 clásico con las dependencias fijadas. Ejecuta verify-flasher.py con las dos imágenes fusionadas.
5. Comprueba contratos de API, compatibilidad de preferencias, respuesta ante red desconectada, tamaño móvil y seguridad de credenciales. Prueba las rutas afectadas; no anuncies validación física si solo compilaste.

Una pull request debe describir el comportamiento final, pruebas realizadas y límites. Distingue funciones entregadas de propuestas.
