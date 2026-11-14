# Respuesta y sensación de juego

`game_feel.gd` proporciona sonido espacial sintetizado localmente, contactos con el suelo, impactos y cámara. No requiere descargas ni archivos de audio externos. Los sonidos son una primera base procedural para sustituir posteriormente por foley y espada grabados.

- Margen de salto de 100 ms al abandonar un borde y memoria de pulsación de 120 ms al aterrizar. El doble salto continúa siendo gratuito.
- Aceleración horizontal vectorial, frenado rápido y control aéreo independiente. Se conservan dash, slide, wallrun y reglas de cada modo.
- Cadencia de pasos por distancia recorrida; velocidad de reproducción de caminar/correr ajustada al desplazamiento.
- Sonidos de pasos, salto, dash, slide, aterrizaje, espada, impacto y recuperación de barras. Ocho voces espaciales con variación de tono y volumen.
- Cámara con impacto breve proporcional al aterrizaje/golpe, junto a los cambios de FOV existentes. Intensidad regulable hasta cero.
- Impacto confirmado con chispas, sonido y pausa de sprites de 35/65 ms. No se detienen física, temporizadores de habilidades, servidor ni SceneTree. Los mensajes de confirmación existentes activan el feedback de red; no se predicen impactos falsos.
- Polvo al pisar y deslizarse; partículas doradas en las zonas de hojas del Santuario; follaje con viento suave y ambiente de río espacial que sigue el tramo más próximo.
- Volumen e intensidad ajustables desde opciones en práctica/Smash, guardados en `user://game_feel.cfg` y aplicados también al entrar en El Descenso.

Verificación: `tests/game_feel_check.gd`, `tests/smash_mode_check.gd`, `tests/sanctuary_art_check.gd` y `tests/descent_network_check.gd` (dos procesos). Los tests headless no permiten valorar la calidad percibida del audio; hace falta escucharlo durante una partida.
