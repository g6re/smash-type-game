extends "res://maps/hollow_bastion/hollow_bastion.gd"
func _ready() -> void:
 super._ready()
 abilities.sparring=false
 await get_tree().create_timer(1.0).timeout
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://screenshots/hollow-hd2d-game.png")
 print("PASS: HD2D lighting rendered at gameplay camera")
 get_tree().quit()
