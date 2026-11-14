extends SceneTree
func _initialize() -> void:call_deferred("run_check")
func run_check() -> void:
 var rules=preload("res://game/descent/rules.gd")
 assert(rules.connect_match(self,true,"",3,24673,true)==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.set_physics_process(false)
 assert(arena.actors.size()==3)
 for line in arena.ropes.lines:
  for step in range(21):assert(arena.mantle_space_clear(line.a.lerp(line.b,step/20.0)),"Expanded rope blocked at %s" % line.a.lerp(line.b,step/20.0))
 arena.set_ready(1,[4,1,1,0],true)
 assert(arena.phase=="preparation","Invalid builds cannot ready")
 arena.submit_ready()
 assert(arena.phase=="elevator" and arena.actors.size()==6)
 var occupied:Array[Vector3]=[]
 for actor in arena.actors.values():
  assert(not occupied.has(actor.body.position),"Every team member gets a separate place in its lift")
  occupied.append(actor.body.position)
 var packed:PackedByteArray=var_to_bytes(arena.pack_state()).compress(FileAccess.COMPRESSION_GZIP)
 assert(packed.size()<1300,"Full 3v3 snapshot fits one network packet")
 arena.server_tick(5.1)
 assert(arena.phase=="battle" and arena.elevator.position.y==0)
 for actor in arena.actors.values():actor.body.position=Vector3(10,0.1,10)
 var opponent:int=-3
 assert(arena.actors[opponent].team==1)
 arena.damage_actor(-1,20,1,Vector3.ZERO)
 assert(arena.actors[-1].hp==112,"No friendly fire")
 var defender:Dictionary=arena.actors[opponent]
 defender.body.position=Vector3(5,0.1,0)
 defender.body.rotation.y=0
 defender.parry=0.22
 arena.damage_actor(opponent,20,1,defender.body.position+Vector3(0,1,-2))
 assert(defender.hp==112,"Front parry blocks damage")
 defender.parry=0.22
 arena.damage_actor(opponent,20,1,defender.body.position+Vector3(0,1,2))
 assert(defender.hp==92,"Back hit bypasses parry")
 defender.parry=0
 arena.server_tick(0.26)
 assert(arena.actors[1].ult>0)
 arena.player.position=Vector3(-2,0.1,8)
 defender.body.position=Vector3(-0.5,0.1,8)
 arena.model.rotation.y=-PI/2
 var hp_before:float=defender.hp
 arena.server_action(1,"uppercut",{})
 arena.server_tick(0.01)
 assert(defender.hp<hp_before and defender.body.velocity.y==13,"Authoritative uppercut damages and launches with Ascenso rite")
 defender.body.position=Vector3(10,0.1,10)
 arena.actors[1].body.position=Vector3.ZERO
 arena.round_time=26
 arena.tick_pickups(2.1)
 assert(arena.orb_taken and arena.actors[1].buff==12)
 arena.start_round()
 for actor in arena.actors.values():actor.body.position=Vector3(10,0.1,10)
 arena.actors[1].body.position=Vector3.ZERO
 defender.body.position=Vector3(2,0.1,0)
 arena.round_time=26
 arena.tick_pickups(3)
 assert(not arena.orb_taken,"Opponent contests orb")
 defender.body.position=Vector3(10,0.1,10)
 arena.tick_pickups(1)
 assert(not arena.orb_taken)
 arena.damage_actor(1,1,opponent,defender.body.position)
 assert(not arena.orb_capture.has(1),"Damage interrupts capture")
 arena.tick_pickups(1)
 assert(not arena.orb_taken)
 var heal:Dictionary=arena.pickups[0]
 arena.actors[1].body.position=heal.node.position
 arena.actors[1].hp=20
 heal.timer=0
 arena.tick_pickups(0.1)
 assert(arena.actors[1].hp==45 and not heal.available)
 var ultimate:Dictionary=arena.pickups[2]
 arena.actors[1].body.position=ultimate.node.position
 ultimate.timer=0
 arena.tick_pickups(0.1)
 assert(arena.actors[1].ult==15)
 arena.round_time=80
 arena.actors[1].body.position=Vector3(31,0.1,0)
 var before:float=arena.actors[1].hp
 arena.server_tick(0.5)
 assert(arena.zone_radius<arena.START_RADIUS and arena.actors[1].hp<before)
 for actor in arena.actors.values():
  if actor.team==1:arena.damage_actor(actor.id,999,1,Vector3.ZERO)
 arena.server_tick(0.1)
 assert(arena.phase=="round_end" and arena.scores[0]==1)
 arena.server_tick(4)
 assert(not defender.alive,"No respawn before next round")
 arena.server_tick(1.1)
 assert(arena.phase=="elevator","Each round begins on the team elevators")
 arena.server_tick(5.1)
 assert(arena.phase=="battle" and defender.alive and defender.hp==112)
 arena.scores=[2,0]
 arena.finish_round(0)
 arena.server_tick(5.1)
 assert(arena.phase=="match_end")
 arena.restart_match()
 assert(arena.phase=="preparation" and arena.scores==[0,0] and arena.actors.size()==3)
 assert(not arena.actors[1].ready)
 print("PASS 3v3 fill, build validation, packet size, friendly fire, directional parry, uppercut damage/launch, ultimate gain, orb contest/interruption, pickups, poison, round respawn and rematch")
 preload("res://game/game_modes.gd").main_menu(self)
 await process_frame
 assert(multiplayer_is_offline())
 quit()
func multiplayer_is_offline() -> bool:return get_multiplayer().multiplayer_peer is OfflineMultiplayerPeer


