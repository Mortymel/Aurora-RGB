# Auditoría de Aurora 1.2 / LEDWeb 1.3

Referencia: 30 de octubre de 2026. Revisión de código, compilación y pruebas automatizadas; no certificación de seguridad ni validación física.

## Evidencia

- Pruebas Flutter de API, estado e interfaz; la navegación también comprueba la carga parcial del catálogo y la aplicación del último efecto. Cobertura: API/autenticación local, timeout, redirecciones, validación, persistencia de prueba, aislamiento de controladores, recuperación, color y MQTT en widgets, deshacer, último gesto agrupado y horarios contradictorios.
- flutter analyze sin incidencias; APK Android compilado, firma de prueba comprobada y SHA-256 contrastado tras descargar.
- LEDWeb 1.3 compilado para ESP32-C6 y ESP32 clásico. Imágenes verificadas por cabeceras, particiones, familia, 4 MB y hashes.
- Flasher público comprobado en Chrome: carga de ESP Web Tools, manifiesto 1.3, dos familias y ausencia de desbordamiento a 390/1200 px. Hashes de ambos binarios públicos contrastados.

Evidencia reproducible: [Actions del repositorio](https://github.com/Mortymel/Aurora-RGB/actions). Las pruebas Flutter usan servidores locales/simuladores; no demuestran control de la tira física. Los artefactos de Actions son temporales; las descargas recomendadas están en Releases y permanecen disponibles salvo que se elimine la versión o el archivo.

## Controles

Credenciales protegidas en Android y backup/transferencia de datos excluidos. HTTP sin redirecciones y con respuesta limitada. Escrituras fallidas no reenviadas automáticamente. Las respuestas antiguas no se aplican a otro controlador. Vista en vivo agrupa entradas y descarta pendientes al cerrar/cambiar de controlador. Contradicciones de horarios se rechazan en app y placa. Arranque apagado inicial; recuperación optativa y límite físico de brillo en la ESP32.

## Pendiente

Prueba en el teléfono/router/ESP32/XGB1338 real; descubrimiento multicast en la LAN del usuario; orden RGB/GRB, nivel lógico de datos, alimentación; MQTT Discovery y disponibilidad con un broker real; validación de transiciones y persistencia tras cortes.

HTTP Basic y MQTT 1883 no cifran tráfico. NVS no tiene cifrado adicional. Las claves iniciales son conocidas y se cambian al compilar. El APK carece de firma estable de distribución; reinstalar puede perder preferencias. No hay bloqueo/versionado entre clientes externos que editen simultáneamente la configuración. UTC es fijo, la cuenta atrás se pierde al reiniciar y no hay OTA.

[Seguridad](https://github.com/Mortymel/Aurora-RGB/blob/main/SECURITY.md) · [Hardware](https://github.com/Mortymel/Aurora-RGB/blob/main/docs/HARDWARE.md) · [Trabajo pendiente](https://github.com/Mortymel/Aurora-RGB/blob/main/docs/ROADMAP.md).

## Auditoría documental de cierre

Se contrastaron las versiones con pubspec.yaml, el firmware y Releases. Se corrigieron enlaces del repositorio renombrado, la URL antigua de Pages (404), la versión Android de referencia, las instrucciones de descarga por Releases y la descripción desactualizada de la simulación. Se separaron uso, conexión, firmware, diseño y compilación. Las rutas antiguas de las guías se mantienen como redirecciones documentales.

El informe de comprobaciones de enlaces está en [VALIDACION-DOCUMENTACION.md](https://github.com/Mortymel/Aurora-RGB/blob/main/docs/VALIDACION-DOCUMENTACION.md). Los enlaces correctos no demuestran una instalación física ni el rendimiento en todos los teléfonos.

## Revisión de la interfaz 1.2.0

Se sustituye la configuración global de la tira por sesiones independientes desde el engranaje de cada luz. Una ventana con navegación interna sustituye los formularios superpuestos. Ajustes permanece como pantalla general y se retiran el selector de pantalla inicial y la vista compacta. La rueda y la esfera se conservan.

La nueva prueba con dos placas simuladas verifica que guardar MQTT en Dormitorio escribe únicamente en su API, conserva Escritorio como seleccionado y no modifica su broker. También comprueba el regreso dentro de una sola ventana y que Ajustes no contiene controles de la luz.

LEDWeb 1.3.0 recompilado con ESP32 Arduino 3.3.12, NeoPixel 1.15.5, ArduinoJson 7.4.3 y PubSubClient 2.8: C6 1.212.902 bytes de programa y 53.132 de RAM estática; ESP32 clásico 1.127.477 y 58.656 bytes. Se comprueban cabeceras, familia, tabla de particiones y tamaño de las imágenes fusionadas. No ha sido necesario cambiar el protocolo ni la versión del firmware. [Validación física pendiente](TECHNICAL-TESTS.md).

## Corrección 1.2.1: JSON de órdenes HTTP

En la prueba física se observó que las lecturas reconocían el ESP32, pero toda escritura devolvía `JSON invalido`. La app enviaba POST sin Content-Length y Dart utilizaba Transfer-Encoding: chunked. El WebServer de ESP32 Arduino 3.3.12 lee el cuerpo JSON de acuerdo con Content-Length; sin él, no expone el argumento plain que deserializa LEDWeb.

La app codifica ahora el JSON en bytes UTF-8, establece contentLength con el tamaño de esos bytes y los envía directamente. Se aplica a luz, configuración, reloj y temporizador. No modifica el protocolo de LEDWeb ni requiere reflashear la placa.

La nueva prueba de regresión reproduce exactamente `JSON invalido` antes de la corrección usando un servidor que rechaza cuerpos chunked como el ESP32. También comprueba longitud en bytes, nombres con acentos y todas las rutas de escritura. Las pruebas anteriores usaban un servidor HTTP que sí admitía chunked y no detectaban esta incompatibilidad.
