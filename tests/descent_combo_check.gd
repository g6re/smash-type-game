extends SceneTree
func _initialize() -> void:call_deferred("run_check")
func run_check() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",1,24679,true)==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.set_physics_process(false)
 arena.submit_ready()
 arena.server_tick(5.1)
 var target:Dictionary=arena.actors[-1]
 target.bot=false
 arena.player.position=Vector3(-2,0.1,8)
 target.body.position=Vector3(0,0.1,8)
 target.body.rotation.y=PI/2
 arena.model.rotation.y=-PI/2
 await physics_frame
 arena.server_action(-1,"melee",{"stage":1})
 arena.server_action(1,"melee",{"stage":1})
 arena.server_tick(0.25)
 assert(target.hp<112 and target.stun>0.7)
 assert(arena.actors[1].hp==112,"First confirmed hit interrupts queued retaliation")
 assert(target.body.velocity.x<2,"Opener holds target in follow-up range")
 assert(target.visual.hurt_left>0)
 var hp_first:float=target.hp
 arena.server_action(-1,"uppercut",{})
 assert(arena.actions.is_empty(),"Victim cannot cast while staggered")
 for frame in range(40):
  if frame==24:arena.server_action(1,"melee",{"stage":2})
  arena.coast_body(target.body,1.0/60)
  arena.server_tick(1.0/60)
  await physics_frame
 assert(target.hp<hp_first,"Buffered second attack connects while opener holds target")
 assert(arena.actors[1].hit_count==2 and not arena.actors[1].finisher)
 assert(target.body.velocity.x<2,"Second hit keeps target nearby")
 arena.server_tick(0.34)
 assert(target.stun==0,"Defender recovers before third startup completes")
 arena.server_action(1,"melee",{"stage":3})
 assert(arena.actions.size()==1 and arena.actions[0].delay==0.45)
 arena.server_action(1,"q",{"direction":Vector3.RIGHT})
 assert(arena.actions.size()==1,"Third attack cannot be cancelled into a skill")
 arena.server_tick(0.46)
 assert(arena.actors[1].hit_count==3 and arena.actors[1].finisher)
 assert(target.body.velocity.x>12,"Third hit launches as a finisher")
 arena.server_tick(0.55)
 arena.server_tick(0.01)
 assert(target.escape>0 and target.stun==0,"Recovery grants an escape window")
 target.body.position=Vector3(0,0.1,8)
 var action={"owner":1,"kind":"melee","stage":1,"point":Vector3(-2,1.1,8),"direction":Vector3.RIGHT,"amount":2.0}
 arena.resolve_action(action)
 assert(target.stun==0,"Repeated hits cannot relock an escaping victim")
 target.escape=0
 target.escape_after=0
 target.stun_budget=0
 for index in range(4):arena.resolve_action(action)
 assert(target.stun_budget<=1.3 and target.escape_after>0,"Stun budget breaks indefinite chains")
 arena.actors[1].last_swing=0
 arena.actors[1].followup_left=0
 arena.actors[1].cooldowns["melee"]=0
 arena.actions.clear()
 arena.server_action(1,"melee",{"stage":2})
 assert(arena.actions.is_empty(),"Network requests cannot open with a finisher")
 target.parry=0.22
 target.body.rotation.y=PI/2
 target.stun=0
 var hp_parry:float=target.hp
 arena.resolve_action(action)
 assert(target.hp==hp_parry and arena.actors[1].stun>0,"Parry interrupts the attacker and breaks the chain")
 assert(arena.ropes.lines.size()==4 and arena.START_RADIUS>21)
 print("PASS three-hit chain, two connected openers, defensive gap before third, committed finisher, escape window and parry break")
 quit()

