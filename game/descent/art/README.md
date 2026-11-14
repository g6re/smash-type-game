# Santuario de la Última Brasa

**Versión activa:** santuario escalonado, con patio bajo, dos jardines a 3,2 m y seis rampas. Se construye con `hillside_sanctuary.gd`. Diseño, alturas y verificación en [HILLSIDE.md](HILLSIDE.md). La versión plana se conserva en `archive/maps/sanctuary-v1`.

## Historial de la pasada anterior

La descripción siguiente documenta la versión anterior; sus ríos exteriores y jardín noroeste ya no se instancian en la arena activa.

Pasada artística de la arena de El Descenso. Se aplica desde `match.gd` al construir la escena; no modifica Smash ni los recursos originales de personajes.

Actualización del 18 de octubre: árboles y arbustos sustituidos por modelos glTF texturizados de Quaternius; rocas del río sustituidas por sus mallas. Jardín compuesto en la entrada noroeste con un árbol retorcido protagonista, rocas, helechos, flores, hierba y pasos de piedra. Suelo y muros usan texturas estilizadas CC0 de StylizedTextures.com, con proyección mundial y mezcla de piedra/hierba en los bordes. Fuentes y licencia en `assets/environment/CREDITS.md`. Esta zona es la muestra del nuevo acabado; ascensores, puentes y arquitectura conservan geometría provisional.

- Modelado generado en Godot: piedra con esquinas biseladas, cornisas, zócalos, bandas de bronce, terrazas apoyadas en basamentos, madera oscura y remates de los ascensores.
- Suelo de losas con color por pieza, juntas, bordes y medallón radial. Materiales de mampostería y follaje con variación de color; son shaders procedurales, no texturas pintadas a mano.
- Árboles de copas rojizas y doradas, raíces, hojas caídas instanciadas, braseros con llama animada, pagodas e isla rocosa de fondo.
- Dos ríos exteriores con agua animada, cuatro cascadas, puentes de madera y bronce, árboles adicionales, rocas, arbustos, juncos, nenúfares y bruma. `river_gardens.gd` construye este paisaje y `water.gdshader` anima el agua. Los ríos y puentes son decorativos, situados fuera del espacio de combate.
- Sol cálido, relleno frío, cielo y niebla suaves, oclusión ambiental y brillo moderado. Los personajes conservan su renderizado pixel art sin filtrado.

La silueta, dimensiones, coberturas en L, spawns y trazados de cuerdas siguen siendo los de la arena. Se añaden basamentos sólidos bajo las dos terrazas elevadas para que su estructura sea coherente: tienen su propia colisión y se puede rodearlos. El paisaje exterior es decorativo y no añade paredes invisibles. El resto de adornos se mantiene dentro o muy cerca de las superficies de colisión existentes.

Las mallas arquitectónicas y shaders son editables en el proyecto; los modelos naturales y texturas proceden ahora de los autores citados. No es una reproducción de los modelos ni texturas de Battlerite. La lógica de combate, equipos, red y ascensores sigue en los scripts anteriores.

Comprobaciones: `tests/sanctuary_art_check.gd` revisa materiales, ausencia de colisiones en el paisaje, suelo octagonal y paso de la cápsula por todas las cuerdas. Su ejecución gráfica genera `screenshots/sanctuary-gameplay.png` y `screenshots/sanctuary-overview.png`. También se verifican ascensores y puertas, reglas de partida, Smash y una conexión entre dos procesos.
