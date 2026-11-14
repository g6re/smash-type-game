# Circuito de movimiento

La arena original sigue en `arena.tscn`. El mapa de parkour mantiene `parkour_arena.tscn` y ahora organiza las rutas alrededor de un centro de combate.

## Rutas

- Centro: superficie de 12 × 12 m conectada al acceso sur. El bloque bajo se puede rodear o atravesar deslizando (1,20 m libres).
- Laterales: pasillos de 4 m de ancho con huecos de 6 m. Las paredes continuas permiten wallrun, walljump e impulso. El centro ofrece un desvío más seguro; no es obligatorio gastar un dash para cada tramo.
- Norte: escalones de 0,8 m conectan el centro con el cruce a 2,4 m. Pasos laterales ofrecen acceso alternativo.
- Alturas: dos terrazas a 5,2 m, dos cuerdas verticales y una transversal. La diagonal sur-norte ofrece un atajo de subida; otra devuelve al sur desde el lado este.
- Recuperación: repisas exteriores a -1,1 m junto a los pasillos, desde las que se puede recuperar con salto/mantle. El rail sigue flotando por fuera a 14,5 m.

Los aros 1–6 marcan un tramo cronometrado: lateral este, cruce norte, lateral oeste y retorno sur. La mejor marca se conserva durante la sesión del mapa. R reinicia el intento. No se fuerza una ruta: se pueden comparar atajos y encadenamientos.

Comprobaciones de `tests/layout_check.tscn`: suelo y altura libre en cada aro, espacio para la cápsula en todo el recorrido de cada cuerda, huecos reales junto a paredes, repisas de recuperación y túnel que admite crouch pero bloquea la cápsula de pie. `zipline_check` comprueba el enganche y desplazamiento reales.

Es una distribución para probar jugabilidad; los tiempos y el riesgo de los atajos deberán ajustarse jugando.
