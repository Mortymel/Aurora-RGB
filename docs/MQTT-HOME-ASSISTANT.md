# Home Assistant mediante MQTT

La ESP32 se conecta al broker MQTT. Aurora guarda los parámetros en la placa; la app no necesita permanecer abierta ni conectarse directamente al broker.

1. En Home Assistant OS instala e inicia Mosquitto broker desde Ajustes → Apps/Complementos.
2. Crea un usuario dedicado y contraseña en Ajustes → Personas → Usuarios; activa modo avanzado si hace falta.
3. Obtén la IP LAN del equipo que aloja el broker desde el router o la configuración de red.
4. Configura la integración MQTT y habilita descubrimiento en Home Assistant.
5. En Aurora → Ajustes → Home Assistant / MQTT introduce IP/host del broker, puerto (habitualmente 1883), usuario y contraseña. Si el broker admite acceso anónimo, elige explícitamente sin autenticación.

No confundas el puerto 1883 con el de la interfaz web 8123. No uses la contraseña Wi-Fi como clave MQTT salvo que realmente sea la configurada en el broker. Un nombre interno como core-mosquitto puede no resolver desde la ESP32.

Las claves guardadas no se devuelven por HTTP. Contraseña configurada → Cambiar permite sustituirla; sin editar se conserva. Servidor vacío desactiva MQTT. La demo solo simula estos datos.

## Protocolo

Con `deviceId=ledweb_<sufijo MAC>`, la base es `ledweb/<deviceId>`: comandos en `/set`, estado en `/state` y disponibilidad en `/availability`. Discovery se publica retenido en `homeassistant/light/<deviceId>/config`, nombre Tira LED. El firmware vuelve a anunciarse al recibir `online` en `homeassistant/status`.

Ejemplo de payload de comando:

```json
{"state":"ON","brightness":100,"effect":"Color fijo","color":{"r":255,"g":120,"b":35}}
```

La conexión local del firmware no usa TLS. No exponer el broker/controlador a Internet. Falta validar descubrimiento y disponibilidad con el broker real del usuario.
