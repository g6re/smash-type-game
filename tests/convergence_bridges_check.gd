extends SceneTree
func _initialize() -> void:call_deferred("check")
func check() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",1,24694,true,"convergence")==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.set_physics_process(false)
 var points:Array=preload("res://game/convergence/layout.gd").POINTS
 for pair in [[0,1],[0,2],[0,3],[0,4],[1,4],[4,2],[2,3],[3,1]]:
  var a:Vector3=points[pair[0]]
  var b:Vector3=points[pair[1]]
  var direction:Vector3=(b-a).normalized()
  arena.player.position=a+Vector3.UP*0.04
  for i in range(ceili(a.distance_to(b)/8*60)):
   arena.player.velocity=direction*8-Vector3.UP
   arena.player.move_and_slide()
   await physics_frame
   assert(arena.player.position.y> -0.1,"Bridge joins both plazas without a floor gap")
  assert(arena.player.position.distance_to(b)<0.5)
 print("PASS eight bridge routes connect all five plazas")
 quit()
