# Home Assistant y MQTT — contrato de integración

**Estado:** diseño para la próxima versión del firmware. La aplicación muestra esta sección como pendiente; todavía no envía credenciales ni configura un broker.

## Requisitos

- Broker MQTT en la red local (por ejemplo, Mosquitto integrado en Home Assistant).
- Firmware ESP32 con cliente MQTT, reconexión, autenticación y publicación de estado.
- Identificador único por controlador. Los ejemplos usan `mostys-led/esp32-01`.

## Temas propuestos

| Tema | Dirección | Contenido |
| --- | --- | --- |
| `mostys-led/esp32-01/state` | ESP32 → broker | JSON de estado, retain=true |
| `mostys-led/esp32-01/set` | Broker → ESP32 | JSON de comandos |
| `mostys-led/esp32-01/availability` | ESP32 → broker | `online` / `offline` (LWT) |

Ejemplo de estado:

```json
{"state":"ON","brightness":180,"color":{"r":255,"g":80,"b":30},"effect":"Solid"}
```

Ejemplo de comando:

```json
{"state":"ON","brightness":150,"color":{"r":20,"g":150,"b":255}}
```

## Home Assistant MQTT Discovery

Publicar un mensaje retained en `homeassistant/light/mostys_led_esp32_01/config`:

```json
{
  "name": "mosty's led",
  "unique_id": "mostys_led_esp32_01",
  "schema": "json",
  "command_topic": "mostys-led/esp32-01/set",
  "state_topic": "mostys-led/esp32-01/state",
  "availability_topic": "mostys-led/esp32-01/availability",
  "brightness": true,
  "rgb": true,
  "effect": true,
  "effect_list": ["Solid", "Rainbow", "Fire", "Sparkle", "Breathe", "Waves"],
  "device": {
    "identifiers": ["mostys_led_esp32_01"],
    "name": "mosty's led",
    "manufacturer": "DIY",
    "model": "ESP32-WROOM-32"
  }
}
```

El firmware debe implementar de verdad los efectos anunciados. En Home Assistant, las claves de MQTT Discovery dependen de la versión; validar contra la documentación oficial al integrar: https://www.home-assistant.io/integrations/light.mqtt/ y https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery

## Seguridad

Usar usuario MQTT específico para el dispositivo con permisos mínimos. Evitar brokers expuestos a Internet. En redes no confiables, exigir TLS si el firmware y la memoria lo permiten. No guardar contraseñas en repositorios ni en logs.

## Criterios de aceptación

1. La ESP32 aparece automáticamente como entidad de luz en Home Assistant.
2. El estado se sincroniza en ambas direcciones.
3. El dispositivo pasa a `unavailable` al desconectarse (LWT).
4. Tras reiniciar, se recupera el estado y se reanuncia el discovery.
5. Se prueban los cambios de brillo, RGB, encendido y efectos.
