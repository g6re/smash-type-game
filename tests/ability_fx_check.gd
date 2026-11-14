extends "res://maps/hollow_bastion/hollow_bastion.gd"
func capture(path:String) -> void:
 if DisplayServer.get_name()=="headless":return
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path)
func _ready() -> void:
 super._ready()
 abilities.sparring=false
 await get_tree().create_timer(0.3).timeout
 set_physics_process(false)
 camera.global_position=Vector3(11,10,17)
 camera.look_at(Vector3(0,1,2))
 ultimate_charge=100
 assert(abilities.ultimate())
 var effect:Node3D=abilities.ult_marker
 effect.set_process(false)
 effect._process(0.75)
 assert(effect.arcs.size()==5 and effect.pixels.mesh is QuadMesh)
 assert(effect.pixels.mesh.material.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST)
 await capture("res://screenshots/ultimate-anime-charge.png")
 abilities.tick(1.2)
 assert(effect.detonated and effect.cut.visible)
 effect._process(0.13)
 await capture("res://screenshots/ultimate-anime-finish.png")
 effect.set_process(true)
 await get_tree().create_timer(1.1).timeout
 assert(not is_instance_valid(effect),"Ultimate effect expires after the finisher")
 assert(abilities.uppercut())
 await get_tree().create_timer(0.12).timeout
 await capture("res://screenshots/uppercut-anime.png")
 await get_tree().create_timer(0.7).timeout
 print("PASS: staged ultimate, pixel particles, 3D slash, uppercut and effect cleanup")
 get_tree().quit()
