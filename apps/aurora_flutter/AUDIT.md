# Auditoría de Aurora 1.1 / LEDWeb 1.3

Referencia: 30 de octubre de 2026. Revisión de código, compilación y pruebas automatizadas; no certificación de seguridad ni validación física.

## Evidencia

- 16 pruebas Flutter aprobadas: API/autenticación local, timeout, redirecciones, validación, persistencia de prueba, aislamiento de controladores, recuperación, color y MQTT en widgets, deshacer, último gesto agrupado y horarios contradictorios.
- flutter analyze sin incidencias; APK Android compilado, firma de prueba comprobada y SHA-256 contrastado tras descargar.
- LEDWeb 1.3 compilado para ESP32-C6 y ESP32 clásico. Imágenes verificadas por cabeceras, particiones, familia, 4 MB y hashes.
- Flasher público comprobado en Chrome: carga de ESP Web Tools, manifiesto 1.3, dos familias y ausencia de desbordamiento a 390/1200 px. Hashes de ambos binarios públicos contrastados.

Evidencia reproducible: [Actions del repositorio](https://github.com/Mortymel/ESP32-RGB-Studio-/actions). Las pruebas Flutter usan servidores locales/simuladores; no demuestran control de la tira física. Los artefactos expiran según la retención del workflow.

## Controles

Credenciales protegidas en Android y backup/transferencia de datos excluidos. HTTP sin redirecciones y con respuesta limitada. Escrituras fallidas no reenviadas automáticamente. Las respuestas antiguas no se aplican a otro controlador. Vista en vivo agrupa entradas y descarta pendientes al cerrar/cambiar de controlador. Contradicciones de horarios se rechazan en app y placa. Arranque apagado inicial; recuperación optativa y límite físico de brillo en la ESP32.

## Pendiente

Prueba en el teléfono/router/ESP32/XGB1338 real; descubrimiento multicast en la LAN del usuario; orden RGB/GRB, nivel lógico de datos, alimentación; MQTT Discovery y disponibilidad con un broker real; validación de transiciones y persistencia tras cortes.

HTTP Basic y MQTT 1883 no cifran tráfico. NVS no tiene cifrado adicional. Las claves iniciales son conocidas y se cambian al compilar. El APK carece de firma estable de distribución; reinstalar puede perder preferencias. No hay bloqueo/versionado entre clientes externos que editen simultáneamente la configuración. UTC es fijo, la cuenta atrás se pierde al reiniciar y no hay OTA.

[Seguridad](https://github.com/Mortymel/ESP32-RGB-Studio-/blob/main/SECURITY.md) · [Hardware](https://github.com/Mortymel/ESP32-RGB-Studio-/blob/main/docs/HARDWARE.md) · [Trabajo pendiente](https://github.com/Mortymel/ESP32-RGB-Studio-/blob/main/docs/ROADMAP.md).
