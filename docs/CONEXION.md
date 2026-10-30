# Conexión Wi-Fi y descubrimiento

Aurora usa Wi-Fi. El proyecto actual no implementa aprovisionamiento Bluetooth.

La primera configuración utiliza el AP `LEDWeb-…`. En tu red habitual puedes buscar la ESP32 mediante mDNS: servicio `_http._tcp.local` y host `ledweb-….local`. LEDWeb 1.3 anuncia TXT `app=aurora` y su versión. La app filtra hosts LEDWeb y muestra sus direcciones IPv4 para completar usuario/contraseña.

Android adquiere un bloqueo multicast durante la búsqueda y lo libera al terminar. Se declaran permisos de Internet, estado de red/Wi-Fi y cambio de estado multicast; no se usa Bluetooth, cámara, micrófono ni ubicación.

Routers con aislamiento de clientes, redes de invitados, VPN o bloqueo multicast pueden impedir descubrir el dispositivo. Añadir la IP manualmente sigue disponible. La búsqueda no sustituye la autenticación ni garantiza compatibilidad física.

[Instalación](INSTALACION.md) · [Índice](README.md).
