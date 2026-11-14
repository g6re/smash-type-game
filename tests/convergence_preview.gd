extends SceneTree
func _initialize() -> void:call_deferred("preview")
func preview() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",1,24693,true,"convergence")==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.set_physics_process(false)
 arena.submit_ready()
 arena.server_tick(5.1)
 arena.player.position=Vector3(0,0.1,4)
 arena.objective_clock=8
 arena.tick_pickups(0.01)
 arena.update_hud()
 arena.camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 arena.camera.size=89
 arena.camera.global_position=Vector3(40,70,70)
 arena.camera.look_at(Vector3.ZERO)
 for child in arena.get_children():
  if child is CanvasLayer:child.hide()
 await create_timer(0.7).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://screenshots/convergence-overview.png")
 print("PASS Convergence scene rendered")
 quit()
