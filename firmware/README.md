# Firmware Morty's LED 0.3.0-dev

## Estado

Firmware para ESP32-WROOM-32 clásico con 12 efectos, cantidad de píxeles configurable, brillo y velocidad, HTTP compatible con la app, conexión WiFi por AP inicial y MQTT opcional. La compilación se comprueba en CI; las pruebas físicas con cada tira siguen siendo necesarias.

## Hardware

El binario admite tiras RGB compatibles con **WS2812B / GRB**, datos en **GPIO 5** y fuente de 5 V independiente. No exige marca ni longitud. En Android, al añadir o editar cada ESP32, indica **1–1024 píxeles direccionables**. La app envía `pixels` al conectar; el firmware lo guarda en NVS y lo usa en todos los efectos. El primer arranque sin configuración usa un único píxel. Las configuraciones anteriores se conservan.

Si la tira agrupa LED, introduce grupos direccionables, no diodos físicos. Otros órdenes de color, protocolos, RGBW o tiras analógicas requieren adaptar el controlador; modificar solo la cantidad no cambia la compatibilidad eléctrica. `LED_MAX_PIXELS` limita memoria y rango; `LED_PIN` y el tipo de LED se cambian al compilar si el hardware lo requiere.

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
- `POST /api/control` con campos `power`, `brightness` (0–255), `speed` (1–255), `effect` (0–11), `color` (0xRRGGBB), `pixels` (entero 1–1024; inválidos reciben HTTP 400)
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
