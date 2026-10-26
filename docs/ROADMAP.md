> Documento de planificación histórica. El estado vigente de la versión 0.8.0 está en [README](../README.md), [Bluetooth](BLUETOOTH.md) y [auditoría](AUDITORIA.md). El alta BLE ya está implementada; autenticación por prueba de posesión y validación física siguen pendientes.

# Hoja de ruta

Este documento distingue trabajo publicado, trabajo sin validar y funciones futuras. No representa promesas de fecha.

## Etapa 0 — Repositorio y compilación

- [x] Repositorio GitHub privado y código Flutter inicial.
- [x] Workflow para intentar construir un APK Android.
- [x] Documentación inicial de arquitectura, hardware y API.
- [ ] Obtener un workflow verde y APK instalable verificado.
- [ ] Probar instalación en dispositivo Android real.

## Etapa 0.5 — Experiencia de app (inspiración comercial)

- [x] Navegación inferior: Inicio, Escenas, Efectos, Ajustes.
- [x] Galería de seis escenas rápidas.
- [x] Guardar, aplicar y eliminar escenas personalizadas en almacenamiento local.
- [x] Vista ilustrativa de tira LED y accesos rápidos.
- [x] Temporizador de apagado local (solo mientras la app siga activa).
- [x] Renombrar dispositivo y editar dirección IP.
- [ ] Validar compilación y experiencia de usuario en Android físico.
- [ ] Rueda HSV interactiva, edición de colores precisos y vista LED real.
- [ ] Escenas por zonas, programaciones persistentes y sincronización multi-dispositivo (requieren firmware).

## Etapa 1 — Control RGB estable

- [x] Interfaz inicial de encendido, brillo, color, velocidad y efectos.
- [x] Cliente HTTP para endpoints previstos.
- [ ] Publicar firmware ESP32 compatible y documentar pines.
- [ ] Probar de extremo a extremo con varias cantidades de píxeles y tiras compatibles, incluidos reinicio y reducción de longitud.
- [ ] Validar colores, límites de corriente y rendimiento.
- [ ] Manejar desconexiones, errores y estados no compatibles.

## Etapa 2 — Experiencia de usuario

- [ ] Descubrimiento mDNS y gestión de varios dispositivos.
- [ ] Favoritos, escenas y presets persistentes.
- [ ] Segmentos LED y paletas configurables.
- [ ] Pruebas unitarias, de widgets y de integración.

## Etapa 3 — BLE seguro

- [x] Código experimental de búsqueda de periféricos BLE.
- [ ] Definir servicio y características GATT.
- [ ] Proteger el aprovisionamiento (prueba de posesión, sesión temporal, evitar credenciales en logs).
- [ ] Implementar recepción y almacenamiento seguro de WiFi en firmware.
- [ ] Validar Android 12+ y manejo de permisos.

## Etapa 4 — Integraciones

- [ ] Micrófono INMP441, I²S, FFT y efectos musicales.
- [ ] MQTT y descubrimiento Home Assistant.
- [ ] WebSocket para estados y cambios en tiempo real.
- [ ] OTA con validación de integridad y mecanismo de recuperación.

## Criterios de versión 1.0

APK reproducible, firmware público o disponible para instalación, API documentada y probada, hardware validado, guía de recuperación, pruebas automáticas y una política clara de seguridad y versiones.

