# Habilidades del samurái

Las habilidades usan efectos provisionales; no requieren nuevas animaciones de sprites.

- Q, Espiral de fuego: mantener carga hasta 1,5 s flotando; soltar atraviesa con estela. Enfriamiento 2,5 s.
- E, Ascua fugaz: lanza una brasa hasta 16 m; queda disponible durante 5 s. Pulsa E de nuevo cuando llegue para impulsarte hasta ella y golpear el recorrido (20 de daño). El desplazamiento colisiona con paredes. Enfriamiento 8 s desde el lanzamiento. Cerca de una cuerda, E prioriza la interacción de cuerda.
- F, Filo ascendente: eleva al personaje y a enemigos en un arco frontal de unos 3 m. Hace 18 de daño. Enfriamiento 6 s. No restaura el doble salto.
- X, Eclipse carmesí: requiere 100 % de carga obtenida golpeando. Marca un círculo de 6 m en el punto de lanzamiento; durante 1,15 s atrae suavemente y al finalizar golpea por 40 y lanza hacia arriba. Los enemigos pueden salir y las paredes bloquean el efecto.
- V, Parry: ventana frontal de 0,22 s. Un golpe bloqueado devuelve una barra de stamina y rechaza al atacante. Enfriamiento 1,2 s; fallar deja 0,25 s de recuperación. Los ataques por la espalda atraviesan la defensa.

Los muñecos cercanos atacan cada cierto tiempo, avisando con un círculo rojo durante medio segundo. Usan la misma función de daño y parry. Se puede desactivar esta práctica desde Escape. El daño recibido aumenta el empuje y aparece en el HUD.

Stamina: tres barras para dash. Salto de suelo, doble salto y walljump son gratuitos. Hay un único salto extra en el aire; no se permite un tercer salto normal. La recuperación es de 0,25 barras/s tras un segundo sin gasto. Las habilidades tienen sus propios enfriamientos.

Box conserva su orbe y no recibe las habilidades del samurái.

Comprobaciones: `tests/abilities_check.tscn` cubre doble salto gratuito y límite, parry frontal/espalda/recuperación, golpe de entrenamiento, Ascua, Filo y definitiva. `tests/skill_check.tscn` verifica Q y stamina.

Combo básico: clic inicia el primer corte. Otro clic durante la ventana del primer golpe (tras el arranque) guarda la continuación y la ejecuta al entrar en recuperación. También se puede encadenar hasta 0,3 s tras terminar. El segundo corte remata por 20 de daño y más elevación; no hay tercer golpe nuevo. Tras una pausa vuelve al primer ataque. AttackContinue1 aporta nueve fotogramas propios para el segundo golpe en las ocho direcciones, sin reflejos.


La Q usa un shader de fuego por bandas con bordes recortados y colores rojo/naranja/amarillo. La carga muestra tres arcos orbitando; la estela tiene espiral afilada, media luna frontal, brasas y remate. Los efectos conservan la oclusión por el escenario y se limpian al terminar. Referencia visual aportada: https://www.youtube.com/watch?v=3_TB6R_FeDE . Comprobación de render y limpieza: tests/fire_fx_check.tscn.


Parry visual: arco celeste al activar y, en bloqueo perfecto, estrella blanco-dorada, tres anillos de energía recortada y doce chispas. Los efectos duran menos de medio segundo y no alteran la ventana ni el enfriamiento. Renderer comprobado con tests/parry_fx_check.tscn.


Estilo visual unificado: partículas con textura pixel art de 7 × 7 y filtro nearest, combinadas con arcos, espirales y cortes 3D de sombreado anime. Ascua tiene halo y estela; Filo tiene un corte ascendente; Eclipse forma un vórtice sobre su radio de 6 m y detona con dos cortes cruzados, expansión, luz cálida y brasas. Q, parry, orbes de Box y partículas de movimiento usan el mismo emisor pixelado. Los cambios son visuales: no modifican daño, radios ni enfriamientos. Comprobación de render, fases y limpieza en tests/ability_fx_check.tscn.

