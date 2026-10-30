# Informe de validación de la documentación

Revisión del 30 de octubre de 2026 para Aurora Android 1.1.1 y LEDWeb 1.3.0.

## Hallazgos corregidos

| Hallazgo | Corrección |
|---|---|
| Nombre anterior del repositorio en enlaces | Referencias actuales a Mortymel/Aurora-RGB |
| Instalador con URL anterior que devuelve 404 | URL actual de GitHub Pages, comprobada por HTTP |
| Versión Android 1.1.0 en guías vigentes | Referencia 1.1.1+5, contrastada con pubspec y Releases; el changelog conserva el historial |
| Documentación aún anunciaba simulación en Efectos | Se explica la carga progresiva y las muestras estáticas; animación solo en Mi luz |
| Descargas de Actions tratadas como única entrega | Releases como descarga principal, artefactos de Actions como alternativa temporal |
| Nombres de guías heredados poco claros | Conexión, Firmware y Diseño como guías canónicas; rutas anteriores conservadas como enlaces |
| Falta de recorrido para el usuario | Nueva guía de uso con color, escenas, horarios, claves y diagnóstico |
| Instrucciones de compilación dispersas | Guía de compilación con rama/carpeta correctas, conservación del lockfile y configuración Android |
| Riesgo de confundir código raíz antiguo con Aurora | Tabla de rutas y advertencias sobre los componentes heredados |
| Notas futuras de Releases con enlace antiguo al firmware | Enlace del workflow actualizado al proyecto renombrado |

## Comprobaciones realizadas

- Inventario de todos los Markdown de main y revisión de las guías de la app en su rama actual.
- Contraste con firmware, pubspec, workflow de publicación y última Release.
- Comprobación automática de enlaces relativos, enlaces a archivos/rutas del repositorio, anclas Markdown, títulos, bloques de código y JSON de ejemplo.
- Búsqueda de referencias al repositorio anterior y de afirmaciones desactualizadas sobre Efectos.
- Comprobación HTTP de las entradas públicas de Releases, GitHub Pages, manifiesto y datos de compilación del instalador.
- Comparación de los documentos publicados con los archivos revisados mediante sus hashes Git.

Los resultados y el número de documentos/enlaces corresponden a la ejecución de validación de esta revisión; no son una vigilancia continua de servicios externos.

Resultado local: **31 documentos, 74 enlaces relativos y 2 ejemplos JSON**, sin incidencias en el comprobador. Las entradas públicas existentes comprobadas devolvieron HTTP 200; la ruta anterior de Pages devolvió 404 y fue reemplazada.

El workflow **Documentation checks** ejecuta `node scripts/check-docs.cjs` para comprobar enlaces relativos, anclas, encabezados, bloques y JSON sin dependencias adicionales. No visita servicios externos en cada ejecución. Los enlaces públicos necesitan una comprobación separada cuando cambie el nombre o alojamiento del proyecto.

## Qué no demuestra esta auditoría

No equivale a pruebas de rendimiento en el teléfono del usuario, validación eléctrica, instalación USB en la placa ni prueba de MQTT con su broker. Tampoco certifica seguridad, firma de producción o soporte de chips sin binarios publicados. El estado funcional y sus límites están en [AUDITORIA.md](AUDITORIA.md).

[Índice](README.md) · [Instalación](INSTALACION.md) · [Uso](GUIA-DE-USO.md).
