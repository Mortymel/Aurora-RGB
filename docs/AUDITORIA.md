# Auditoría técnica — Morty's LED 0.8.0

Fecha: 26 de octubre de 2026. Alcance: todos los módulos Dart, firmware ESP32, manifiesto Android generado, dos workflows, instalador web y documentación operativa. Se revisaron el flujo de alta, persistencia, límites de entrada, asincronía, selección de dispositivos, temporizadores, seguridad local y generación de artefactos.

**Conclusión:** el flujo Bluetooth solicitado está implementado en app y firmware. La validación automática y las compilaciones se describen abajo; esto no equivale a una validación física ni a una certificación de seguridad para producción.

## Funcionamiento entregado

Flashear firmware 0.8.0 → ESP32 sin credenciales anuncia BLE → Añadir tira / Buscar por Bluetooth → seleccionar ESP32 → SSID de 2,4 GHz, contraseña, nombre y píxeles → emparejamiento cifrado → comprobar WiFi → guardar en ESP32 → confirmar identidad/IP/nombre/píxeles → añadir en la app → control WiFi local.

La contraseña no forma parte del modelo guardado en el teléfono. Una tentativa WiFi fallida no reemplaza la configuración anterior. BOOT durante 3 segundos después de arrancar reabre el alta por 10 minutos. Cancelar en el teléfono no deshace un comando que la placa ya recibió; ese caso tiene recuperación por búsqueda WiFi.

## Hallazgos corregidos

| Prioridad | Hallazgo y efecto | Corrección y evidencia |
|---|---|---|
| Alta | El firmware no iniciaba BLE y el cliente no enviaba credenciales | Servicio y características GATT compartidos; transporte real, formulario y confirmación por solicitud |
| Alta | Antiguo AP WiFi abierto para configurar la placa | Eliminado AP y `/setup`; BLE cifrado durante una ventana limitada |
| Alta | Posible pérdida de credenciales al probar otra red | WiFi con persistencia automática desactivada; candidato en RAM; evento IP nuevo y SSID coincidente antes del commit único de `setup`; restauración ante error |
| Alta | Identificador basado en solo 24 bits de la MAC, potencialmente prefijo compartido | Identificador con los 48 bits completos, usado por BLE, mDNS, almacenamiento y MQTT |
| Alta | El apagado programado podía actuar sobre otro controlador después de cambiar la selección | El temporizador captura su API y controlador originales; prueba de regresión con dos IP |
| Media | Pruebas antiguas bloqueadas por una animación de búsqueda y campos obsoletos | Transporte sustituible, casos actualizados y esperas acotadas para listas desplazables |
| Media | Permisos Bluetooth iguales para todas las versiones Android | SDK explícito: Dispositivos cercanos desde 31; ubicación hasta 30; prueba de manifiesto idempotente |
| Media | MTU pequeño o un comando interrumpido podía romper la configuración | Bloques de 20 bytes, reset explícito `!`, delimitador final, límite de 512 bytes y descarte completo de exceso/NUL |
| Media | Confirmación antigua o incoherente podía guardar datos incorrectos | `request_id`, versión, IPv4 válida y coincidencia de nombre/píxeles; pruebas del intercambio real |
| Media | Respuesta tardía después de cancelar/cerrar podía modificar el formulario | Generaciones de operación y comprobaciones de montaje; cancelación y desconexión; pruebas de resultado tardío |
| Media | WiFi guardado malformado podía dar lugar a un arranque incoherente | Validación de campos NVS al arrancar y al recuperar credenciales |
| Media | Entradas HTTP no numéricas se convertían silenciosamente en cero; validación parcial | Validación previa de controles JSON/formulario, rango/tipo y límite de cuerpo JSON a 512 bytes |
| Media | Un hostname que empezaba por `http` podía interpretarse como una URL incompleta | Normalización por presencia de `://`; rechazo de esquemas y credenciales no admitidos; prueba de regresión |
| Media | Mensajes y guías seguían prometiendo o negando funciones obsoletas | README, instalación, arquitectura, Bluetooth, firmware, web-flasher y solución de problemas actualizados |
| Media | Artefactos podían subir sin comprobar versión, contenido o offsets | Comprobación de APK con aapt, apksigner y ZIP; imagen ESP32 comparada con sus tres componentes; SHA-256 en los artefactos |
| Media | Errores emitidos por el stream de escaneo podían quedar sin manejar | Captura explícita de errores y devolución al asistente |
| Baja | Inicialización asíncrona podía continuar tras cerrar la pantalla | Comprobación `mounted` antes de usar el estado cargado |

