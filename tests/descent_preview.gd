extends SceneTree
func _initialize() -> void:call_deferred("preview")
func preview() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",3,24676,true)==OK)
 await create_timer(0.7).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://screenshots/descent-preparation.png")
 current_scene.submit_ready()
 await create_timer(5.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://screenshots/descent-arena.png")
 print("PASS rendered network preparation and battle")
 quit()
