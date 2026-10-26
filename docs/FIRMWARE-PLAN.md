# Siguiente paso: firmware ESP32 v0.2

## Objetivo

Mantener un firmware reproducible para ESP32-WROOM-32 con tiras RGB direccionables compatibles. La cantidad se configura por controlador en Android (1–1024 píxeles en el binario actual), sin marca ni longitud obligatorias.

## Paso 1 — Identificar hardware y protocolo

Confirmar chip/controlador, protocolo, orden de colores, GPIO, tensión, nivel lógico y corriente. Validar con patrón rojo/verde/azul/blanco a brillo reducido. Contar píxeles/grupos direccionables: un grupo puede contener varios LED físicos. El binario actual usa WS2812B/GRB; otros protocolos requieren un controlador distinto.

## Paso 2 — API estable

Mantener por compatibilidad `GET /api/state` y `POST /api/control`. Agregar:

- `GET /api/info`: `device_id`, `name`, `firmware_version`, `api_version`, `pixels`, `capabilities`.
- `GET /api/effects`: lista real de identificadores, nombres y parámetros.
- `PUT /api/device`: renombrar el dispositivo en firmware, si hay autenticación.
- `GET /api/health`: tiempo activo, WiFi RSSI y memoria libre (sin secretos).

Las funciones de la app deben activarse a partir de `capabilities`, no de supuestos.

## Paso 3 — Efectos de verdad

Propuesta inicial para implementar y medir:

1. Color fijo.
2. Arcoíris.
3. Respiración.
4. Desvanecimiento.
5. Barrido.
6. Cometa.
7. Chispas.
8. Fuego.
9. Meteoros.
10. Olas.
11. Gradiente.
12. Pulso.

**Estos doce efectos son objetivos, no funciones disponibles hoy.** Mantener IDs versionados y exponerlos desde `/api/effects`; no asignar IDs arbitrarios en Flutter.

## Paso 4 — MQTT / Home Assistant

Implementar broker configurable por un canal autenticado, `availability` con LWT, mensajes retained de estado y MQTT Discovery. Contrato de referencia: [MQTT-HOME-ASSISTANT.md](MQTT-HOME-ASSISTANT.md).

## Paso 5 — Estabilidad y pruebas

- Estado consistente tras reinicios.
- Watchdog y recuperación WiFi.
- Actualizaciones de efectos sin bloquear HTTP.
- Límites de brillo y consumo.
- Pruebas de 24 horas de funcionamiento.
- Versiones semánticas de firmware separadas de la app.

## Paso 6 — BLE y OTA

Implementar después de la API WiFi y MQTT. BLE requiere aprovisionamiento autenticado. OTA requiere integridad, rollback y protección de claves.

## Estructura futura recomendada

```text
firmware/
  platformio.ini
  include/
  src/
  test/
docs/
  API.md
  HARDWARE.md
```

El firmware y las instrucciones de compilación y flasheo están en `firmware/`. La validación física sigue pendiente.
