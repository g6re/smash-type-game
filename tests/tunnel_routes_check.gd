extends SceneTree
func _initialize() -> void:call_deferred("check")
func check() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",1,24689,true)==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.submit_ready()
 arena.server_tick(5.1)
 arena.set_physics_process(false)
 for side in [-1,1]:
  for x in [-25.8,-12.8,12.8,25.8]:
   arena.player.position=Vector3(x,0.04,side*14.2)
   arena.player.velocity=Vector3.ZERO
   for i in range(90):
    arena.player.velocity=Vector3(0,-1,side*4)
    arena.player.move_and_slide()
    await physics_frame
   assert(arena.player.position.z*side>19.5,"Portal %s/%s blocked at %s" % [side,x,arena.player.position])
   assert(arena.player.position.y<0.1,"Tunnel remains at courtyard level")
  arena.player.position=Vector3(-24,0.04,side*20)
  for i in range(360):
   arena.player.velocity=Vector3(8,-1,0)
   arena.player.move_and_slide()
   await physics_frame
  assert(arena.player.position.x>23,"Cross the full tunnel below the terrace")
  var query:=PhysicsRayQueryParameters3D.create(Vector3(0,2,side*20),Vector3(0,4,side*20),1)
  var hit:Dictionary=arena.get_world_3d().direct_space_state.intersect_ray(query)
  assert(not hit.is_empty() and absf(hit.position.y-2.6)<0.05,"A solid playable roof separates both routes")
 print("PASS eight standing entrances, both cross-map tunnels and solid terrace roofs")
 quit()
