# Morty's LED — versión 0.8.0

Control local de tiras direccionables con ESP32-WROOM-32 y Android. La instalación inicial se realiza por Bluetooth LE; el control diario utiliza HTTP en la red WiFi local.

## Puesta en marcha

1. Instala el firmware **0.8.0** en la ESP32 desde [el instalador web](https://mortymel.github.io/ESP32-RGB-Studio-/). Desconecta la tira durante el flasheo.
2. Instala el APK **0.8.0+9** generado por el workflow Android APK. El firmware anterior no implementa este protocolo: actualizar solamente la app no basta.
3. Enciende la ESP32. Sin credenciales guardadas anuncia `MortysLED-…` por Bluetooth durante 10 minutos.
4. En la app: **Añadir tira → Buscar por Bluetooth → selecciona la ESP32**.
5. Introduce **WiFi de 2,4 GHz, contraseña, nombre y cantidad de LED/píxeles**. Cuenta grupos direccionables si tu tira agrupa varios LED.
6. Pulsa **Configurar y añadir tira** y acepta el emparejamiento de Android. La ESP32 comprueba el WiFi y guarda la configuración solo al conectar. La app recibe su IP y añade el controlador.
7. Conecta el teléfono a esa misma red para controlar la tira.

Para cambiar de red, mantén **BOOT pulsado durante 3 segundos después del arranque**. Esto reabre Bluetooth durante 10 minutos sin borrar la configuración anterior. Una contraseña errónea no la sustituye. No mantengas BOOT al encender si no quieres entrar en el cargador de arranque.

## Funciones y límites reales

| Función | Estado |
|---|---|
| Alta por BLE: WiFi, nombre y píxeles | Implementada en app y firmware; requiere validación en placa y teléfono reales |
| Emparejamiento y características BLE cifradas | Implementados; sin PIN ni protección contra intermediario activo |
| Control WiFi: encendido, brillo, color, 12 efectos y velocidad | Implementado |
| Cantidad individual de píxeles, 1–1024 | Guardada en ESP32 y teléfono |
| Escenas personalizadas | Guardadas en el teléfono |
| Apagado temporizado | Local en el teléfono; requiere app activa, ligado al controlador original |
| Controladores ya configurados | Búsqueda mDNS y entrada manual como alternativa |
| MQTT/Home Assistant | Código de firmware existente; configuración de broker desde la app pendiente |
| Música, segmentos, horarios en la ESP32 y OTA | Pendientes |

Hardware objetivo: **ESP32-WROOM-32 con flash de 4 MB**, datos en GPIO5, WS2812B compatible, orden GRB. El límite de corriente por software de 3 A no sustituye una fuente, cableado y protecciones adecuados. La partición de aplicación de 3 MB permite BLE; esta versión no utiliza OTA.

## Descargas y verificación

En [GitHub Actions](https://github.com/Mortymel/ESP32-RGB-Studio-/actions):

- **Android APK** genera `ESP32-RGB-Studio-Android-APK`, con APK, SHA-256, metadatos y dependencias resueltas.
- **ESP32 Firmware** genera `Mortys-LED-ESP32-Firmware-Web-Flasher`, con imagen fusionada, manifiesto e instalador. El mismo contenido se publica en Pages.

Las compilaciones comprueban pruebas Dart, estructura y firma del APK, versión, pruebas C++ con sanitizadores y correspondencia de offsets de la imagen ESP32. La firma actual es la de desarrollo generada por Flutter: todavía no existe una clave de publicación estable. Una actualización sobre otro APK puede exigir desinstalar la app anterior, lo que borra sus datos locales.

## Seguridad y validación

No se crea el antiguo punto de acceso WiFi abierto. Las credenciales viajan en una conexión BLE cifrada y no se guardan en las preferencias del teléfono. Se conservan en NVS de la ESP32, que no está cifrada en esta configuración. El emparejamiento sin PIN no acredita por sí solo posesión física de la placa. Configura cerca de la ESP32 en un entorno de confianza.

El HTTP local y el MQTT opcional no tienen TLS ni autenticación propia del controlador. Utiliza una red privada, sin exponer puertos a Internet. Esta versión no se declara preparada para producción ni validada físicamente.

Documentación: [Bluetooth y protocolo](docs/BLUETOOTH.md), [instalación](docs/INSTALACION.md), [auditoría](docs/AUDITORIA.md), [arquitectura](docs/ARQUITECTURA.md), [API](docs/API.md), [hardware](docs/HARDWARE.md), [firmware](firmware/README.md).
