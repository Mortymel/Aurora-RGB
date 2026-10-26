# Firmware ESP32-WROOM-32 — 0.8.0

Objetivo: ESP32 clásico con flash de 4 MB; FastLED, WS2812B compatible, orden GRB, GPIO5, 1–1024 píxeles. Revisa [hardware](../docs/HARDWARE.md) antes de conectar la tira. El límite de corriente por software no protege contra errores de cableado o fuente.

## Compilación

```sh
pio run -d firmware
```

La plataforma `espressif32@6.9.0` utiliza Arduino ESP32 2.0.17. FastLED 3.7.8, ArduinoJson 7.3.0 y PubSubClient 2.8 están fijados. BLE utiliza la biblioteca incluida por Arduino. Se emplea `huge_app.csv` (aplicación de 3 MB), sin OTA. No cambies la tabla de particiones sin volver a instalar la imagen completa.

El workflow compila, comprueba el protocolo con C++/ASan/UBSan, fusiona bootloader en `0x1000`, particiones en `0x8000` y aplicación en `0x10000`. El `firmware.bin` del instalador web es una imagen fusionada que se escribe desde **offset 0**. No confundas esa imagen con la aplicación individual de PlatformIO.

## Alta y recuperación

Sin credenciales guardadas anuncia BLE `MortysLED-…` durante 10 minutos. Android envía SSID, contraseña, nombre y píxeles por características cifradas. Se comprueba WiFi hasta 25 segundos antes de guardar una configuración nueva en NVS. BOOT durante 3 segundos después del arranque reabre la configuración, sin borrar la anterior. Tras éxito se permite leer la confirmación durante un minuto.

Una placa ya configurada reintenta su WiFi guardado; una caída del router no abre de nuevo la configuración. No se crea un AP abierto. El protocolo está documentado en [BLUETOOTH.md](../docs/BLUETOOTH.md).

HTTP ofrece `/api/state`, `/api/control`, `/api/info`, `/api/effects` y `/api/health`. MQTT opcional conserva el código de conexión a un broker configurado en NVS; la app no ofrece todavía ese alta. No hay música, segmentos ni programación persistente.

## Límites de seguridad y validación

BLE usa Secure Connections Just Works, sin PIN ni prueba de posesión. La configuración NVS no tiene cifrado en reposo. HTTP local carece de autenticación/TLS; no debe publicarse en Internet. La compilación no verifica físicamente alimentación, señal de datos, memoria dinámica de BLE, emparejamiento Android ni persistencia ante un corte real de corriente. Ver [auditoría](../docs/AUDITORIA.md).
