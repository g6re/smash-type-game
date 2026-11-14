extends "res://maps/parkour/parkour_arena.gd"
func _ready() -> void:
 super._ready()
 set_physics_process(false)
 abilities.sparring=false
 await get_tree().physics_frame
 # Each checkpoint has solid ground and standing clearance.
 for point in route_points:
  var floor_hit:=ray(point+Vector3.UP*0.4,point-Vector3.UP*0.3)
  assert(not floor_hit.is_empty(),"Checkpoint needs a landing surface")
  assert(mantle_space_clear(point+Vector3.UP*0.06),"Checkpoint must fit a standing player")
 # Validate the whole rope path, not just its endpoints.
 for line in ropes.lines:
  for step in range(41):
   var point:Vector3=line.a.lerp(line.b,float(step)/40)
   assert(mantle_space_clear(point),"Rope route intersects solid geometry: %s" % point)
 # Six-metre wallrun gaps are genuine void, with a usable wall alongside.
 for side in [-1,1]:
  assert(ray(Vector3(side*10,1,0),Vector3(side*10,-3,0)).is_empty())
  assert(not ray(Vector3(side*11.5,1.5,0),Vector3(side*12.4,1.5,0)).is_empty())
  var recovery:=ray(Vector3(side*13,0,6),Vector3(side*13,-2,6))
  assert(not recovery.is_empty() and is_equal_approx(recovery.position.y,-1.1))
 # Free movement through the slide tunnel, standing player blocked by its roof.
 var saved:float=collider.shape.height
 collider.shape.height=1.0
 assert(mantle_space_clear(Vector3(0,0.05,1)))
 collider.shape.height=saved
 assert(not mantle_space_clear(Vector3(0,0.05,1)))
 print("PASS: checkpoint landings, rope clearances, wallrun voids, recovery ledges and slide tunnel")
 if DisplayServer.get_name()!="headless":
  pivot.position=Vector3.ZERO
  pivot.rotation=Vector3.ZERO
  camera.position=Vector3(29,28,33)
  camera.look_at(Vector3(0,1.5,-1))
  await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://screenshots/movement-circuit.png")
 get_tree().quit()
