# Mapas

- `original/arena.tscn`: arena inicial; `layout.gd` contiene su geometría.
- `parkour/parkour_arena.tscn`: circuito de movimiento y cuerdas.
- `hollow_bastion/hollow_bastion.tscn`: escenario importado con plataformas sólidas y vacío exterior.

Escape permite cambiar entre los tres. El controlador común permanece en `game/arena.gd`. Hollow Bastion es el escenario inicial y no añade el rail cuadrado del prototipo.

Hollow Bastion conserva el archivo descargado en `source.zip` y sus recursos extraídos en `assets/`. La licencia y el autor están en `assets/license.txt` y en `CREDITS.txt`: Caleb Smores, CC-BY-NC-4.0, uso no comercial.

La cámara puede girar 360 grados horizontalmente; el giro vertical está limitado para evitar que se invierta. Conserva la detección de obstáculos para no introducirse en las plataformas sólidas.


Hollow Bastion incluye iluminación HD-2D en lighting.gd: luz cálida y relleno violeta, SSAO, glow moderado, cielo de atardecer, mar de niebla animado y motas doradas. Los shaders están en hollow_bastion/shaders/. La viñeta se aplica antes del HUD y no desenfoca los sprites. El fondo es decorativo, sin colisión. Vista de comprobación: tests/lighting_preview.tscn.

