extends "res://game/arena.gd"
func _ready() -> void:
 combo_limit=3
 tactical_combat=true
 super._ready()
 abilities.sparring=false
 player.position=Vector3(0,0.1,6)
 await get_tree().create_timer(0.2).timeout
 request_melee()
 assert(combo==1 and attack_time>0)
 request_melee()
 assert(not combo_queued,"Immediate click does not skip startup")
 await get_tree().create_timer(0.32).timeout
 request_melee()
 assert(combo_queued and combo==1)
 await get_tree().create_timer(0.38).timeout
 assert(combo==2 and attack_time>0.6,"Buffered click chains after first active frames")
 request_melee()
 assert(not combo_queued,"Early click cannot skip second startup")
 await get_tree().create_timer(0.32).timeout
 request_melee()
 assert(combo_queued)
 await get_tree().create_timer(0.38).timeout
 assert(combo==3 and attack_time>0.9)
 assert(not try_dash(),"Remate has committed recovery")
 await get_tree().create_timer(1.4).timeout
 request_melee()
 assert(combo==1,"Isolated attacks restart from the first hit")
 await get_tree().create_timer(0.86).timeout
 assert(combo_window>0)
 request_melee()
 assert(combo==2,"Click just after first hit also chains")
 set_physics_process(false)
 camera.global_transform=Transform3D.IDENTITY
 model.rotation.y=PI
 visual.animate(0.016,Vector3.ZERO,true,false,false,0.4,2)
 assert(visual.direction_id==8 and visual.sprite.animation=="attack2_8")
 var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://samurai/samurai-atlas.json"))
 var texture:AtlasTexture=visual.library.get_frame_texture("attack2_8",0)
 var region:Array=manifest.animations.followup.south[0]
 assert(texture.region==Rect2(region[0],region[1],region[2],region[3]),"Second hit uses new source")
 reset_player()
 assert(combo==0 and not combo_queued)
 model.rotation.y=PI
 visual.animate(0.016,Vector3.ZERO,true,false,false,0.6,3)
 assert(visual.sprite.animation=="attack2_8","Third uses temporary second animation")
 print("PASS: three-hit input buffer, committed third, late followup, idle reset and temporary animation")
 get_tree().quit()
