# Convergencia

Modo independiente de Smash y El Descenso, accesible desde su estación o botón en el vestíbulo. ENet por IP/puerto, 1v1 y 2v2, con bots opcionales. Cada participante debe seleccionar Convergencia al conectarse. No incluye matchmaking ni relay.

## Reglas iniciales

- Tres vidas por participante. El porcentaje incrementa el empuje; recibir daño no elimina por vida. Se pierde una vida al caer al vacío.
- Reaparición tras 2,5 s, porcentaje a cero, protección de 2 s y pérdida de hasta 25 de energía. Los compañeros que aún tienen vidas siguen contando mientras reaparecen. Gana el equipo que agota todas las vidas rivales.
- Ataques, parry, tres habilidades, variantes EX y definitiva del samurái. Las mejoras de arsenal se conservan; atributos fijos e iguales para esta primera versión.
- Sin veneno ni vidas extra. El combate genera energía; las habilidades básicas mantienen sus cooldowns.
- Objetivos en ciclos de 33 s: 8 s de aviso, 20 s disponibles y 5 s de pausa. Marcador visible desde los últimos 5 s del aviso. Solo un objetivo activo; captura individual de 2 s, contestada por enemigos a 4 m e interrumpida al recibir daño.
- Rotación: centro (+35 energía), plaza sur (−25 puntos de porcentaje), plaza norte (8 s de regeneración adicional de stamina a 0,75 barras/s). Recompensa solo al captor, sin invulnerabilidad ni stamina ilimitada.

## Mapa

Cinco plazas circulares, cuatro puentes principales anchos (5,5 m) y cuatro conexiones laterales más arriesgadas (3,5 m). Los ascensores llegan a las plazas de equipo. Los bots siguen las conexiones principales para llegar a los objetivos.

Es un **bloqueado funcional propio**, inspirado en la organización de Fantasy Fight Arena, no una importación ni reproducción de sus assets. Sigue pendiente el acabado artístico del nuevo mapa. Se utilizan los materiales y rocas CC0 acreditados en `assets/environment/CREDITS.md`.

## Comprobaciones

`tests/convergence_check.gd`: daño, vidas, reaparición, protección, objetivos, disputa y victoria.
`tests/convergence_network_check.gd`: dos procesos ENet reales, pérdida de vida, porcentaje, reaparición y estado de objetivos.
`tests/convergence_bridges_check.gd`: recorrido físico de los ocho puentes con la cápsula del jugador.
`tests/convergence_preview.gd`: vista gráfica en `screenshots/convergence-overview.png`.
