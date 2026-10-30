# Aurora

App web independiente para LEDWeb. Código fuente único de la versión real y de la demo; no depende de la app Android anterior.

- `index.html`: pantallas y formularios.
- `app.css`: diseño adaptable Aurora.
- `app.js`: controles, estado y preferencias.
- `transport.js`: API del mismo origen, timeout y errores.
- `preview.js`: aproximación animada de los efectos.

## Probar sin ESP32

Desde la raíz: `node demo/server.cjs`. Abrir `http://127.0.0.1:8765/aurora`. Los datos son simulados; no introducir claves reales. La esfera muestra el color seleccionado y la tira el efecto aproximado. Horarios y Ajustes ocultan la vista previa.

## Usar en ESP32

Ejecutar `node scripts/build-aurora.cjs` tras editar la app. Genera `firmware/LEDWeb/aurora_ui.h` con HTML, CSS y JavaScript comprimidos. `scripts/compile.ps1` lo hace automáticamente. El header se incluye en el firmware y no necesita sistema de archivos ni Internet.

Abrir la IP de la ESP32 en el teléfono y autenticar con los datos de `config.h`. La interfaz clásica sigue disponible en `/classic`. El navegador administra HTTP Basic; Aurora no almacena la contraseña del administrador.

La versión real se selecciona al empaquetar con `data-demo="false"`; no puede activarse por un parámetro de URL. Añadir otra ESP32 abre su dirección, sin realizar peticiones cruzadas entre orígenes. Es necesario cargar este firmware en cada placa.

La auditoría, límites y comprobaciones físicas están en `docs/AUDITORIA-AURORA.md`.
