# Arquitectura de ESP32 RGB Studio

## Visión general

```text
┌────────────────────────────┐      WiFi / HTTP       ┌─────────────────────┐
│ Aplicación Flutter Android │ ─────────────────────► │ ESP32-WROOM-32      │
│ • Estado y controles       │ ◄───────────────────── │ • Firmware RGB v0.1 │
│ • Descubrimiento BLE       │                        │ • GPIO de datos LED │
└────────────────────────────┘                        └─────────┬───────────┘
                                                                │ Datos 5 V
                                                        ┌───────▼──────────┐
                                                        │ RGB direccionable│
                                                        │ 1–1024 píxeles   │
                                                        └──────────────────┘
```

**Estado real:** Android y firmware ESP32 se incluyen en este repositorio. La cantidad se configura por controlador desde Android y se guarda en la ESP32. El dibujo no certifica pruebas físicas ni compatibilidad con todos los protocolos LED.

## Componentes de software

- `lib/main.dart`: interfaz, conexión al dispositivo, controles y estado.
- `lib/device_api.dart`: cliente HTTP, estructura de estado y comandos.
- `lib/ble_provisioning.dart`: búsqueda experimental de periféricos cuyo nombre comienza por `RGBStudio`; no escribe credenciales.
- `scripts/configure_android.py`: permisos y HTTP local en Android.
- `.github/workflows/android-apk.yml`: análisis y construcción del APK.

## Flujo de control actual

1. El usuario introduce nombre, IP y cantidad de píxeles de cada ESP32 en la misma red.
2. Flutter consulta `GET /api/state`.
3. Aplica la cantidad guardada cuando difiere, comprueba la respuesta y representa el estado recibido.
4. El usuario modifica brillo, color, efecto, velocidad o encendido.
5. Flutter envía `POST /api/control` con campos de formulario.
6. Se vuelve a consultar el estado aproximadamente cada 3 segundos.

## Límites actuales

- La comunicación HTTP local no cifra ni autentica las peticiones. **No exponer la API a Internet**.
- Los nombres, números de efectos y campos HTTP dependen del firmware real: comprobar compatibilidad antes de usar.
- No hay reconexión avanzada, descubrimiento mDNS, emparejamiento seguro ni OTA desde la app.
- BLE es descubrimiento experimental, no aprovisionamiento WiFi.
- No hay implementación completa de audio, MQTT, segmentos ni WebSocket en este repositorio.

## Diseño futuro propuesto

Separar `presentation/`, `domain/`, `data/` y `services/`; agregar estado reactivo, modelo de capacidades del dispositivo, autenticación local opcional y pruebas de contrato API. El firmware deberá publicar su versión y capacidades para que la aplicación oculte funciones no soportadas.
