extends SceneTree
func _initialize() -> void:call_deferred("preview")
func preview() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",3,24683,true)==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.set_physics_process(false)
 arena.submit_ready()
 arena.server_tick(2.5)
 arena.camera.global_position=Vector3(-51,22,31)
 arena.camera.look_at(arena.spawn_center(0,12)+Vector3.UP)
 arena.update_hud()
 await create_timer(0.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://screenshots/team-lift-descent.png")
 arena.server_tick(2.6)
 arena.camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 arena.camera.size=68
 arena.camera.global_position=Vector3(0,90,0)
 arena.camera.look_at(Vector3.ZERO,Vector3.FORWARD)
 for child in arena.get_children():
  if child is CanvasLayer:child.hide()
 await create_timer(0.2).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://screenshots/octagonal-arena-spawns.png")
 print("PASS rendered opposing side lifts and octagonal arena overview")
 quit()
