# Solución de problemas de Aurora

| Problema | Comprobación |
|---|---|
| No aparece puerto USB | Cable de datos, otro puerto, monitor serie cerrado y controlador del fabricante. BOOT/RESET si la placa lo necesita. |
| Navegador no instala | Chrome/Edge de escritorio con Web Serial y HTTPS; Android no es el entorno de instalación USB documentado. |
| Chip no compatible | Solo se publican binarios C6 y ESP32 clásico; no elijas otro a mano. |
| No aparece LEDWeb-… | Reinicia, espera recuperación y consulta monitor serie. Si conecta a un Wi-Fi guardado, revisa el router. |
| Usuario/contraseña incorrectos | Claves de config.h; inicial admin/tiraesp32, no las de Wi-Fi ni Home Assistant. |
| No encuentra por búsqueda | Misma LAN, sin aislamiento de invitados/VPN; algunos routers bloquean multicast. Usa la IP. |
| Deja de responder al guardar Wi-Fi | Cambió de red/IP. Reconecta el teléfono, consulta el router y edita la IP; recuperación por AP. |
| Colores intercambiados | Prueba rojo/verde/azul y cambia RGB/GRB. Algunos efectos tienen paletas propias. |
| Brillo menor que el solicitado | Revisa max_brightness, transición en curso y alimentación; el brillo reportado es el valor solicitado. |
| Tira inestable o sin datos | DIN/flechas, GND común, GPIO real libre, cable corto y señal compatible. No elevar un GPIO a 5 V. |
| Horario no ejecutado | Reloj válido, UTC fijo correcto, días seleccionados y regla habilitada. No hay ajuste automático de verano. |
| MQTT desconectado | IP/puerto del broker, credenciales y firewall. No usar 8123 ni asumir que core-mosquitto resuelve en la ESP32. |
| Android rechaza actualizar APK | Posible firma distinta entre compilaciones de prueba. Reinstalar borra datos locales; anota direcciones y conserva claves antes de hacerlo. |
| Firma/archivo de firmware dudoso | Usa el instalador actual y compara SHA-256 con build-info.json; las imágenes fusionadas se escriben desde 0x0. |

Usa Ajustes → Diagnóstico para consultar versión, IP, señal, MQTT y reloj. Al reportar un fallo incluye versiones y modelo exacto, sin claves ni logs con secretos.