## Comprobaciones y resultados

| Comprobación | Resultado y evidencia |
|---|---|
| Código de aplicación probado | `34e5e429b5fc718efc11ca62e95fee885d3b74cf`; cambios posteriores solo en documentación/manifiesto del instalador |
| Android APK #67 | **Éxito**: [ejecución 40347558048](https://github.com/Mortymel/ESP32-RGB-Studio-/actions/runs/40347558048) |
| Dart | **16 pruebas aprobadas**; análisis sin errores ni advertencias bloqueantes, con una observación informativa de estilo existente |
| Permisos Android | Prueba Python aprobada tanto localmente como en Actions; configuración idempotente |
| APK 0.8.0+9 | **54.076.246 bytes**, estructura ZIP/DEX/ARM64, versión y firma verificadas; lockfile y SHA-256 incluidos |
| Descarga APK final | [Artefacto 12661433960](https://github.com/Mortymel/ESP32-RGB-Studio-/actions/runs/40347558048/artifacts/12661433960), no caducado al verificar |
| Firmware #20 | **Éxito**: [ejecución 40349620618](https://github.com/Mortymel/ESP32-RGB-Studio-/actions/runs/40349620618), fuente `ddb1758790c118a98ffa7261bcd6dd13b86def50` |
| C++ de protocolo | Validación y framing aprobados con ASan/UBSan |
| Binario ESP32 | Imagen fusionada **1.700.928 bytes**; bootloader, particiones y aplicación comparados con sus offsets; versión 0.8.0 |
| Tamaño estático ESP32 | RAM: **64.252 / 327.680 bytes (19,6%)**; aplicación: **1.628.821 / 3.145.728 bytes (51,8%)**. No mide el pico de heap dinámico de BLE |
| Descarga firmware final | [Artefacto 12662578333](https://github.com/Mortymel/ESP32-RGB-Studio-/actions/runs/40349620618/artifacts/12662578333), con SHA-256 |
| Instalador publicado | Deploy Pages aprobado; [página](https://mortymel.github.io/ESP32-RGB-Studio-/) abierta en navegador y manifiesto 0.8.0/ESP32/offset 0 verificado, incluido texto UTF-8 corregido |
| Documentación local | Enlaces internos existentes y codificación UTF-8 comprobados |

Digest SHA-256 del ZIP de APK: `76743fc40bc8dbe6ff3d578c3ebd0bf284f2b5f2743cfd8a2a40ec59300de9e0`.
Digest SHA-256 del ZIP de firmware: `9a401011d04dcc70103633d0c1cb2ecc0943c2f7fdf5a17504ad320cfcec5382`.
Son hashes de los ZIP de Actions, distintos de los hashes de APK/binario incluidos dentro de cada artefacto. Las descargas de Actions tienen retención de 30 días y las verificadas vencen el 25 de noviembre de 2026.


Pruebas Dart cubren validación y conservación de datos, descubrimiento LAN, alta manual, alta BLE con éxito/error, cancelación, cierre, temporizador con cambio de dispositivo, hostname, fragmentación del transporte, UTF-8 y espacios de credenciales, respuesta antigua, confirmación incoherente y timeout. Las pruebas del intercambio utilizan las mismas funciones que el transporte GATT, con lectura/escritura sustituidas; no simulan la radio.

La prueba C++ ejecuta el código de validación y ensamblado utilizado por el firmware: límites de píxeles y contraseñas, NUL, mensajes de 512/513 bytes, descarte y recuperación del siguiente mensaje. Se ejecuta con AddressSanitizer y UndefinedBehaviorSanitizer. Es una prueba de escritorio; no cubre toda la máquina de estados ni NVS en silicio.

La prueba Python comprueba permisos Android, restricciones de SDK, `neverForLocation`, multicast y ausencia de duplicación al aplicar dos veces la configuración.

No hay entorno Flutter/PlatformIO instalado localmente: las compilaciones se ejecutaron en GitHub Actions. La prueba Python sí se ejecutó además en este entorno de trabajo. No se afirma una revisión completa de vulnerabilidades de todas las dependencias transitivas.

## Riesgos y trabajo pendiente

| Prioridad | Riesgo residual | Consecuencia y siguiente medida |
|---|---|---|
| Alta para producción | BLE Just Works cifra, pero no acredita posesión ni evita intermediario activo | Alta solo en entorno de confianza. Para distribución: secreto individual o QR y sesión autenticada; probar negociación real |
| Alta fuera de red privada | HTTP sin autenticación/TLS y MQTT opcional sin TLS | Cualquier equipo con acceso a esa LAN puede intentar controlar la placa. No exponer puertos; diseñar autenticación antes de uso público |
| Alta con acceso físico | NVS/flash no cifrada | Las credenciales pueden extraerse físicamente. Para producto: cifrado NVS/flash y secure boot con gestión de claves |
| Alta para distribución | APK con firma de desarrollo del proyecto generado | No hay clave de publicación estable entre runners; las actualizaciones pueden requerir desinstalar y perder datos locales. Configurar firma de release mediante secretos del propietario |
| Media | Sin validación física ESP32/Android/tira | No se certifican emparejamiento, rendimiento BLE+WiFi+FastLED, RAM dinámica, señal eléctrica ni cortes de corriente |
| Media | IP guardada por DHCP | Si cambia se necesita redescubrimiento LAN o edición; no hay reconexión automática por identidad estable |
| Media | Dependencias transitivas no fijadas en el repositorio con lockfile | Flutter y dependencias principales de BLE/hardware fijados; el artefacto conserva el lockfile resuelto para trazabilidad, pero falta adoptarlo como entrada versionada para reproducibilidad completa |
| Media | Temporizador y escenas locales en teléfono | El temporizador requiere proceso activo y no es un horario persistente en ESP32. No hay garantía de ejecución si Android cierra la app |
| Media | Límite por software de corriente y protocolo LED específico | No sustituye dimensionar fuente/cables/protecciones; otros protocolos/tiras necesitan firmware y verificación propios |
| Media | Escrituras de estado LED ordinario no propagan todos los errores de NVS | El alta nueva sí verifica su commit; una flash llena/averiada puede impedir persistir ediciones posteriores aunque el estado en RAM cambie |
| Baja | `device_info_plus` avisa de migración futura a Built-in Kotlin | La compilación actual es correcta con Flutter 3.47.8 fijado; revisar el plugin antes de actualizar Flutter |
| Baja | Recuperación de preferencias locales corruptas es conservadora | Una lista JSON dañada puede perderse o usar migración antigua; no hay copia ni recuperación granular de escenas/controladores |
| Funcional | Música, segmentos, OTA, horarios persistentes y alta de broker MQTT desde app pendientes | Se mantienen etiquetados como pendientes; no forman parte de la funcionalidad entregada |

## Prueba física de aceptación

1. Flash completa en ESP32-WROOM-32 de 4 MB; arrancar sin credenciales y localizarla desde Android.
2. Comprobar Android 11 o anterior y Android 12 o posterior, incluido permiso denegado y Bluetooth apagado.
3. Dar de alta con nombre acentuado y píxeles 1, 60 y 1024; verificar longitud, color GRB, brillo y alimentación adecuada.
4. Reiniciar y cortar alimentación: comprobar WiFi, nombre y longitud guardados.
5. BOOT 3 segundos después de arrancar: cambiar WiFi; probar contraseña errónea y verificar que la red anterior se conserva.
6. Cancelar/cerrar la app durante transferencia y durante conexión; recuperar por Bluetooth o LAN sin duplicar el controlador.
7. Probar dos ESP32 del mismo fabricante: IDs distintos; temporizador de una no afecta a la otra al cambiar la selección.
8. Dejar expirar los 10 minutos y comprobar que no admite nuevas escrituras; después de éxito verificar cierre al minuto.
9. Probar convivencia BLE/WiFi/FastLED, cambios de IP, apagado del router y emparejamiento antiguo tras reflashear.

Estas pruebas quedan pendientes de hardware real. El resultado automático debe interpretarse dentro de ese límite.
