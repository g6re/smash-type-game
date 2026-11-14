# El Descenso — prototipo multijugador

El menú inicial es un vestíbulo jugable. Camina hasta PRÁCTICA, EL DESCENSO o ARCHIVO y pulsa E. También hay accesos con botones; Escape libera el cursor. Práctica conserva los tres mapas y sus opciones anteriores. El Archivo contiene el lore de la Última Brasa.

## Conectar

1. Ambos jugadores deben ejecutar la misma versión del proyecto con Godot 4.7.2.
2. En EL DESCENSO, el anfitrión elige 1v1, 2v2 o 3v3, puerto UDP (24567 por defecto) y si completar plazas con bots. Pulsa Crear partida.
3. Los demás escriben la IP del anfitrión y el mismo puerto, y pulsan Unirse por IP. En el mismo ordenador: 127.0.0.1; en LAN: dirección local del anfitrión. Para Internet hace falta que el puerto UDP del anfitrión sea accesible desde fuera (router/firewall); esta versión no tiene relay, matchmaking ni perforación NAT automática.
4. Tab alterna cursor/cámara. Hay 45 segundos para repartir atributos y probar ataques contra objetivos pasivos: no persiguen ni atacan, pero reciben daño y empujes. Para redistribuir, primero resta un punto y luego súbelo en otra categoría. Marca Listo para adelantar el descenso. Al agotarse el tiempo se confirma la última distribución válida de cada jugador. Sin bots, el contador espera a que se llenen las plazas humanas; con bots, comienza directamente y los huecos se completan al bajar.
5. Cada equipo tiene su propio spawn cuadrado de 12 × 12 m, anexo a un lado de la arena. Allí elige atributos y dispone de un objetivo pasivo. Con todos listos, los dos ascensores descienden a la vez durante cinco segundos: se puede caminar, saltar y hacer dash dentro mientras bajan. Las puertas se levantan al llegar y se sale directamente a la arena, sin teletransporte al centro. Cada ronda comienza con este descenso. No se admiten incorporaciones en mitad de una partida. Escape vuelve al vestíbulo y desconecta; si el anfitrión sale, termina la conexión de los demás.

No se ha verificado una conexión entre redes externas. Sí se ha verificado ENet con dos procesos independientes en localhost, incluida una acción enviada por el cliente, vida autoritativa, ascensor, eliminación, marcador y reaparición en la siguiente ronda.

## Reglas iniciales

- Solo Samurai de fuego. El anfitrión controla daño, parry, vida, atributos, bots, recursos, orbe, veneno y resultados. Los clientes predicen su movimiento; el anfitrión comprueba desplazamientos finitos y limita la distancia, con colisiones. Es una primera implementación de red, sin rollback ni simulación completa de entradas en el servidor.
- Seis puntos de atributos; máximo tres por categoría. Vitalidad: +6 PV por punto sobre 100. Fuerza: +3 % daño. Agilidad: +2 % velocidad terrestre. Foco: +5 % carga de definitiva por daño. Son valores de partida para probar equilibrio, no balance competitivo validado.
- Sin daño entre compañeros en la arena. El parry dura 0,22 s y bloquea por delante; deja pasar golpes por detrás. Las tres habilidades, combos y definitiva mantienen los controles del modo práctica.
- El primer ataque retiene al objetivo con un empuje suave y 0,72 s de reacción, suficiente para enlazar el segundo ataque que se haya pulsado durante la ventana de combo. El segundo inflige 14 de daño y retiene solo 0,28 s. El tercero inflige 24, tarda 0,45 s en impactar y remata con empuje fuerte y 0,5 s de reacción. Hay una apertura para esquivar o hacer parry antes del tercero. El remate dura 1,05 s y compromete hasta 1,23 s, sin cancelación con dash o habilidades. Recibir daño cancela ataques pendientes, habilidades y movimiento especial; hay destello y sacudida visual sobre el sprite existente. Un parry corta la cadena y deja al atacante en reacción 0,25 s. La interfaz cuenta impactos confirmados consecutivos contra el mismo rival.
- Para evitar bloqueos infinitos, la cadena tiene un presupuesto de 1,3 s de reacción y, al terminar el remate o agotarse el presupuesto, se conceden 0,65 s en que los nuevos golpes siguen causando daño/empuje pero no vuelven a bloquear el control. El empuje del remate aumenta hasta un 80 % según la vida perdida. F y la definitiva lanzan hacia arriba. La vida propia tiene una barra grande y los demás llevan barras con números y color de equipo.
- Definitiva: carga al infligir daño (75 % del daño, modificado por Foco). Vida, stamina, cooldowns y definitiva se restablecen cada ronda.
- Al morir, quedas eliminado y observas hasta la siguiente ronda. No hay reanimaciones. La última escuadra con supervivientes gana la ronda; primera en ganar tres rondas gana la partida. Un empate no suma puntos. El anfitrión puede iniciar otra partida al terminar.
- Curas: +25 PV, reaparecen cada 20 s. Fragmentos violeta: +15 de definitiva, reaparecen cada 25 s. Primera aparición a los 18 s de la ronda.
- Orbe central dorado: aparece a los 25 s, una captura por ronda. Exige dos segundos a menos de 1,5 m del centro y sin rivales a menos de 3 m. Recibir daño o salir interrumpe la captura. Otorga doce segundos de regeneración acelerada de stamina al portador (+0,75 barras/s, además de la regeneración normal); no aumenta la capacidad ni concede invulnerabilidad.
- El anillo verde delimita la zona segura. Tras 35 s comienza a encogerse; llega al centro sobre los 140 s. Fuera causa daño creciente, de 4 a un máximo de 12 PV/s. Caer al vacío elimina.
- Arena central octagonal de 64 × 56 m y dos spawns laterales opuestos, inspirada en el esquema aportado. Coberturas en L, columnas diagonales, centro abierto, rutas de flanqueo, muros para wallrun, terrazas con accesos de mantle y cuatro cuerdas laterales (E, Espacio para soltar). El radio seguro inicial es de 44 m para incluir los spawns; el cierre sigue llegando al centro hacia los 140 s. Los bots tienen persecución y evasión de obstáculos simples; no dominan todavía todo el parkour. La arena original de práctica mide 32 × 32 m y el circuito de parkour tiene rutas exteriores; los rails quedan sobre el vacío.

