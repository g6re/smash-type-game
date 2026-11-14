extends SceneTree
func _initialize() -> void:call_deferred("run_check")
func key(code:Key,pressed:bool) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=pressed
 Input.parse_input_event(event)
func run_check() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",1,24682,true)==OK)
 await process_frame
 for frame in range(10):await physics_frame
 var arena:Node=current_scene
 assert(arena.lifts.size()==2)
 assert(arena.actors[-101].team==0 and arena.actors[-102].team==1)
 assert(arena.player.position.x < -31 and arena.actors[-102].body.position.x>31)
 arena.submit_ready()
 assert(arena.phase=="elevator")
 var before:Vector3=arena.player.position
 key(KEY_D,true)
 for frame in range(20):await physics_frame
 key(KEY_D,false)
 assert(arena.phase=="elevator" and arena.elevator.position.y<24)
 assert(Vector2(arena.player.position.x-before.x,arena.player.position.z-before.z).length()>1,"WASD moves during descent")
 assert(absf(arena.player.position.y-arena.elevator.position.y)<0.35,"Floor carries a grounded passenger smoothly")
 var ray_query:=PhysicsRayQueryParameters3D.create(arena.spawn_center(0,arena.elevator.position.y)+Vector3.UP,arena.spawn_center(0,arena.elevator.position.y)+Vector3(8,1,0),1)
 ray_query.exclude=[arena.player.get_rid()]
 var gate_hit:Dictionary=arena.get_world_3d().direct_space_state.intersect_ray(ray_query)
 assert(not gate_hit.is_empty() and gate_hit.collider.name=="ArenaGate","Door stays closed during descent")
 key(KEY_SPACE,true)
 key(KEY_SPACE,false)
 for frame in range(6):await physics_frame
 assert(arena.player.position.y-arena.elevator.position.y>0.3,"Jump remains relative to moving lift")
 var last_position:Vector3=arena.player.position
 while arena.phase=="elevator":
  last_position=arena.player.position
  await physics_frame
 assert(arena.phase=="battle")
 assert(Vector2(arena.player.position.x-last_position.x,arena.player.position.z-last_position.z).length()<0.5,"Landing does not teleport into the arena")
 assert(arena.lifts[0].gate.position.y==4.5)
 key(KEY_W,true)
 for frame in range(80):await physics_frame
 key(KEY_W,false)
 assert(arena.player.position.x>-31,"Walk through the landing gate into the connected arena")
 assert(arena.player.position.y>-0.2,"Spawn and arena floors join without a fall")
 var corner_query:=PhysicsRayQueryParameters3D.create(Vector3(31,2,27),Vector3(31,-2,27),1)
 assert(arena.get_world_3d().direct_space_state.intersect_ray(corner_query).is_empty(),"Arena contour has clipped corners")
 print("PASS two side spawns, separate training targets, free WASD/jump on moving lifts, closed/open gates, no landing teleport, joined floors and octagonal contour")
 quit()
