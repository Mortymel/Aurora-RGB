# Política de seguridad

## Estado de seguridad

ESP32 RGB Studio es un prototipo. El cliente HTTP actual usa conexiones locales sin cifrado ni autenticación y el aprovisionamiento BLE seguro **no está implementado**.

**No expongas la API de la ESP32 a Internet.** Mantén el dispositivo en una red WiFi confiable y separada cuando sea posible.

## Reportar vulnerabilidades

No publiques contraseñas, tokens ni detalles explotables en issues públicos. Contacta al propietario del repositorio mediante un canal privado acordado. Si GitHub Private Vulnerability Reporting está habilitado, úsalo.

## Secretos

- Nunca guardar credenciales de WiFi en código, ejemplos reales, logs o issues.
- Mantener keystores y contraseñas de firma fuera del repositorio; usar secretos de GitHub Actions para builds de distribución.
- No transmitir credenciales por BLE hasta implementar autenticación y una sesión de aprovisionamiento protegida.

## Limitaciones

La aplicación no implementa hoy controles de acceso al dispositivo, actualizaciones OTA verificadas ni una auditoría de seguridad independiente. No utilizarla para instalaciones críticas.
