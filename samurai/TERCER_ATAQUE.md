# Tercer ataque — guía para la animación

Destino recomendado: `samurai/AttackContinue2/`. Ocho GIF independientes, con el nombre de dirección: south-west, west, north-west, north, north-east, east, south-east y south. No reflejar: el personaje y la espada son asimétricos. De momento se reutiliza AttackContinue1 con un ritmo más lento y un arco mayor; no hay animación nueva dibujada.

Duración en juego: 1,05 s. Impacto a los 0,45 s. Recuperación completa hasta 1,23 s desde el inicio: los últimos 0,18 s pueden estar ya en la pose neutra, pero todavía no se cancela el remate con dash o habilidad.

Propuesta: nueve fotogramas, fondo transparente y el mismo tamaño de lienzo y anclaje de pies en las ocho vistas. Mantén margen para el recorrido de la espada; no recortes cada fotograma por separado.

1. Enlaza desde el final del segundo corte, espada al costado.
2. Baja el centro de gravedad y lleva la espada atrás.
3. Gira caderas y hombros: anticipación clara.
4. Espada arriba/atrás, peso en la pierna posterior.
5. Impacto: corte diagonal amplio y paso corto hacia delante, aproximadamente a 0,45 s.
6. Continúa el arco, con el torso siguiendo la espada.
7. Termina con el peso adelantado; se nota el esfuerzo.
8. Recupera guardia lentamente.
9. Regresa a una pose compatible con idle.

No basta con mover la espada: cambia piernas, cadera, hombros, pelo y ropa. Los pies deben conservar su referencia en el lienzo para que el sprite no tiemble. El paso es visual y corto, no un dash dibujado. La estela de fuego se dibuja en el juego, así que no hace falta incrustarla en todos los GIF.

Las duraciones individuales del GIF servirán como referencia; al integrarlo se ajustará la reproducción para que el fotograma de contacto coincida con el daño a 0,45 s. Guarda también el archivo .aseprite editable.

Reglas: 12 / 14 / 24 de daño base; los dos primeros permiten enlazar, el segundo tiene 0,28 s de reacción y el tercero tarda 0,45 s en contactar. El rival recupera el control antes del tercero: puede esquivar o hacer parry. No es un combo de tres golpes garantizados.
