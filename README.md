# Smash / Pixel Arena

Abre `project.godot` en Godot y pulsa F5. El juego inicia en un vestíbulo jugable (`game/menu/main_menu.tscn`): camina hasta un portal y pulsa E, o usa sus botones. Práctica permite elegir escenario y personaje. El Descenso permite crear o unirse por IP a partidas 1v1, 2v2 y 3v3. El Archivo contiene el lore. Todos los escenarios de práctica están organizados en `maps/`.

## Organización

- `game/`: controlador, habilidades, movimiento, efectos y menús.
- `maps/`: escenarios separados por carpetas, con sus scripts, escenas y recursos.
- `samurai/`: fuentes actuales de animación, atlas único y escena del samurái pixel art. Consulta `samurai/ATLAS.md` para reconstruirlo.
- `box/`: personaje alternativo Box y sus recursos con licencia.
- `character_base/` y `assets/`: recursos usados por los muñecos de entrenamiento.
- `tests/`: comprobaciones de animación, combate, movimiento y cuerdas.
- `screenshots/`: capturas del prototipo.
- `archive/`: archivo de trabajos anteriores, excluido de la importación de Godot.
- `tools/`: Aseprite, Blender y herramientas de trabajo.

## Controles

WASD mueve; ratón gira la cámara; Alt camina lento; Espacio salta; Shift hace dash; C agacha; Ctrl desliza conservando inercia; clic izquierdo ataca; botón derecho activa strafe; Q mantenida carga y al soltar lanza la habilidad. E engancha cuerdas y Espacio suelta con impulso. R reaparece. Escape abre las opciones.

El mantle es automático al avanzar en el aire hacia un borde. Las paredes permiten wallrun y walljump; otro Espacio durante la ventana de impulso activa un dash. Los rails flotantes permiten grind. Detalles en `game/MOVIMIENTO.md`.

El samurái usa ocho direcciones independientes, sin reflejar sprites. Idle y running tienen animaciones; salto y mantle siguen el movimiento físico; ataque usa los GIF actuales sincronizados con el golpe. Crouch y sliding usan poses estáticas. Walking animado solo está disponible hacia el este.

Q del samurái atraviesa con fuego y estela; Box lanza magia. Hay tres barras de stamina y una opción de stamina ilimitada para entrenar. El samurái dispone de E (Ascua fugaz), F (Filo ascendente), X (definitiva) y V (parry). El doble salto es gratuito. Consulta `game/HABILIDADES.md`.


El registro de modos y escenarios está en `game/game_modes.gd`. El modo por rondas, su red ENet, atributos y arena están en `game/descent/`. Consulta [El Descenso](game/descent/README.md) para conectar por IP, reglas, balance inicial y limitaciones del prototipo. Puerto UDP por defecto: 24567. La navegación se comprueba con `tests/menu_check.gd`; las reglas y los dos procesos de red tienen comprobaciones específicas.

Smash conserva el combate original por porcentaje, empuje creciente, caída al vacío con reaparición y combo de dos golpes (12/20), accesible desde Modo Smash en el vestíbulo. Permite escoger los tres escenarios existentes. Práctica mantiene sus controles y opciones de entrenamiento. El Descenso tiene sus propias reglas de vida, equipos, rondas, energía/arsenal y cadena táctica de tres ataques. Cambiar de mapa desde las opciones de Smash conserva el modo. `tests/smash_mode_check.gd` verifica el acceso y las reglas originales; `tests/descent_combo_check.gd` comprueba que la cadena de tres sigue disponible en El Descenso.

La arena de El Descenso usa un santuario escalonado: patio bajo, dos jardines elevados a 3,2 m, seis rampas, pabellones y galerías de entrada. Diseño y verificación en `game/descent/art/HILLSIDE.md`; la versión plana anterior se guarda en `archive/maps/sanctuary-v1`. Vista general: `screenshots/sanctuary-gardens.png`.

Convergencia es un modo independiente en red, 1v1/2v2, con porcentaje, tres vidas y objetivos rotativos. Acceso desde su estación o botón en el menú. Mapa de cinco plazas conectadas, todavía en bloqueado funcional; reglas y pruebas en `game/convergence/README.md`.
