# Diseño y uso de Aurora

Aurora tiene cuatro secciones: Mi luz, Efectos, Horarios y Ajustes. Desde Aurora 1.1.1, la simulación animada aparece solo en Mi luz. Efectos usa muestras estáticas y un catálogo que crea las tarjetas según se desplaza la pantalla; Horarios y Ajustes no muestran la simulación.

La esfera mantiene el volumen y representa el RGB elegido; no intenta imitar físicamente la difusión de la tira. La rueda táctil permite elegir tono y saturación, con colores rápidos y RGB/HEX en ajuste preciso. Aplicar permanece visible encima del borde/teclado. La vista en vivo puede desactivarse. Deshacer recupera el estado confirmado anterior; no es un historial de acciones de Home Assistant.

Las tarjetas muestran colores estáticos orientativos, sin reproducir el efecto ni calcular cientos de muestras por tarjeta. El efecto real se ejecuta en la ESP32. Algunos efectos usan su propia paleta y otros el RGB seleccionado. El sistema respeta reducción de animaciones en la vista previa, pero eso no deshabilita por sí solo destellos en la tira real.

Las claves existentes se presentan como Contraseña configurada → Cambiar. La clave real no se recupera de la ESP32. Red abierta y MQTT sin autenticación son elecciones explícitas; no se muestran casillas técnicas de borrado como flujo normal.

El web flasher comparte colores lavanda, esfera, tarjetas redondeadas, navegación por pasos y tema claro/oscuro según el sistema. Instalar firmware sigue requiriendo navegador de escritorio compatible y un puerto USB; la app Android controla por Wi-Fi.

[Guía de uso](GUIA-DE-USO.md) · [Índice](README.md).
