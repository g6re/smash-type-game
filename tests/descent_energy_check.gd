extends SceneTree
func _initialize() -> void:call_deferred("run_check")
func run_check() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",1,24684,true)==OK)
 await process_frame
 await physics_frame
 var a:Node=current_scene
 a.set_physics_process(false)
 a.set_arsenal(1,[1,1,1])
 assert(a.actors[1].arsenal==[1,1,1])
 a.set_arsenal(1,[7,0,0])
 assert(a.actors[1].arsenal==[1,1,1])
 a.submit_ready()
 a.server_tick(5.1)
 var own:Dictionary=a.actors[1]
 a.set_arsenal(1,[0,0,0])
 assert(own.arsenal==[1,1,1],"Loadout locks after preparation")
 own.ult=24
 a.server_action(1,"ex_uppercut",{})
 assert(own.ult==24 and a.actions.is_empty())
 own.ult=100
 a.server_action(1,"ex_uppercut",{})
 assert(own.ult==75 and a.actions[0].amount>26)
 a.server_action(1,"ex_uppercut",{})
 assert(own.ult==75,"Cooldown rejection does not charge energy twice")
 a.actions.clear()
 a.server_action(1,"ultimate",{})
 assert(a.actions.is_empty(),"EX spend delays ultimate")
 a.server_action(1,"ex_guard",{})
 assert(own.ult==25 and own.shield==25 and own.parry==0.42)
 own.parry=0
 var before:float=own.hp
 a.damage_actor(1,15)
 assert(own.hp==before and own.shield==10)
 a.server_tick(3.1)
 assert(own.shield==0,"Shield expires")
 own.hp=50
 own.parry=0.22
 a.model.rotation.y=0
 a.damage_actor(1,12,-1,a.player.position+Vector3(0,1,-2))
 assert(own.hp==58,"Healing parry rite")
 own.arsenal=[0,0,0]
 own.parry=0.22
 own.ult=0
 a.damage_actor(1,12,-1,a.player.position+Vector3(0,1,-2))
 assert(own.ult==8,"Energy parry rite")
 own.cooldowns={}
 a.server_action(1,"q",{"power":1.0,"direction":Vector3.RIGHT})
 assert(a.actions.back().length==17 and a.actions.back().amount<40)
 own.cooldowns={}
 own.arsenal=[1,0,0]
 a.server_action(1,"q",{"power":1.0,"direction":Vector3.RIGHT})
 assert(a.actions.back().length==12 and a.actions.back().amount>40)
 var enemy:Dictionary=a.actors[-1]
 enemy.hp=2
 var energy_before:float=own.ult
 a.damage_actor(-1,999,1,a.player.position)
 assert(own.ult-energy_before<2,"Overkill does not grant unearned energy")
 assert(a.pack_state().actors[0].has("shield") and a.pack_state().actors[0].has("arsenal"))
 print("PASS energy costs, shared cooldowns, ultimate tradeoff, shield absorption/expiry, arsenal validation/lock, Q variants, parry variants, overkill clamp and replicated loadout")
 quit()
