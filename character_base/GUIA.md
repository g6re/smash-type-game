# Base editable del personaje

## Archivos
- character_base.tscn: abre esta escena en Godot para ver el personaje en el editor. Es la escena visual que usa el jugador de arena.gd. Movimiento y colisiones siguen en arena.gd.
- animations.tres: SpriteFrames editable con todas las acciones y ocho orientaciones.
- personaje_base.aseprite: copia del archivo Idle original, con las cinco vistas y sus frames. Abre en Aseprite, duplica el archivo para crear cada acción y conserva los originales de assets/iso_character.

## Dibujar y añadir un ataque
1. En Aseprite usa un lienzo de 64×64 por frame. Mantén los pies en la línea Y=63 y el mismo origen entre frames. Puedes tomar el archivo personaje_base.aseprite como referencia.
2. Dibuja la secuencia. Exporta PNG individuales o un atlas y guárdalos dentro de este proyecto (por ejemplo character_base/art/).
3. Abre character_base.tscn en Godot. Selecciona AnimatedSprite3D y abre Sprite Frames en el Inspector. Selecciona attack1_8 (ataque frontal), elimina sus frames provisionales y arrastra los PNG o usa Añadir frames de una hoja de sprites.
4. Repite para attack1_1...attack1_8. attack2 y attack3 corresponden a los otros golpes. No renombres las animaciones; el controlador ya las selecciona.
5. Selecciona CharacterBase y quita attack1 de Provisional States para desactivar su movimiento provisional. Repite al reemplazar otras acciones.
6. Guarda animations.tres y la escena; F5 para probarlo. Los frames de ataque se sincronizan con los 0.82 segundos del golpe. La ventana de daño sigue en arena.gd.

## Direcciones
1 = abajo izquierda, 2 = izquierda, 3 = arriba izquierda, 4 = arriba/espaldas, 5 = arriba derecha, 6 = derecha, 7 = abajo derecha, 8 = abajo/frente. Se calculan respecto a cámara.

El recurso original tiene cinco vistas. Mirror Left Directions está activado para reflejar las orientaciones 5, 6 y 7. Si dibujas ocho vistas independientes, desactívalo y sustituye todas las animaciones de esas direcciones.

## Acciones disponibles
idle, run, run_back, strafe_left, strafe_right, jump, fall, crouch, crouch_walk, in_crouch, out_crouch, slide, dash, climb, wall_slide, attack1, attack2, attack3.
Cada acción lleva sufijo _1..._8. Solo reposo, caminar y correr tienen animación original. Los demás slots reutilizan frames como marcadores provisionales; NO son ataques o parkour dibujados.

Para movimientos normales puedes ajustar FPS y bucle en SpriteFrames. Para salto/caída conviene desactivar el bucle cuando añadas las secuencias definitivas. Evita cambiar tamaño u origen entre frames sin ajustar Pixel Size y Offset.

## Licencia
Base: Leapopen, https://leapopen.itch.io/8dirprc01. Permite modificar y usar en juegos, incluso comerciales; no compartir/revender como assets independientes. Esta carpeta es para editar el personaje dentro del juego, no una plantilla para distribuir por separado. Consulta assets/iso_character/LICENSE.txt.
