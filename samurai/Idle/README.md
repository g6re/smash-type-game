# Idle de ocho direcciones

Archivo usado por el juego: `samurai-idle-sheet.png` (384 × 512).
Seis columnas de fotogramas y ocho filas: sur, sureste, este, noreste,
norte, noroeste, oeste y suroeste. Celdas de 64 × 64, fondo transparente.
Cada ciclo dura 1,44 segundos.

Archivo editable: `samurai-idle-8-directions.aseprite`.
Las poses originales de `base/` se conservan porque el juego las usa para
movimiento y los demás estados sin animación.

Después de editar el archivo de Aseprite, exporta el spritesheet desde
la raíz del proyecto:

```powershell
./tools/aseprite/app/aseprite.exe --batch --script samurai/Idle/export_sheet.lua
```

Godot importa automáticamente el PNG actualizado.
Los tiempos de fotograma están en `samurai/base_rotations.tres` y en
`tests/prepare_samurai.gd`.
