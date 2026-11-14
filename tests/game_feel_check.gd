extends SceneTree
func _initialize() -> void:call_deferred("check")
func check() -> void:
 assert(change_scene_to_file("res://maps/original/arena.tscn")==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.set_physics_process(false)
 arena.abilities.sparring=false
 assert(arena.steer_velocity(Vector3(12.5,0,0),Vector3.ZERO,8,0.016,false)==Vector3(12.5,0,0),"Air release preserves momentum")
 assert(arena.steer_velocity(Vector3(12.5,0,0),Vector3.RIGHT,8,0.016,false).x==12.5,"Forward input preserves dash jump speed")
 assert(arena.steer_velocity(Vector3.ZERO,Vector3.RIGHT,8,0.1,true).x==8,"Ground control reaches running speed within 100 ms")
 var feel:Node=arena.feel
 assert(feel.sounds.size()==9 and feel.voices.size()==8)
 for wave in feel.sounds.values():assert(wave.data.size()>1000)
 arena.player.position=Vector3(0,8,0)
 arena.player.velocity=Vector3.ZERO
 arena.jumps=0
 arena.coyote_left=0.08
 arena.jump()
 assert(arena.jumps==1 and arena.player.velocity.y==10 and arena.coyote_left==0)
 arena.jumps=2
 arena.coyote_left=0
 arena.player.velocity=Vector3.ZERO
 arena.jump()
 assert(arena.jump_buffer>0 and arena.player.velocity.y==0)
 arena.player.position=Vector3(0,0.05,6)
 arena.player.velocity=Vector3(0,-5,0)
 for i in range(8):arena._physics_process(1.0/60)
 assert(arena.player.velocity.y>0,"Buffered jump fires on landing")
 var before:Vector3=arena.player.velocity
 feel.impact(arena.player.position,true)
 assert(feel.hit_pause>0 and not paused and Engine.time_scale==1)
 assert(arena.player.velocity==before,"Presentation does not change combat physics")
 feel.intensity=0
 assert(feel.camera_offset()==Vector3.ZERO)
 feel.volume=0
 feel.tick(0.1)
 assert(feel.hit_pause==0)
 await create_timer(1.2).timeout
 print("PASS coyote jump, buffered landing, synthesized sounds, local visual impact, physics isolation and reduced motion")
 quit()
