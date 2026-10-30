# LEDWeb 1.3 — firmware de Aurora

Firmware actual para ESP32-C6 y ESP32 clásico. [Compilar](../../../docs/FIRMWARE-PLAN.md) · [API](../../../docs/API.md) · [Hardware](../../../docs/HARDWARE.md) · [Instalar por USB](https://mortymel.github.io/Aurora-RGB/).

La interfaz web se genera desde ledweb/app/aurora con ledweb/scripts/build-aurora.cjs antes de compilar. Mantener config.h, web_ui.h y aurora_ui.h junto a LEDWeb.ino. Los binarios genéricos tienen claves iniciales conocidas; compilar con claves propias para uso permanente. El directorio raíz firmware contiene otro proyecto heredado.
