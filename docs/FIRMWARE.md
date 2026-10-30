# Firmware LEDWeb 1.3: estado y compilación

El firmware actual está en `ledweb/firmware/LEDWeb`; el directorio raíz firmware corresponde al código anterior.

Herramientas verificadas: Arduino-ESP32 3.3.12, Adafruit NeoPixel 1.15.5, ArduinoJson 7.4.3 y PubSubClient 2.8. El workflow aurora-flasher.yml instala estas versiones y compila:

```sh
node ledweb/scripts/build-aurora.cjs
arduino-cli compile --fqbn esp32:esp32:esp32c6 --output-dir build/c6 ledweb/firmware/LEDWeb
arduino-cli compile --fqbn esp32:esp32:esp32 --output-dir build/wroom ledweb/firmware/LEDWeb
```

Antes deben estar instalados core y bibliotecas indicados. Mantén config.h, web_ui.h y el header generado aurora_ui.h junto al sketch. Cambia WEB_PASSWORD y AP_PASSWORD en config.h antes de compilar para uso permanente; AP necesita al menos ocho caracteres. No subas claves privadas ni config.local.h.

Los binarios fusionados son de 4 MB, para escritura desde 0x0 y familias distintas. No son imágenes OTA intercambiables. verify-flasher.py comprueba cabeceras de bootloader/aplicación, familia, particiones, tamaño y genera hashes.

Por defecto arranca apagado. restore habilita recuperar el estado persistido; las preferencias de luz se escriben tras 1,5 s sin cambios, por lo que un corte inmediato puede conservar un estado anterior. transition_ms controla encendido/apagado, no una interpolación general entre escenas. max_brightness limita la salida incluso con órdenes MQTT. reverse invierte la dirección de píxeles.

Compilado para C6 y ESP32 clásico. La compilación no sustituye una prueba de cableado, señal o consumo en placa real.
