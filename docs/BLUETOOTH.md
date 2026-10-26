# Configuración por Bluetooth — 0.8.0

## Flujo

Una placa sin WiFi guardado abre BLE durante 10 minutos. La app escanea por el UUID de servicio, no solamente por el nombre. Se selecciona `MortysLED-<id de 48 bits>`, se completa el formulario y Android empareja la placa antes de escribir los datos. No se envía la contraseña al servidor HTTP ni a servicios externos.

La ESP32 intenta conectarse durante 25 segundos sin bloquear el bucle de control. Conserva las credenciales anteriores mientras prueba las nuevas. Tras éxito guarda credenciales, nombre y cantidad en una única entrada NVS `setup`, actualiza FastLED y devuelve IP e identidad. El teléfono solo añade un controlador al recibir la confirmación correspondiente a su solicitud. El escaneo no modifica la placa.

Si falla, informa del error y recupera el WiFi anterior. Si se cancela o cierra la app después de enviar el comando, la placa puede finalizar su conexión; la cancelación detiene la espera del teléfono y nunca guarda un resultado tardío. En ese caso se puede recuperar con **Ya está conectada al WiFi**. Si la ventana expiró, BOOT durante 3 segundos después del arranque la reabre. La placa configurada no abre BLE automáticamente porque su router esté temporalmente caído.

## Contrato GATT v1

| Elemento | UUID | Propiedad |
|---|---|---|
| Servicio | `d973f2e0-b19e-11ee-a506-0242ac120002` | Anunciado por BLE |
| Configuración | `d973f2e1-b19e-11ee-a506-0242ac120002` | Escritura con respuesta, requiere cifrado |
| Estado | `d973f2e2-b19e-11ee-a506-0242ac120002` | Lectura, requiere cifrado |

Antes de transferir, una escritura aislada `!` descarta un mensaje anterior incompleto. Se envían bytes UTF-8 en bloques de hasta 20 bytes y un salto de línea final confirma el mensaje. El máximo es 512 bytes sin el salto final. Los bloques se ensamblan antes de interpretar UTF-8 y JSON. Los mensajes excesivos o con NUL se descartan completos hasta el delimitador.

Ejemplo de estructura (sin contraseña real):

```json
{"version":1,"request_id":"request-1","ssid":"Mi WiFi","password":"ejemplo123","name":"Salón","pixels":60}
```

Límites por bytes UTF-8: SSID 1–32; contraseña 8–63 o vacía para red abierta; nombre 1–48; píxeles entero 1–1024. La app recorta únicamente espacios de los extremos del nombre, nunca del SSID ni la contraseña. El firmware vuelve a validar todo antes de cambiar el WiFi. No se admiten redes empresariales EAP ni la clave PSK hexadecimal de 64 caracteres en este protocolo.

El estado usa `version`, `state`, `request_id` y `device_id`; estados `ready`, `connecting`, `connected` o `error`. La confirmación incorpora `ip`, `name` y `pixels`. Los errores son `invalid_config`, `wifi_failed` o `storage_failed`. Nunca incluye SSID ni contraseña. La app consulta el estado por lectura para no truncar una notificación al tamaño del MTU.

Después de éxito se deja un minuto para leer la confirmación; luego cesa la publicidad BLE y se desconecta el cliente. No se ofrecen actualizaciones OTA. El botón BOOT reabre la configuración existente.

## Android

Android 12 o posterior solicita Dispositivos cercanos (SCAN/CONNECT). Android 11 o anterior solicita ubicación, que también debe estar activada para escanear. El manifiesto limita ubicación y los permisos Bluetooth antiguos a SDK 30; SCAN declara `neverForLocation`. Si se borraron los vínculos de la ESP32 al flashear y el teléfono mantiene uno antiguo, elimina el emparejamiento guardado y vuelve a intentar.

## Seguridad y límites

Se exige cifrado BLE con emparejamiento Secure Connections Just Works y vínculo persistente. Sin pantalla o secreto individual, no se garantiza autenticación frente a intermediario activo. La ventana inicial y la reapertura física reducen exposición, pero no sustituyen una prueba de posesión. Las credenciales NVS no tienen cifrado en reposo; acceso físico a flash puede revelarlas. La implementación actual es para entorno local de confianza. Android/ESP32 reales deben verificar negociación, fragmentación, reconexión y convivencia BLE/WiFi/FastLED.

Referencias de implementación: [BLE de Espressif 2.0.17](https://github.com/espressif/arduino-esp32/tree/2.0.17/libraries/BLE), [FlutterBluePlus 1.36.8](https://pub.dev/documentation/flutter_blue_plus/1.36.8/).
