# Solución de problemas — 0.8.0

| Síntoma | Comprobación |
|---|---|
| No aparece la ESP32 por Bluetooth | Firmware 0.8.0 instalado, placa encendida, teléfono cerca; BOOT 3 segundos después del arranque para reabrir los 10 minutos |
| No aparece el permiso | Android 12+: Dispositivos cercanos; Android 11 o anterior: ubicación concedida y activada |
| Emparejamiento falla tras reflashear | Elimina el vínculo Bluetooth anterior en Android y vuelve a buscar |
| WiFi no conecta | SSID y contraseña exactos, red de 2,4 GHz; no se admiten EAP ni PSK hexadecimal de 64 caracteres |
| Configuración cancelada, pero placa conectada | Puede haber completado el comando ya enviado; utiliza Ya está conectada al WiFi |
| La app añadió la tira pero no responde | Teléfono en la misma red, sin aislamiento de clientes ni VPN que bloquee la LAN; comprueba IP actual |
| Cambió el router o la contraseña | BOOT 3 segundos después del arranque y repite el alta; una contraseña fallida no borra la anterior |
| Cantidad incorrecta de LED | Cuenta píxeles direccionables/grupos, no necesariamente encapsulados; rango 1–1024 |
| Android rechaza instalar una actualización | La firma de desarrollo puede diferir de la anterior. Desinstalar borra los datos locales de la app; no los de la ESP32 |
| Temporizador no actúa tras cerrar la app | Es un temporizador del teléfono; requiere mantener el proceso activo |

La ESP32 configurada no abre automáticamente Bluetooth por una caída del router; utiliza BOOT si necesitas cambiar la red. Ya no existe el antiguo punto de acceso abierto ni la ruta de configuración `/setup`.

Las ejecuciones correctas deben tener pruebas, compilación y verificación de artefactos aprobadas. Un archivo de un run anterior no confirma que el firmware/app nuevos se hayan generado. Consulta el SHA de cada ejecución.
