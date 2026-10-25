# Firmware Morty's LED 0.1.0-dev

## Estado

Código inicial para ESP32-WROOM-32 clásico con 12 efectos, control de brillo y velocidad, HTTP compatible con la app, conexión WiFi por AP inicial y MQTT opcional. **No se ha probado físicamente con la tira FCOB RGB IC ni se ha validado todavía la compilación.**

## Hardware

El ejemplo supone una tira compatible con **WS2812B / GRB**, 320 píxeles direccionables, datos en **GPIO 5** y fuente de 5 V independiente. **La tira real podría utilizar otro protocolo o grupos de píxeles**. Verificar antes de conectar. Cambiar `LED_PIN`, `LED_COUNT` y el tipo de LED en `src/main.cpp` si corresponde.

## Compilar

```bash
python -m pip install platformio
pio run -d firmware
```

En GitHub Actions, el workflow **ESP32 Firmware** compila y empaqueta un instalador web. El artefacto contiene `firmware.bin`, `index.html` y `manifest.json`. La página solo funciona como flasheador si se sirve por **HTTPS** junto con el binario. Descargar el ZIP y abrir `index.html` con `file://` no sirve.

## Primer arranque

Si no hay WiFi guardado o no conecta, la ESP32 crea un punto de acceso `MortysLED-<ID>` sin contraseña. Conéctate temporalmente y abre `http://192.168.4.1/setup` para indicar SSID y clave. El firmware guarda esos datos en NVS y reinicia. **Este mecanismo es solo para desarrollo**: no hay autenticación, cifrado de credenciales en tránsito ni bloqueo de intentos.

## API

- `GET /api/state`
- `POST /api/control` con campos `power`, `brightness` (0–255), `speed` (1–255), `effect` (0–11), `color` (0xRRGGBB)
- `GET /api/info`
- `GET /api/effects`
- `GET /api/health`

## Efectos

0 Fijo · 1 Arcoíris · 2 Respirar · 3 Cometa · 4 Chispas · 5 Fuego · 6 Olas · 7 Barrido · 8 Pulso · 9 Confeti · 10 Meteoros · 11 Gradiente.

## MQTT / Home Assistant

El cliente MQTT y Discovery están implementados en código, pero quedan **desactivados** si no hay `mqtt_host` en NVS. Aún falta un canal seguro para configurar el broker y credenciales. No hay formulario MQTT funcional en la app. Consulta `docs/MQTT-HOME-ASSISTANT.md`.

## Seguridad

El firmware no tiene autenticación HTTP, OTA segura ni aprovisionamiento protegido. No abrir puertos al exterior. No utilizar el AP abierto de instalación en entornos no confiables.

## Antes de conectar LEDs

Verificar fuente 5 V, tierra común, adaptador lógico 3,3→5 V, fusible y corriente máxima. El límite de software es 3000 mA, pero no reemplaza las protecciones físicas.
