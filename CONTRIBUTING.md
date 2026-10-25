# Cómo contribuir

Gracias por colaborar con ESP32 RGB Studio. El repositorio es privado actualmente; el acceso y las contribuciones dependen de sus permisos.

## Propuesta de cambios

1. Abrir un issue describiendo el problema, la versión y los pasos para reproducirlo.
2. Crear una rama `feature/...` o `fix/...`.
3. Mantener los cambios pequeños y documentar decisiones relevantes.
4. Ejecutar `flutter pub get` y `flutter analyze --no-fatal-infos` antes de enviar una pull request.
5. Incluir pruebas cuando exista infraestructura para el componente afectado.

## Convenciones

- Mensajes de commit descriptivos.
- No subir credenciales WiFi, tokens, certificados, claves de firma ni archivos `.env` privados.
- Las modificaciones de hardware deben indicar tensiones, corrientes, pines y riesgos.
- No marcar funciones como terminadas sin una prueba reproducible.

## Reportar errores

Incluir: pasos, comportamiento esperado, resultado real, modelo Android, versión del firmware, versión de la app y extracto de logs **sin secretos**.
