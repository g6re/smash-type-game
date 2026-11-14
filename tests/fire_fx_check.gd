extends "res://maps/hollow_bastion/hollow_bastion.gd"
func _ready() -> void:
 super._ready()
 abilities.sparring=false
 await get_tree().create_timer(0.3).timeout
 set_physics_process(false)
 player.position=Vector3(-6,0.1,3)
 yaw=-PI/2
 camera.global_position=Vector3(1,8,14)
 camera.look_at(Vector3(0,1,0))
 assert(begin_charge())
 charge_time=CHARGE_SECONDS
 await get_tree().create_timer(0.12).timeout
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://screenshots/anime-q-charge.png")
 camera.look_at(Vector3(7,1,3))
 release_charge()
 slash_direction=Vector3.RIGHT
 slash_effects.begin(slash_direction,1)
 for step in range(9):
  advance_slash(0.02)
  await get_tree().process_frame
 camera.global_position=Vector3(1,9,16)
 camera.look_at(Vector3(0,1,3))
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://screenshots/anime-q-trail.png")
 finish_slash()
 await get_tree().create_timer(1.0).timeout
 assert(slash_effects.ribbon==null,"Trail must clean up after fading")
 print("PASS: anime charge, fire trail, shader rendering and cleanup")
 get_tree().quit()
