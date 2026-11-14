# Animaciones del samurái

El juego carga un único atlas: `samurai-atlas.png`. Su manifiesto contiene regiones, tiempos y alineación de los pies. `base_rotations.tres` conecta esas regiones con los estados del controlador.

Fuentes actuales:
- Idle: archivo editable y hoja exportada; base contiene las poses de referencia.
- Running, Jumping, Climbing y Attack: un GIF original por dirección.
- Crouch y Sliding: un PNG original por dirección.
- Walking: secuencia este para caminar lento con Alt.

No se reflejan direcciones ni se escalan los píxeles al construir el atlas. Los nombres de GIF pueden cambiar, pero deben terminar en `_east.gif`, `_north.gif`, etc. Debe existir exactamente un GIF por dirección para evitar elegir versiones antiguas por accidente.

Para reconstruir desde la raíz del proyecto (Python con Pillow):

```powershell
python samurai/build_atlas.py
& 'C:/Users/PC/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --path . --editor --quit
& 'C:/Users/PC/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --path . --script tests/prepare_samurai.gd
```

El generador valida todos los fotogramas antes de guardar y calcula la altura de apoyo de attack y slide desde las fuentes. No necesita hojas intermedias por dirección. Conserva los GIF y archivos editables: son las fuentes, no duplicados del juego.



