# API de LEDWeb 1.3

HTTP local, puerto 80 y autenticación Basic con WEB_USER/WEB_PASSWORD de config.h. Las escrituras requieren Content-Type application/json y un objeto JSON de hasta 8192 bytes. Los errores devuelven JSON con `error`; una autenticación fallida puede devolver 401 sin JSON. No hay CORS abierto ni API de nube.

| Ruta | Método | Uso |
|---|---|---|
| / | GET | Interfaz Aurora alojada en la ESP32 |
| /aurora | GET | Misma interfaz |
| /classic | GET | Interfaz web clásica de LEDWeb |
| /api/state | GET | Estado, efectos admitidos y diagnóstico |
| /api/light | POST | Cambiar luz |
| /api/config | GET | Configuración sin claves; GPIO admitidos y chip |
| /api/config | POST | Guardar configuración completa |
| /api/timer | POST | Cuenta atrás |
| /api/clock | POST | Sincronizar hora UTC |

## Luz

```json
{"state":"ON","brightness":100,"speed":45,"effect":"Atardecer","color":{"r":255,"g":120,"b":35}}
```

Estado ON/OFF; brillo 0–255; velocidad 1–100; RGB 0–255. Usa nombres exactos de la lista `effects` de /api/state (32 efectos); la API también admite índice válido. Campos omitidos conservan el valor. La respuesta de POST luz contiene el estado de luz, no todos los campos de GET state.

GET state incluye `id,count,ip,wifi,mqtt,ap,clock_valid,clock,timer_remaining,effects,version,rssi,uptime,free_heap,hostname`, además de luz. `clock` solo existe con hora válida, `uptime` y cuenta atrás están en segundos; RSSI en dBm y memoria libre en bytes. El brillo reportado es el solicitado; la salida física está limitada por max_brightness y puede estar en transición.

## Configuración

Lee primero GET config y envía el objeto completo modificado: `count` 1–1600; `gpio` de available_pins; `grb` booleano; `ssid,wifi_password,mqtt_host,mqtt_port,mqtt_user,mqtt_password,utc_offset,schedules`. Puerto 1–65535, UTC en minutos entre −720 y +840. SSID hasta 32, clave Wi-Fi hasta 63, host/usuario/clave MQTT hasta 128.

LEDWeb 1.3 añade `reverse` y `restore` booleanos; `max_brightness` 1–255; `transition_ms` 0–5000. Valores iniciales false, false, 255 y 400.

Cuatro schedules exactos: `{"enabled":true,"on":true,"time":"20:00","days":127}`. Days: máscara de 1–127, lunes bit 0 y domingo bit 6. Se rechazan reglas activas con acciones opuestas, misma hora y días solapados. No hay escena independiente por horario; el encendido usa el ambiente seleccionado.

GET nunca devuelve claves: indica wifi_password_set/mqtt_password_set. Clave vacía conserva la existente; para retirarla se usan clear_wifi_password/clear_mqtt_password. Estas opciones son de protocolo; la UI las presenta como red abierta o sin autenticación. Si se envían simultáneamente borrado y clave nueva no vacía, prevalece la nueva.

Guardar red/MQTT/zona puede devolver `{"ok":true,"reconnecting":true}`. No asumir que una segunda consulta inmediata responderá: la IP/red pueden cambiar. Se abre el AP de recuperación.

## Tiempo

Timer: `{"minutes":30,"on":false}`; de 0 a 10080, cero cancela. Se pierde al reiniciar. Reloj: `{"epoch":1793358000}`, segundos UTC entre 1700000000 y 4102444800. Los horarios necesitan reloj válido y usan desfase fijo, sin ajuste estacional automático.

MQTT utiliza el mismo formato de luz: [guía](MQTT-HOME-ASSISTANT.md). No hay endpoints OTA, grupos ni segmentos en esta versión.
