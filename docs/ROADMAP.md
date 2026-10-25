# Hoja de ruta

Este documento distingue trabajo publicado, trabajo sin validar y funciones futuras. No representa promesas de fecha.

## Etapa 0 — Repositorio y compilación

- [x] Repositorio GitHub privado y código Flutter inicial.
- [x] Workflow para intentar construir un APK Android.
- [x] Documentación inicial de arquitectura, hardware y API.
- [ ] Obtener un workflow verde y APK instalable verificado.
- [ ] Probar instalación en dispositivo Android real.

## Etapa 1 — Control RGB estable

- [x] Interfaz inicial de encendido, brillo, color, velocidad y efectos.
- [x] Cliente HTTP para endpoints previstos.
- [ ] Publicar firmware ESP32 compatible y documentar pines.
- [ ] Probar de extremo a extremo con la tira real de 320 píxeles.
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
