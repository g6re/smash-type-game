extends "res://maps/hollow_bastion/hollow_bastion.gd"
func _ready() -> void:
 super._ready()
 abilities.sparring=false
 await get_tree().create_timer(0.35).timeout
 set_physics_process(false)
 model.rotation.y=0
 camera.global_position=player.position+Vector3(2.5,2.8,6)
 camera.look_at(player.position+Vector3.UP)
 assert(abilities.parry())
 visual.protecting=true
 visual.animate(0.016,Vector3.ZERO,true,false,false,0,1)
 await get_tree().create_timer(0.06).timeout
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://screenshots/anime-parry-guard.png")
 assert(abilities.receive_hit(10,player.position+Vector3(0,1,-2),Vector3.BACK*8))
 for node in get_children():
  if node.get_script()==preload("res://game/parry_fx.gd") and node.success:
   node._process(0.045)
   node.set_process(false)
 await get_tree().process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://screenshots/anime-parry-perfect.png")
 for node in get_children():
  if node.get_script()==preload("res://game/parry_fx.gd"):node.set_process(true)
 await get_tree().create_timer(0.6).timeout
 for node in get_children():
  assert(node.get_script()!=preload("res://game/parry_fx.gd"),"Parry effects must expire")
 print("PASS: anime guard and perfect parry render, damage blocked, effects cleaned")
 get_tree().quit()

