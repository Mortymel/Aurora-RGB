# Seguridad — 0.8.0

El alta inicial requiere BLE cifrado con emparejamiento Just Works y una ventana de configuración de 10 minutos. La reapertura de una placa configurada requiere BOOT físico. No hay AP WiFi abierto. Las credenciales no se guardan en las preferencias de Android, pero sí en NVS de ESP32 sin cifrado en reposo.

Just Works no proporciona protección contra intermediario activo ni prueba criptográfica de posesión. HTTP local y MQTT opcional no tienen TLS ni autenticación propia del controlador. La firma actual del APK es de desarrollo. No desplegar en redes públicas ni exponer la placa a Internet. Para producción faltan identidad/autenticación, gestión de claves, firma estable, cifrado de almacenamiento y validación física.

Consulta el [informe de auditoría](docs/AUDITORIA.md) para correcciones, riesgos residuales y pruebas pendientes. No publiques contraseñas WiFi, claves privadas, tokens ni volcados NVS al informar un problema.
