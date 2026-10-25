# Historial de versiones — Morty's LED

El número visible en Android procede de `pubspec.yaml` (`versionName+versionCode`). La etiqueta de compilación y el APK deben usar el mismo número.

## 0.4.0+4 — Desarrollo

- Nombre de instalación Android: **Morty's LED**.
- Tarjetas deslizables para varios controladores en Inicio.
- Nombres editables, selección y gestión de dispositivos.
- Correcciones de respuestas de conexión obsoletas.
- Auditoría técnica y plan de firmware v0.2.

## 0.3 — Iteraciones de desarrollo anteriores (sin versión de paquete independiente)

- Galería de escenas, controles, temporizador y mejoras visuales.
- Gestión de dispositivos múltiples y documentación MQTT.
- Compilaciones de CI anteriores usaron `version: 0.2.0+2` pese a cambios de interfaz.

## 0.2.0+2 — Primera serie APK

- Cliente HTTP local, escaneo BLE experimental y Flutter Android.
- Primeros APK generados por GitHub Actions.

## Convención a partir de ahora

- **MAJOR.MINOR.PATCH+BUILD**: ejemplo `0.4.0+4`.
- Incrementar BUILD en cada entrega instalable; incrementar PATCH para correcciones, MINOR para funciones.
- No crear una etiqueta Git ni publicar una release hasta que CI termine correctamente.
- El firmware usa su propio versionado (por ejemplo `0.2.0`) y anuncia `api_version`.
