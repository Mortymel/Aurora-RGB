# Seguridad de Aurora

Usa el controlador en una LAN de confianza. HTTP Basic y MQTT sin TLS no cifran credenciales ni comandos. No abras puertos del controlador o broker hacia Internet.

Cambia WEB_PASSWORD y AP_PASSWORD de config.h al compilar para uso permanente. Los binarios genéricos incluyen admin/tiraesp32 y AP tiraesp32. Wi-Fi y MQTT se cambian desde la interfaz; GET config solo indica si existe clave.

La app usa almacenamiento protegido Android y deshabilita backup/transferencia de esos datos. Eso no cifra el tráfico HTTP ni la NVS del firmware. No publiques claves privadas, volcados de memoria o capturas con contraseñas. El repositorio no incluye una firma estable de distribución para Google Play.

La app bloquea redirecciones de credenciales, limita respuestas y tiempos; el firmware autentica su interfaz, requiere JSON y valida campos. Estos controles no equivalen a una auditoría independiente. La consulta mDNS descubre direcciones, no autentica equipos.

Para avisar de un fallo sin secretos usa un issue con versiones y pasos. Si el problema contiene información sensible, no la incluyas públicamente: no hay un canal privado de reporte confirmado en esta documentación.

[Auditoría](docs/AUDITORIA.md).
