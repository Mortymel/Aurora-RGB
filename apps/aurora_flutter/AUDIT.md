# Auditoría — Aurora Android 1.0.0

29 de octubre de 2026. Implementación Flutter nueva; no reutiliza la UI Android anterior ni carga HTML en una WebView.

## Controles implementados

- Alta de controladores solo después de consultar configuración y estado compatibles con LEDWeb. Credenciales se guardan con `flutter_secure_storage`, no en texto plano en preferencias ni en archivos del proyecto.
- Sin registros de contraseñas. Copias de seguridad y transferencia de datos Android excluidas para no transportar material cifrado a otra clave de dispositivo.
- HTTP Basic hacia la dirección elegida; redirecciones deshabilitadas para no reenviar credenciales a otro servidor.
- Timeout de 8 segundos, cierre de conexión al expirar, respuesta limitada a 64 KiB. No se reenvían automáticamente órdenes de encendido/configuración.
- Estado confirmado por ESP32; error visible al fallar. Sondeo periódico para reconectar y captar cambios hechos desde Home Assistant.
- Cada respuesta de sondeo se comprueba contra la generación del dispositivo seleccionado y la revisión de comandos. Las escrituras bloquean cambios de controlador hasta completar la operación.
- Lectura de configuración reciente antes de aplicar cambios. Formularios validan puerto, color, píxeles y días. La placa decide qué GPIO admite.
- Cancelación del sondeo cuando la app pasa a segundo plano. Horarios y temporizadores reales se ejecutan en la ESP32.
- La esfera aplica el mismo sombreado a los tres canales. Los efectos se dibujan por Flutter y respetan movimiento reducido.
- Permisos Android: Internet y estado de red. No se solicita cámara, micrófono, ubicación ni Bluetooth.

## Pruebas

`flutter analyze` y `flutter test` son requisitos del workflow antes de generar el APK. Los tests cubren validación de dirección/protocolo, servidor HTTP real local con autenticación y JSON, rechazo 401/redirecciones, timeout sin repetición, persistencia con almacén de prueba, cambios de controlador con respuesta retrasada, recuperación de conexión, demo y navegación nativa.

La prueba de widgets comprueba las cuatro secciones, visibilidad de la tira, color y formulario MQTT, ausencia de excepciones en 390/320 píxeles y genera `build/screenshots/aurora-native.png`. Esa captura corresponde a widgets Flutter, no a la demo web.

## Límites pendientes de validación física

- No se ha probado en el teléfono del usuario ni con su ESP32/XGB1338. El análisis estático y los tests no demuestran compatibilidad eléctrica o funcionamiento en todos los fabricantes Android.
- HTTP y MQTT 1883 no cifran el tráfico de la LAN. Mantener el controlador en una red de confianza y cambiar claves iniciales en el firmware. No exponerlo a Internet.
- Falta probar MQTT Discovery y control desde Home Assistant real.
- No hay descubrimiento automático ni aprovisionamiento BLE; se añade IP/.local y la primera configuración usa el AP de la ESP32. Algunos routers no resuelven `.local`; usar la IP en ese caso.
- La app necesita LEDWeb 1.2; no es compatible con la API del firmware antiguo 0.8.
- Las reglas semanales usan UTC fijo sin cambio estacional automático. La cuenta atrás se pierde al reiniciar la ESP32. En la demo se evalúan al consultar el estado con la app activa.
- Dos clientes externos pueden sobrescribir su configuración mutuamente; no existe versionado transaccional entre teléfonos y otros clientes.
- El APK de prueba usa la firma generada por el entorno Flutter. Una firma estable de distribución y Google Play requieren preparación adicional; no se incluyen claves privadas en Git.

La compilación de Android y su artefacto deben comprobarse en el workflow Aurora Flutter Android. No interpretar la mera existencia del workflow como una compilación exitosa.
