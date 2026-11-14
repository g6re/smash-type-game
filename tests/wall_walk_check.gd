extends "res://game/arena.gd"
func _ready() -> void:
 super._ready()
 set_physics_process(false)
 abilities.sparring=false
 player.position=Vector3(8.0,3,0)
 parkour.wall_lock=0
 await get_tree().physics_frame
 for i in range(12):
  assert(parkour.update_wallrun(Vector3.FORWARD,1.0/60))
  player.move_and_slide()
  await get_tree().physics_frame
 var gap:float=8.5-player.position.x
 assert(gap>0.4 and gap<0.65,"Wallrun stays close to wall")
 camera.global_position=player.position+Vector3(-5,2,5)
 camera.look_at(player.position+Vector3.UP)
 visual.wall_running=true
 visual.wall_normal=parkour.wall_normal
 visual.animate(0.016,player.velocity,false,false,false,0,1)
 assert(visual.state=="wall_walk" and visual.sprite.is_playing())
 assert(visual.sprite.billboard==BaseMaterial3D.BILLBOARD_DISABLED)
 var tilted_up:Vector3=visual.sprite.global_basis.y
 assert(tilted_up.dot(parkour.wall_normal)>camera.global_basis.y.dot(parkour.wall_normal),"Wallrun uses the corrected lean side")
 if DisplayServer.get_name()!="headless":
  await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://screenshots/wall-walk-lean.png")
 visual.wall_running=false
 visual.animate(0.016,Vector3.ZERO,true,false,false,0,1)
 assert(visual.sprite.billboard==BaseMaterial3D.BILLBOARD_ENABLED)
 print("PASS: close wallrun, reused locomotion, wallward lean and restoration")
 get_tree().quit()
