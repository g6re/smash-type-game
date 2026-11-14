extends "res://maps/parkour/parkour_arena.gd"
func _ready() -> void:
 super._ready()
 abilities.sparring=false
 await get_tree().physics_frame
 set_physics_process(false)
 player.position=Vector3(11.65,0.05,6)
 yaw=-PI/2
 pitch=-1.3
 pivot.position=player.position+Vector3.UP*1.5
 pivot.rotation=Vector3(pitch,yaw,0)
 camera.position=Vector3(0,0.6,6)
 model.rotation.y=-PI/2
 visual.animate(0.016,Vector3.ZERO,true,false,false,0,1)
 assert(visual.sprite.billboard==BaseMaterial3D.BILLBOARD_ENABLED)
 assert(visual.sprite.global_position.x<player.position.x-0.5,"Camera-facing sprite shifts clear of wall" )
 if DisplayServer.get_name()!="headless":
  await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://screenshots/wall-camera-upright.png")
 print("PASS: samurai stays upright beside wall at steep camera pitch")
 get_tree().quit()