## Verificación

- `tests/descent_rules_check.gd`: 3v3, plazas con bots, atributos inválidos, paquete comprimido dentro del MTU, fuego amigo, parry frontal/trasero, carga de ulti, captura disputada/interrumpida, curas, fragmentos, veneno, rondas, revancha y desconexión al volver al menú.
- `tests/descent_network_check.gd`: ejecutar dos procesos con `--script tests/descent_network_check.gd -- host` y `--script tests/descent_network_check.gd -- client`, en ese orden. Usa UDP 24671 y sale automáticamente.
- `tests/descent_combo_check.gd`: enlace real de los dos impactos, interrupción de represalias, remate, recuperación, límite de reacción, validación de la segunda etapa y ruptura por parry. Las cuerdas de la arena ampliada también se comprueban con la cápsula completa en la prueba de reglas.
- `tests/descent_lifts_check.gd`: spawns separados, WASD y salto durante la bajada, transporte relativo al suelo, puertas cerradas/abiertas, llegada sin teletransporte, unión de suelos y esquinas recortadas. Ejecutar con `--fixed-fps 60`. La prueba con dos procesos verifica además el movimiento del cliente remoto durante el descenso.
- `tests/menu_check.gd`: vestíbulo, lore, panel de red, selección de práctica y retorno desde pausa.
- Regresión: habilidades, combo y parkour existentes.


## Energía y arsenal del Samurai

En El Descenso, la barra anterior de definitiva es ahora energía compartida: 0–100 en cuatro segmentos de 25. Se gana al causar daño real a la vida, modificado por Foco, y con fragmentos del mapa. No hay regeneración pasiva. Empieza en cero cada ronda. La stamina sigue siendo un recurso aparte para movimiento.

- F: Filo normal, gratis, 6 s de enfriamiento.
- T: Filo EX, cuesta 25, comparte enfriamiento con F. Daño base 26 en vez de 18 y +3 de lanzamiento vertical. El daño es modificado por Fuerza.
- V: parry normal, gratis, 0,22 s de ventana.
- G: Guardia EX, cuesta 50, comparte enfriamiento con V. Ventana de parry de 0,42 s y escudo de 25 durante 3 s. El escudo absorbe daño aunque falle el parry; no es invulnerabilidad.
- X: definitiva, cuesta 100. Gastar en EX retrasa su disponibilidad. No se puede lanzar con energía insuficiente y el anfitrión valida coste, estado y enfriamiento.

Antes de descender se eligen tres mejoras en el panel Arsenal, una alternativa por grupo. Se bloquean al marcar Listo; para cambiarlas hay que cancelar Listo. Al agotarse el tiempo queda la última selección válida aceptada por el anfitrión. Las mejoras se mantienen entre rondas.

- Q: Alcance (+3 m, −15 % daño) o Fulgor (−2 m, +15 % daño).
- F / T: Ascenso (+3 impulso vertical al golpe y al usuario) o Barrido (+3 de empuje horizontal al golpe).
- Parry V / G: Disciplina (+8 energía si acierta) o Respiro (+8 vida si acierta, sin superar el máximo).

Es una adaptación inicial del concepto de energía, variantes EX y mejoras de habilidades; no reproduce todo el kit ni el sistema de objetos/consumibles de Battlerite. Los atributos se conservan junto al arsenal por ahora. Las EX se usan mediante T/G para no interferir con Shift, que controla el dash. El panel indica sus costes. Los efectos actuales se reutilizan con un destello azul de energía; siguen pendientes iconos y animaciones propias de EX.

`tests/descent_energy_check.gd` comprueba costes, enfriamientos compartidos, bloqueo de ulti, absorción/caducidad del escudo, validación/bloqueo de arsenal, variantes de Q/parry y energía sin exceso por overkill.
