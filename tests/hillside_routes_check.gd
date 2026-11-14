extends SceneTree
func _initialize() -> void:call_deferred("check")
func key(code:Key,pressed:bool) -> void:
 var event:=InputEventKey.new()
 event.physical_keycode=code
 event.keycode=code
 event.pressed=pressed
 Input.parse_input_event(event)
func check() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",1,24688,true)==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.submit_ready()
 arena.server_tick(5.1)
 arena.set_physics_process(false)
 arena.yaw=0
 arena.abilities.sparring=false
 # Walk each approach up and down without jumping, mantling or teleporting.
 for side in [-1,1]:
  for x in [-20,0,20]:
   arena.player.position=Vector3(x,0.08,side*6)
   arena.player.velocity=Vector3.ZERO
   for i in range(6):
    arena.move_player(1.0/60)
    await physics_frame
   key(KEY_S if side>0 else KEY_W,true)
   for i in range(110):
    arena.move_player(1.0/60)
    await physics_frame
   key(KEY_S if side>0 else KEY_W,false)
   assert(arena.player.position.y>3.0,"Ramp reaches the upper terrace without jumping")
   assert(absf(arena.player.position.z)>16,"Route opens onto the garden")
   arena.player.velocity=Vector3.ZERO
   key(KEY_W if side>0 else KEY_S,true)
   for i in range(110):
    arena.move_player(1.0/60)
    await physics_frame
   key(KEY_W if side>0 else KEY_S,false)
   assert(arena.player.position.y<0.3,"Ramp descends to the courtyard")
 assert(arena.pickups[2].node.position.y>3.2)
 arena.player.position=Vector3(0,3.3,22)
 for actor in arena.actors.values():
  if actor.bot and actor.team==1:
   actor.body.position=Vector3(0,0.1,5)
   actor.body.velocity=Vector3.ZERO
   for i in range(240):
    arena.bot_step(actor,1.0/60)
    await physics_frame
   assert(actor.body.position.y>3.0,"Bot uses the ramp to pursue an opponent above")
   break
 print("PASS six walkable ramp routes, continuous upper/lower floors and raised pickups")
 quit()
