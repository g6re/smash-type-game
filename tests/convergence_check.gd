extends SceneTree
func _initialize() -> void:call_deferred("check")
func check() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",1,24691,true,"convergence")==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.set_physics_process(false)
 arena.submit_ready()
 arena.server_tick(5.1)
 assert(arena.stock_mode and arena.phase=="battle")
 var opponent:=0
 for actor in arena.actors.values():
  actor.protection=0.0
  if actor.team==1:opponent=actor.id
 assert(opponent!=0)
 var target:Dictionary=arena.actors[opponent]
 arena.damage_actor(opponent,160,1,Vector3.ZERO)
 assert(target.percent==160 and target.alive and target.stocks==3,"Percentage does not kill")
 arena.eliminate(opponent)
 assert(target.stocks==2 and not target.alive)
 arena.server_tick(1)
 assert(arena.phase=="battle","Pending respawn does not end the game")
 arena.server_tick(1.6)
 assert(target.alive and target.percent==0 and target.stocks==2 and target.protection>0)
 var actor:Dictionary=arena.actors[1]
 actor.body.position=Vector3.ZERO
 target.body.position=Vector3(25,0,-12)
 actor.ult=0
 arena.objective_clock=8
 arena.tick_pickups(2.1)
 assert(actor.ult==35 and arena.objective_captured)
 arena.objective_clock=33
 arena.tick_pickups(0)
 assert(arena.objective_index==1)
 actor.percent=60
 actor.body.position=Vector3(0,0,26)
 arena.objective_clock=8
 arena.tick_pickups(2.1)
 assert(actor.percent==35,"Heal reduces percentage")
 arena.objective_index=2
 arena.objective_clock=8
 arena.objective_captured=false
 actor.body.position=Vector3(0,0,-26)
 arena.tick_pickups(2.1)
 assert(actor.buff==8,"Stamina reward is temporary regeneration")
 arena.objective_index=0
 arena.objective_clock=8
 arena.objective_captured=false
 arena.orb_capture.clear()
 actor.body.position=Vector3.ZERO
 target.body.position=Vector3(1,0,0)
 arena.tick_pickups(3)
 assert(not arena.objective_captured,"Enemy contests the capture")
 target.body.position=Vector3(25,0,-12)
 arena.tick_pickups(1)
 assert(float(arena.orb_capture.get(1,0))>0)
 actor.protection=0
 arena.damage_actor(1,5,opponent,Vector3.ZERO)
 assert(not arena.orb_capture.has(1),"Damage interrupts capture")
 var state:Dictionary=arena.pack_state()
 assert(state.actors[0].has("stocks") and state.has("objective_index"))
 target.protection=0
 arena.eliminate(opponent)
 arena.server_tick(3)
 target.protection=0
 arena.eliminate(opponent)
 arena.server_tick(0.1)
 assert(arena.phase=="match_end" and target.stocks==0)
 print("PASS Convergence percentage, three stocks, respawn, protection, rotating energy/heal objectives, contest and victory")
 quit()
