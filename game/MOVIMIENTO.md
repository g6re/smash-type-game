# Movimiento

No hay escalada continua: E no permite subir paredes.
El mantle se activa automáticamente en el aire al avanzar contra un borde.
La dirección debe apuntar al borde; la superficie debe ser plana y estar
entre 0,25 y 1,65 metros por encima de los pies.

Antes de iniciar se verifica el espacio de la cápsula durante la subida y
el paso al destino. El recorrido dura 0,22–0,34 segundos y usa movimiento
con colisión. Si aparece un obstáculo, se interrumpe. Al terminar se devuelve
la velocidad de avance (3–8 m/s); no consume stamina.

Box utiliza objetivos de manos con IK de dos articulaciones, codos hacia
fuera y una transición de apoyo a recuperación. Las manos se liberan mientras
el cuerpo supera el borde. Esta pose procedural sigue siendo una base para
una animación de mantle dibujada o capturada con mayor detalle.

Al caminar/correr, las manos siguen objetivos que oscilan sobre el eje de
avance y se mantienen separadas lateralmente de los pantalones.

Pruebas: `tests/mantle_check.tscn` y `tests/box_gait_check.tscn`.

## Dash y saltos encadenados

Shift gasta una barra y activa un dash de 18 m/s durante 0,22 s: unos cuatro
metros en espacio libre. La velocidad se aplica de inmediato y las paredes
siguen bloqueándolo. Espacio durante el dash lo corta y da un salto gratis,
con 12,5 m/s horizontales y 10,5 m/s verticales. Este salto se consume una vez
por dash y también puede hacerse durante los 0,13 s posteriores a su final.

La opción de Escape «Stamina ilimitada · entrenamiento» permite practicar
sin gastar barras. No elimina las colisiones ni permite encadenar otro dash
antes de terminar el actual.

## Wallrun y rail

En el aire, avanzar paralelo a una pared activa wallrun de hasta 1,25 s,
a 10,5 m/s, con gravedad reducida. Un salto de pared es gratuito. Durante
0,4 s tras ese salto, un segundo Espacio activa un impulso horizontal breve.

El rail es un circuito cuadrado flotante a 2,5 m fuera de la plataforma,
sobre el vacío, sin postes. Aterrizar encima lo engancha automáticamente
si llevas velocidad. Grind entre 9 y 12 m/s; carga fuego en los pies en unos
dos segundos. Espacio da un salto con dash gratis: WASD elige la dirección,
o sale hacia la arena si no hay entrada. Tiene bloqueo de 0,65 s antes de
volver a engancharse. El fuego permanece brevemente después de salir.

Los valores son una primera pasada de balance para probar los encadenamientos.
Prueba adicional: `tests/parkour_check.tscn`.

## Islas de parkour
El inicio abre el nuevo circuito. Escape permite volver a Arena original o seleccionar Islas de parkour. Son escenas independientes y conservan el mismo controlador.
Cinco cuerdas amarillas conectan las rutas: pulsa E a menos de 1,5 m para engancharte; Espacio suelta con impulso y Shift suelta y hace dash. Las cuerdas diagonales permiten cambiar de sentido con WASD; la orientación inicial depende del extremo y la mirada. Hay bloqueo breve para no reengancharse accidentalmente.
Incluye plataformas separadas sobre el vacío, paredes para wallrun, pasos de mantle y túnel bajo para slide. Las habilidades pueden soltar la cuerda. El reinicio limpia el enganche.


Doble salto actualizado: un salto extra en el aire gratuito, incluso con cero stamina. El salto de pared sigue siendo gratuito. Filo ascendente no restaura los saltos consumidos.


Caída rápida: dos pulsaciones de C o Ctrl en el aire separadas por un máximo de 0,4 s. Arranca a 32 m/s hacia abajo y acelera hasta 45 m/s, conservando dirección lateral limitada con WASD. No consume stamina, corta dash/wallrun/grind/cuerda y termina al aterrizar. No inflige daño de ataque ni atraviesa plataformas.


