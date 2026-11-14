# Santuario escalonado

La versión activa de El Descenso utiliza `layout.gd` y `hillside_sanctuary.gd`. La versión plana anterior está guardada en `archive/maps/sanctuary-v1`.

- Patio de combate a cota 0, con el orbe en el centro.
- Dos jardines elevados a cota 3,2 m, norte y sur. Son volúmenes sólidos con muros de contención, no plataformas suspendidas.
- Bajo cada jardín hay una galería transversal de 52 m, con techo a 2,6 m, cuatro accesos hacia el patio y las galerías de entrada. El volumen de las terrazas está dividido en muros, techo y apoyos: no hay un bloque de colisión oculto dentro del túnel. Ocho portales con arco, linternas cálidas y vigas interiores. El techo conserva el paseo superior; ambas rutas pueden usarse a la vez. Verificación de los ocho accesos y ambos recorridos completos en `tests/tunnel_routes_check.gd`.
- Tres rampas de 8 m de ancho por jardín, centradas en X = -20, 0 y 20. Pendiente 3,2/8, accesibles andando; seis rutas comprobadas con la cápsula real.
- Las alas de los muros unen las coberturas con las terrazas y definen los accesos. El centro mantiene espacio para esquivar y disputar el objetivo.
- Galerías laterales alineadas con los ascensores, pabellones en los jardines, vegetación agrupada y canales estrechos detrás del paseo superior. La isla tiene una base rocosa continua. Se retiran los ríos exteriores separados y las filas regulares de árboles de la versión anterior.
- Se conserva la simetría de rutas para ambos equipos. Las cuatro cuerdas se recolocan para alcanzar las terrazas sin atravesar colisiones; los dos pickups superiores se elevan con el terreno.
- Los bots reconocen las entradas de las rampas cuando persiguen a alguien en un jardín superior. No es un sistema de navegación general: sigue siendo lógica específica de esta arena.

Verificación: `hillside_routes_check.gd`, `sanctuary_art_check.gd`, `descent_lifts_check.gd`, `descent_rules_check.gd` y conexión de dos procesos `descent_network_check.gd`.

Esta es una revisión de estructura y composición, no un entorno con acabado de producción. Las mallas de arquitectura siguen siendo editables en código y los assets naturales y materiales externos mantienen los créditos de `assets/environment/CREDITS.md`.
