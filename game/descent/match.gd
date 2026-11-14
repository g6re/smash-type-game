extends "res://game/arena.gd"
const RULES=preload("res://game/descent/rules.gd")
const ARSENAL=preload("res://game/descent/arsenal.gd")
var my_arsenal:Array=[0,0,0]
var arsenal_panel:PanelContainer
var arsenal_pickers:Array[OptionButton]=[]
var energy_note:=0.0
var phase:="preparation"
var phase_time:=0.0
var round_time:=0.0
var team_size:=1
var fill_bots:=true
var actors:Dictionary={}
var scores:=[0,0]
var local_id:=1
var network_timer:=0.0
var my_build:Array=[2,2,1,1]
var selected_ready:=false
var network_message:=""
var elevator:StaticBody3D
var zone:MeshInstance3D
const START_RADIUS=44.0
var zone_radius:=START_RADIUS
var pickups:Array[Dictionary]=[]
var orb:MeshInstance3D
var orb_available:=false
var orb_capture:Dictionary={}
var orb_taken:=false
var round_number:=1
var actions:Array[Dictionary]=[]
var header:Label
var roster:Label
var info:Label
var ready_button:Button
var attributes_panel:PanelContainer
var attribute_labels:Array[Label]=[]
var capture_labels:Label
var connection_failed:=false
var connection_wait:=0.0
var ropes:Node3D
var lifts:Array[Dictionary]=[]
const PREPARATION_SECONDS=45.0
var preparation_left:=PREPARATION_SECONDS
var hitstun:=0.0
var stock_mode:=false

func build_map() -> void:
 enable_grind_rail=false
 spawn=spawn_center(0,24)+Vector3(0,0,2)
 preload("res://game/descent/layout.gd").build(self)
 for team in range(2):make_lift(team)
 elevator=lifts[0].body
 var art:=Node3D.new()
 art.set_script(preload("res://game/descent/art/hillside_sanctuary.gd"))
 add_child(art)
 art.build(self)

func spawn_center(team:int,height:float) -> Vector3:
 return Vector3(-37 if team==0 else 37,height+0.1,12 if team==0 else -12)

func spawn_slot(team:int,slot:int,height:float=24) -> Vector3:
 return spawn_center(team,height)+Vector3(0,0,(slot-1)*2.2)

func make_lift(team:int) -> void:
 var body:=StaticBody3D.new()
 body.name="BlueSpawnLift" if team==0 else "RedSpawnLift"
 add_child(body)
 var center:=spawn_center(team,24)
 body.position=Vector3(center.x,24,center.z)
 var color:=Color("64bdd8") if team==0 else Color("dc8c72")
 box(body,Vector3(12,0.65,12),Vector3(0,-0.325,0),Color("394653"))
 lift_collision(body,Vector3(12,0.65,12),Vector3(0,-0.325,0))
 var side:float=-1 if team==0 else 1
 for edge in range(4):
  var x_edge:bool=edge<2
  var sign_value:float=-1 if edge%2==0 else 1
  var inner:bool=x_edge and sign_value==-side
  if inner:continue
  var size:=Vector3(0.2,4.2,12) if x_edge else Vector3(12,4.2,0.2)
  var point:=Vector3(sign_value*5.95,2.1,0) if x_edge else Vector3(0,2.1,sign_value*5.95)
  lift_collision(body,size,point)
  for height in [0.4,2.1,4.1]:box(body,Vector3(0.14,0.10,12) if x_edge else Vector3(12,0.10,0.14),Vector3(point.x,height,point.z),color)
  for index in range(7):box(body,Vector3(0.12,4.1,0.12),Vector3(point.x,2.05,-5.8+index*1.93) if x_edge else Vector3(-5.8+index*1.93,2.05,point.z),Color("6c7c85"))
 var gate:=StaticBody3D.new()
 gate.name="ArenaGate"
 body.add_child(gate)
 gate.position.x=-side*5.95
 lift_collision(gate,Vector3(0.22,4.2,12),Vector3(0,2.1,0))
 for z in range(7):box(gate,Vector3(0.14,4.2,0.14),Vector3(0,2.1,-5.8+z*1.93),color)
 for height in [0.4,2.1,4.1]:box(gate,Vector3(0.15,0.12,12),Vector3(0,height,0),color)
 for x in [-5.8,5.8]:
  for z in [-5.8,5.8]:
   box(self,Vector3(0.24,30,0.24),Vector3(center.x+x,14,center.z+z),Color("586978"))
   for height in range(0,29,4):box(self,Vector3(0.32,0.12,0.32),Vector3(center.x+x,height,center.z+z),color)
 for x in [-5.65,5.65]:box(body,Vector3(0.08,0.025,11.3),Vector3(x,0.025,0),color)
 for z in [-5.65,5.65]:box(body,Vector3(11.3,0.025,0.08),Vector3(0,0.025,z),color)
 var sign_label:=Label3D.new()
 sign_label.text="AZUL · ASCENSOR" if team==0 else "ROJO · ASCENSOR"
 sign_label.position=Vector3(0,4.8,0)
 sign_label.font_size=36
 sign_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 sign_label.modulate=color
 body.add_child(sign_label)
 lifts.append({"body":body,"gate":gate,"team":team})

func lift_collision(body:StaticBody3D,size:Vector3,point:Vector3) -> void:
 var collision:=CollisionShape3D.new()
 var shape:=BoxShape3D.new()
 shape.size=size
 collision.shape=shape
 collision.position=point
 body.add_child(collision)

func move_lifts(height:float,carry:bool) -> void:
 var delta:float=height-elevator.position.y
 for lift in lifts:lift.body.position.y=height
 if not carry or absf(delta)<0.00001:return
 for actor in actors.values():
  actor.body.position.y+=delta
  if actor.has("net_p"):actor.net_p.y+=delta

func update_gates() -> void:
 var progress:float=1 if phase in ["battle","round_end","match_end"] else (clampf((phase_time-4.5)/0.5,0,1) if phase=="elevator" else 0)
 for lift in lifts:lift.gate.position.y=progress*4.5

func constrain_to_spawn(body:CharacterBody3D,team:int) -> void:
 var center:=spawn_center(team,elevator.position.y)
 var previous:=body.position
 body.position.x=clampf(body.position.x,center.x-5.4,center.x+5.4)
 body.position.z=clampf(body.position.z,center.z-5.4,center.z+5.4)
 if previous.x!=body.position.x:body.velocity.x=0
 if previous.z!=body.position.z:body.velocity.z=0
 if body.position.y<center.y-0.6:
  body.position.y=center.y
  body.velocity.y=0

func _ready() -> void:
 combo_limit=3
 tactical_combat=true
 selected_character="samurai"
 super._ready()
 if selected_character!="samurai":select_character("samurai",false)
 for enemy in enemies:enemy.body.queue_free()
 enemies.clear()
 abilities.sparring=false
 unlimited_stamina=false
 combat_hud.health_mode=true
 # Competitive rounds do not expose training cheats or a map change.
 options_menu.queue_free()
 options_menu=null
 team_size=int(get_tree().get_meta("descent_size",1))
 fill_bots=bool(get_tree().get_meta("descent_bots",true))
 var peer:ENetMultiplayerPeer=get_tree().get_meta("descent_peer") if get_tree().has_meta("descent_peer") else null
 if peer==null:
  network_message="Sin conexión. Vuelve al vestíbulo para crear o unirte."
  connection_failed=true
 else:
  multiplayer.multiplayer_peer=peer
  get_tree().remove_meta("descent_peer")
  local_id=multiplayer.get_unique_id()
 multiplayer.peer_connected.connect(peer_arrived)
 multiplayer.peer_disconnected.connect(peer_left)
 multiplayer.connected_to_server.connect(connected)
 multiplayer.connection_failed.connect(failed)
 multiplayer.server_disconnected.connect(failed)
 make_hud()
 ropes=Node3D.new()
 ropes.name="AbilityRopes"
 ropes.set_script(preload("res://game/ziplines.gd"))
 ropes.arena=self
 add_child(ropes)
 for side in [-1,1]:
  ropes.add_rope(Vector3(side*26,0.1,side*5),Vector3(side*26,5.8,side*20))
  ropes.add_rope(Vector3(side*7,0.1,-side*7),Vector3(side*7,4.8,-side*18))
 zone=make_orb(Vector3.ZERO,Color("7ab749"),1.0)
 zone.mesh=make_zone_mesh()
 var boundary:=material(Color("8ce06a"),true)
 boundary.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 boundary.emission_energy_multiplier=0.4
 zone.material_override=boundary
 zone.position.y=0.08
 zone.hide()
 orb=make_orb(Vector3(0,1.2,0),Color("ffd169"),0.45)
 orb.hide()
 for p in [Vector3(-21,0.7,-9),Vector3(21,0.7,9),Vector3(0,3.9,-21),Vector3(0,3.9,21)]:
  var kind:="heal" if pickups.size()<2 else "ultimate"
  var mesh:=make_orb(p,Color("67e7a5") if kind=="heal" else Color("a391ff"),0.28)
  pickups.append({"node":mesh,"kind":kind,"available":false,"timer":18.0})
 if peer!=null and multiplayer.is_server():
  add_actor(1,0,false,"Tú")
  add_actor(-101,0,true,"Bot de prueba A")
  add_actor(-102,1,true,"Bot de prueba B")
  actors[-101].body.position=spawn_center(0,24)+Vector3(2.3,0,0)
  actors[-102].body.position=spawn_center(1,24)+Vector3(-2.3,0,0)
 elif peer!=null and peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED:connected()

func make_zone_mesh() -> TorusMesh:
 var mesh:=TorusMesh.new()
 mesh.inner_radius=0.985
 mesh.outer_radius=1.0
 mesh.rings=96
 return mesh

func make_orb(point:Vector3,color:Color,radius:float) -> MeshInstance3D:
 var node:=MeshInstance3D.new()
 var mesh:=SphereMesh.new()
 mesh.radius=radius
 mesh.height=radius*2
 node.mesh=mesh
 node.material_override=material(color,true)
 add_child(node)
 node.position=point
 return node

func add_actor(id:int,team:int,bot:bool,name_value:String) -> void:
 if actors.has(id):return
 var own:=id==local_id
 var body:CharacterBody3D=player if own else CharacterBody3D.new()
 var actor_visual:Node3D=visual if own else preload("res://samurai/samurai_base.tscn").instantiate()
 if not own:
  add_child(body)
  var collision:=CollisionShape3D.new()
  var shape:=CapsuleShape3D.new()
  shape.radius=0.38
  shape.height=1.8
  collision.shape=shape
  collision.position.y=0.9
  body.add_child(collision)
  body.add_child(actor_visual)
  body.collision_layer=2
  body.collision_mask=1
 var slot:=0
 for existing in actors.values():
  if existing.team==team and not existing.bot:slot+=1
 body.position=spawn_slot(team,slot)
 if own:
  yaw=-PI/2 if team==0 else PI/2
  pitch=-0.45
  model.rotation.y=yaw
  pivot.position=body.position+Vector3.UP*1.5
  pivot.rotation=Vector3(pitch,yaw,0)
 var label:=Label3D.new()
 label.position.y=2.25
 label.font_size=26
 label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 body.add_child(label)
 label.hide()
 actors[id]={"id":id,"team":team,"bot":bot,"name":name_value,"body":body,"visual":actor_visual,"label":label,"build":[2,2,1,1],"hp":112.0,"maxhp":112.0,"alive":true,"ready":bot,"ult":0.0,"parry":0.0,"buff":0.0,"cooldowns":{},"anim":0.0,"combo":1,"last_motion":0.0}
 if not own:enemies.append({"id":id,"body":body,"visual":actor_visual,"label":label,"damage":0.0,"spawn":body.position})
 abilities.enemy_timers.resize(enemies.size())
 abilities.enemy_marks.resize(enemies.size())

func remove_actor(id:int) -> void:
 if not actors.has(id):return
 if id!=local_id:actors[id].body.queue_free()
 actors.erase(id)
 for i in range(enemies.size()-1,-1,-1):
  if enemies[i].id==id:enemies.remove_at(i)
 abilities.enemy_timers.resize(enemies.size())
 abilities.enemy_marks.resize(enemies.size())

func peer_arrived(id:int) -> void:
 if not multiplayer.is_server():return
 if phase!="preparation" or human_count()>=team_size*2:
  multiplayer.multiplayer_peer.disconnect_peer(id)
  return
 var counts:=[0,0]
 for actor in actors.values():
  if not actor.bot:counts[actor.team]+=1
 add_actor(id,0 if counts[0]<=counts[1] else 1,false,"Portador %d" % human_count())

func peer_left(id:int) -> void:
 if not multiplayer.is_server():return
 if phase=="preparation":remove_actor(id)
 elif actors.has(id):
  eliminate(id)
  remove_actor(id)

func connected() -> void:
 hello.rpc_id(1)
func failed() -> void:
 network_message="Conexión perdida o no disponible. Escape para volver al vestíbulo."
 connection_failed=true
 multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()

@rpc("any_peer","call_remote","reliable")
func hello() -> void:
 if not multiplayer.is_server():return
 var sender:=multiplayer.get_remote_sender_id()
 if not actors.has(sender):peer_arrived(sender)

func human_count() -> int:
 var count:=0
 for actor in actors.values():
  if not actor.bot:count+=1
 return count

func submit_ready() -> void:
 if phase=="match_end":
  if multiplayer.is_server():restart_match()
  return
 if phase!="preparation" or not RULES.valid_build(my_build):return
 selected_ready=not selected_ready
 if multiplayer.is_server():set_ready(local_id,my_build,selected_ready)
 else:ready_request.rpc_id(1,my_build,selected_ready)

@rpc("any_peer","call_remote","reliable")
func ready_request(build:Array,value:bool) -> void:
 if multiplayer.is_server():set_ready(multiplayer.get_remote_sender_id(),build,value)

func set_ready(id:int,build:Array,value:bool) -> void:
 if phase!="preparation" or not actors.has(id) or not RULES.valid_build(build):return
 actors[id].build=build.duplicate()
 var stats:=RULES.stats(build)
 actors[id].hp=stats.health
 actors[id].maxhp=stats.health
 actors[id].ready=value
 if id==local_id:movement_multiplier=stats.speed
 check_ready()

func check_ready() -> void:
 if not fill_bots and human_count()!=team_size*2:return
 for actor in actors.values():
  if not actor.bot and not actor.ready:return
 start_elevator()

func start_elevator() -> void:
 stop_local_actions()
 actions.clear()
 for id in actors.keys():
  if actors[id].bot:remove_actor(id)
 # Teams retain their preparation spawn throughout the descent.
 var next_bot:=-1
 for team in range(2):
  var count:=0
  for actor in actors.values():
   if actor.team==team:count+=1
  while count<team_size:
   add_actor(next_bot,team,true,"Brasa %d" % -next_bot)
   next_bot-=1
   count+=1
 begin_descent(true)

func begin_descent(preserve_positions:bool=false) -> void:
 move_lifts(24,false)
 phase="elevator"
 phase_time=0
 actions.clear()
 var slots:=[0,0]
 for actor in actors.values():
  var center:=spawn_center(actor.team,24)
  var inside:bool=absf(actor.body.position.x-center.x)<5.4 and absf(actor.body.position.z-center.z)<5.4 and actor.body.position.y>=23.9
  if not preserve_positions or not inside or actor.bot:actor.body.position=spawn_slot(actor.team,slots[actor.team])
  slots[actor.team]+=1
  actor.body.velocity=Vector3.ZERO
  actor.hp=actor.maxhp
  actor.alive=true
  actor.ult=0
  actor.buff=0
  actor.anim=0
  actor.cooldowns={}
  actor["pose"]={"ground":true}
  actor.body.show()
  actor.body.collision_layer=1 if actor.id==local_id else 2
  actor.body.collision_mask=1
  for key in ["stun","stun_budget","escape","escape_after","followup_left","last_swing","combo_display","hit_count","shield","shield_left"]:actor[key]=0
  actor["attack_epoch"]=int(actor.get("attack_epoch",0))+1
 reset_local_combat()
 update_gates()

func start_round() -> void:
 var arriving:bool=phase=="elevator"
 move_lifts(0,arriving)
 actions.clear()
 phase="battle"
 phase_time=0
 round_time=0
 orb_taken=false
 orb_available=false
 orb_capture.clear()
 zone_radius=START_RADIUS
 for pickup in pickups:pickup.available=false;pickup.timer=18
 var slots:=[0,0]
 for actor in actors.values():
  if not arriving:
   actor.body.position=spawn_slot(actor.team,slots[actor.team],0)
   actor.body.velocity=Vector3.ZERO
  slots[actor.team]+=1
  actor.hp=actor.maxhp
  actor.alive=true
  actor.buff=0
  actor.ult=0
  actor.cooldowns={}
  for key in ["stun","stun_budget","escape","escape_after","followup_left","last_swing","combo_display","hit_count","shield","shield_left"]:actor[key]=0
  actor["attack_epoch"]=int(actor.get("attack_epoch",0))+1
 if not arriving and actors.has(local_id):reset_local_combat()
 update_gates()

func reset_local_combat() -> void:
 stop_local_actions()
 hitstun=0
 if phase in ["battle","elevator"] and actors.has(local_id):
  yaw=-PI/2 if actors[local_id].team==0 else PI/2
  pitch=-0.4
  model.rotation.y=yaw
  pivot.position=player.position+Vector3.UP*1.5
  pivot.rotation=Vector3(pitch,yaw,0)
 combo=0
 stamina=3
 skill_cooldown=0
 abilities.ember_cd=0
 abilities.upper_cd=0
 abilities.parry_cd=0
 player.show()

func stop_local_actions() -> void:
 cancel_charge()
 if slash_left>0:finish_slash()
 abilities.reset()
 attack_time=0
 combo_queued=false
 parkour.reset()
 fast_falling=false
 player.velocity=Vector3.ZERO
 if is_instance_valid(ropes) and ropes.active>=0:ropes.detach()

func restart_match() -> void:
 preparation_left=PREPARATION_SECONDS
 for id in actors.keys():
  if actors[id].bot:remove_actor(id)
 phase="preparation"
 phase_time=0
 scores=[0,0]
 round_number=1
 network_message=""
 actions.clear()
 move_lifts(24,false)
 selected_ready=false
 zone.hide()
 orb.hide()
 for pickup in pickups:pickup.node.hide()
 var slots:=[0,0]
 for actor in actors.values():
  actor.ready=false
  actor.alive=true
  actor.hp=actor.maxhp
  actor.ult=0
  actor.body.show()
  actor.body.collision_layer=1 if actor.id==local_id else 2
  actor.body.collision_mask=1
  actor.body.position=spawn_slot(actor.team,slots[actor.team])
  slots[actor.team]+=1
 add_actor(-101,0,true,"Bot de prueba A")
 add_actor(-102,1,true,"Bot de prueba B")
 actors[-101].body.position=spawn_center(0,24)+Vector3(2.3,0,0)
 actors[-102].body.position=spawn_center(1,24)+Vector3(-2.3,0,0)
 reset_local_combat()
 update_gates()

func _input(event:InputEvent) -> void:
 if event is InputEventMouseButton and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and get_viewport().gui_get_hovered_control()!=null:return
 if event is InputEventMouseMotion:
  super._input(event)
  return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:
   preload("res://game/game_modes.gd").main_menu(get_tree())
   return
  if event.keycode==KEY_TAB:
   Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
   return
  if event.keycode==KEY_R:return
 if connection_failed or phase not in ["preparation","elevator","battle"]:return
 if phase=="elevator":
  if event is InputEventKey and event.keycode in [KEY_Q,KEY_E,KEY_F,KEY_X,KEY_V]:return
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:return
 if actors.has(local_id) and not actors[local_id].alive:return
 if hitstun>0:return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_T,KEY_G] and phase in ["preparation","battle"]:
  var kind:="ex_uppercut" if event.keycode==KEY_T else "ex_guard"
  var cost:=25.0 if kind=="ex_uppercut" else 50.0
  if ultimate_charge<cost:
   energy_note=2
   return
  if kind=="ex_uppercut" and abilities.uppercut():send_action(kind,{})
  elif kind=="ex_guard" and abilities.parry():send_action(kind,{})
  return
 if event is InputEventKey and event.pressed and not event.echo and is_instance_valid(ropes):
  if event.keycode==KEY_E and (ropes.active>=0 or ropes.nearest().index>=0):
   ropes.interact()
   return
  if event.keycode in [KEY_SPACE,KEY_SHIFT] and ropes.active>=0:
   ropes.detach()
   if event.keycode==KEY_SHIFT:try_dash()
   return
 var old_f:float=abilities.upper_cd
 var old_e:bool=abilities.ember_dash
 var old_marker:bool=is_instance_valid(abilities.ember)
 var old_parry:float=abilities.parry_cd
 var old_ult:float=abilities.ult_left
 super._input(event)
 if abilities.upper_cd>old_f:
  player.velocity.y=12+(3 if my_arsenal[1]==0 else 0)
  send_action("uppercut",{})
 if abilities.parry_cd>old_parry:send_action("parry",{})
 if abilities.ult_left>old_ult:send_action("ultimate",{})
 if not old_marker and is_instance_valid(abilities.ember):send_action("ember_set",{"target":abilities.ember_target})
 if not old_e and abilities.ember_dash:send_action("ember",{})

func start_melee(stage:int) -> void:
 super.start_melee(stage)
 send_action("melee",{"stage":stage})

func release_charge() -> void:
 var power:=clampf(charge_time/CHARGE_SECONDS,0,1)
 var was:=charging
 var aim:Vector3=-camera.global_basis.z
 super.release_charge()
 if was and slash_left>0:
  slash_speed=maxf(1,6+power*8+(3 if my_arsenal[0]==0 else -2))/0.24
 if was:send_action("q",{"power":power,"direction":aim})

func begin_charge() -> bool:
 if is_instance_valid(ropes) and ropes.active>=0:ropes.detach()
 return super.begin_charge()

func apply_hit(_index:int,_amount:float,_direction:Vector3,_lift:=5.0,_melee_stage:int=0) -> void:
 # Round damage is resolved by the host from validated attack actions.
 pass
func on_player_damage(_amount:float,_source:Vector3,_knockback:Vector3,_index:int=-1) -> bool:return false
func reset_player() -> void:
 if actors.has(local_id):
  if phase=="battle":
   if multiplayer.is_server():eliminate(local_id)
   else:fall_request.rpc_id(1)
  else:player.position=spawn_center(actors[local_id].team,elevator.position.y);player.velocity=Vector3.ZERO

@rpc("any_peer","call_remote","reliable")
func fall_request() -> void:
 if multiplayer.is_server() and actors.has(multiplayer.get_remote_sender_id()):
  var id:=multiplayer.get_remote_sender_id()
  if actors[id].body.position.y< -6:eliminate(id)

func move_player(dt:float) -> void:
 if phase not in ["preparation","elevator","battle"] or connection_failed:return
 if actors.has(local_id) and not actors[local_id].alive:return
 if hitstun>0:
  coast_body(player,dt)
  return
 if is_instance_valid(ropes) and ropes.drive(dt):return
 super.move_player(dt)
 if phase in ["preparation","elevator"] and actors.has(local_id):constrain_to_spawn(player,actors[local_id].team)

func send_action(kind:String,data:Dictionary) -> void:
 if multiplayer.is_server():server_action(local_id,kind,data)
 else:action_request.rpc_id(1,kind,data)

@rpc("any_peer","call_remote","reliable")
func action_request(kind:String,data:Dictionary) -> void:
 if multiplayer.is_server():server_action(multiplayer.get_remote_sender_id(),kind,data)

func cooldown(actor:Dictionary,kind:String,seconds:float) -> bool:
 if float(actor.cooldowns.get(kind,0))>0:return false
 actor.cooldowns[kind]=seconds
 return true

func server_action(id:int,kind:String,data:Dictionary) -> void:
 if phase not in ["preparation","battle"] or not actors.has(id) or not actors[id].alive:return
 var actor:Dictionary=actors[id]
 if (phase=="preparation" and actor.bot) or float(actor.get("stun",0))>0:return
 if int(actor.get("last_swing",0))==3 and float(actor.cooldowns.get("melee",0))>0:return
 var stats:=RULES.stats(actor.build)
 var point:Vector3=actor.body.position+Vector3.UP
 var forward:Vector3=actor_forward(actor)
 var powered:=kind in ["ex_uppercut","ex_guard"]
 var cost:=25.0 if kind=="ex_uppercut" else 50.0
 if powered:
  if actor.ult<cost:return
  var cd_key:="uppercut" if kind=="ex_uppercut" else "parry"
  if float(actor.cooldowns.get(cd_key,0))>0:return
  actor.ult-=cost
  data=data.duplicate()
  data["ex"]=true
  kind="uppercut" if kind=="ex_uppercut" else "parry"
 var rites:Array=actor.get("arsenal",[0,0,0])
 if kind=="melee":
  var stage:int=int(data.get("stage",1))
  if stage<1 or stage>3:return
  if stage>1 and (int(actor.get("last_swing",0))!=stage-1 or float(actor.get("followup_left",0))<=0):return
  if not cooldown(actor,"melee",0.58):return
  actor["last_swing"]=stage
  actor["followup_left"]=1.15 if stage<3 else 0.0
  actor.anim=1.05 if stage==3 else 0.82
  if stage==3:actor.cooldowns["melee"]=1.23
  actor.combo=stage
  actions.append({"owner":id,"kind":"melee","stage":stage,"epoch":int(actor.get("attack_epoch",0)),"delay":0.45 if stage==3 else 0.25,"point":point,"direction":forward,"amount":[12,14,24][stage-1]*stats.power})
 elif kind=="parry":
  if not cooldown(actor,"parry",1.2):return
  actor.parry=0.42 if powered else 0.22
  if powered:actor["shield"]=minf(30,float(actor.get("shield",0))+25);actor["shield_left"]=3.0
 elif kind=="uppercut":
  if not cooldown(actor,"uppercut",6):return
  if id==local_id:player.velocity.y=12+(3 if rites[1]==0 else 0)+(3 if powered else 0)
  actions.append({"owner":id,"kind":"uppercut","ex":powered,"delay":0.0,"point":point,"direction":forward,"amount":(26 if powered else 18)*stats.power})
 elif kind=="q":
  if not cooldown(actor,"q",2.5):return
  var direction:Vector3=data.get("direction",forward)
  if not direction.is_finite() or direction.length()<0.1:return
  direction=direction.normalized()
  var power:=clampf(float(data.get("power",0)),0,1)
  actions.append({"owner":id,"kind":"q","delay":0.0,"point":point,"direction":direction,"length":6+power*8+(3 if rites[0]==0 else -2),"amount":(12+power*28)*stats.power*(0.85 if rites[0]==0 else 1.15)})
 elif kind=="ember_set":
  if not cooldown(actor,"ember_set",8):return
  var target:Vector3=data.get("target",point)
  if not target.is_finite():return
  actor["ember_target"]=point+(target-point).limit_length(16)
  actor["ember_age"]=5.0
 elif kind=="ember":
  if float(actor.get("ember_age",0))<=0:return
  var delta:Vector3=actor.ember_target-point
  actor.ember_age=0
  actions.append({"owner":id,"kind":"q","delay":0.0,"point":point,"direction":delta.normalized(),"length":delta.length(),"amount":20*stats.power})
 elif kind=="ultimate":
  if actor.ult<100:return
  actor.ult=0
  actions.append({"owner":id,"kind":"ultimate","delay":1.15,"point":actor.body.position,"direction":forward,"amount":40*stats.power})
 else:return
 for action in actions:
  if action.owner==id and not action.has("epoch"):action["epoch"]=int(actor.get("attack_epoch",0))
 if multiplayer.has_multiplayer_peer():visual_action.rpc(id,kind,data)
 if powered:energy_effect.rpc(id,kind)

@rpc("authority","call_local","reliable")
func energy_effect(id:int,kind:String) -> void:
 if not actors.has(id):return
 abilities.spawn_skill_effect("uppercut" if kind=="uppercut" else "ember",actors[id].body.position)
 preload("res://game/pixel_sparks.gd").burst(self,actors[id].body.position+Vector3.UP,Color("81dfff"),32,5)
 if id==local_id and kind=="parry":
  abilities.parry_left=0.42
  abilities.parry_pose_left=0.42
 if id==local_id and kind=="uppercut":player.velocity.y=15+(3 if my_arsenal[1]==0 else 0)

@rpc("any_peer","call_remote","reliable")
func arsenal_request(value:Array) -> void:
 if multiplayer.is_server():set_arsenal(multiplayer.get_remote_sender_id(),value)

func set_arsenal(id:int,value:Array) -> void:
 if phase!="preparation" or not actors.has(id) or actors[id].ready or not ARSENAL.valid(value):return
 actors[id]["arsenal"]=value.duplicate()

func choose_arsenal() -> void:
 for index in range(3):my_arsenal[index]=arsenal_pickers[index].selected
 if multiplayer.is_server():set_arsenal(local_id,my_arsenal)
 else:arsenal_request.rpc_id(1,my_arsenal)

@rpc("authority","call_local","reliable")
func visual_action(id:int,kind:String,data:Dictionary) -> void:
 if not actors.has(id) or id==local_id:return
 var actor:Dictionary=actors[id]
 if kind=="melee":actor.anim=0.82
 if kind=="q" or kind=="ember":
  var direction:Vector3=data.get("direction",actor_forward(actor))
  var length_value:float=6+clampf(float(data.get("power",0)),0,1)*8
  if kind=="q":length_value+=3 if actor.get("arsenal",[0,0,0])[0]==0 else -2
  if kind=="ember" and actor.has("ember_target"):
   direction=actor.ember_target-(actor.body.position+Vector3.UP)
   length_value=direction.length()
  var trail:=Node3D.new()
  trail.set_script(preload("res://game/slash_fx.gd"))
  add_child(trail)
  trail.begin(direction.normalized(),float(data.get("power",0)))
  for step in range(13):trail.append_point(actor.body.position+Vector3.UP+direction.normalized()*length_value*step/12.0)
  trail.finish()
  get_tree().create_timer(1.5,false).timeout.connect(trail.queue_free)
 if kind=="ember_set":
  actor["ember_target"]=data.get("target",actor.body.position)
  if is_instance_valid(actor.get("ember_fx")):actor.ember_fx.queue_free()
  actor["ember_fx"]=abilities.spawn_skill_effect("ember",actor.ember_target)
  var marker:Node3D=actor.ember_fx
  get_tree().create_timer(5.0,false).timeout.connect(func():if is_instance_valid(marker):marker.queue_free())
 if kind=="ember" and is_instance_valid(actor.get("ember_fx")):actor.ember_fx.queue_free()
 if kind in ["uppercut","ultimate"]:
  var effect:Node3D=abilities.spawn_skill_effect(kind,actor.body.position)
  if kind=="ultimate":get_tree().create_timer(1.15,false).timeout.connect(func():if is_instance_valid(effect):effect.detonate())
 if kind=="parry":
  var effect:=Node3D.new()
  effect.set_script(preload("res://game/parry_fx.gd"))
  effect.arena=self
  effect.position=actor.body.position+Vector3.UP
  effect.rotation.y=actor.body.rotation.y
  add_child(effect)

func opponents(a:Dictionary,b:Dictionary) -> bool:
 if a.id==b.id:return false
 if phase=="preparation":return not (a.bot and b.bot)
 return a.team!=b.team

func resolve_action(action:Dictionary) -> void:
 if phase not in ["preparation","battle"]:return
 if not actors.has(action.owner) or not actors[action.owner].alive:return
 var owner:Dictionary=actors[action.owner]
 if int(action.get("epoch",owner.get("attack_epoch",0)))!=int(owner.get("attack_epoch",0)):return
 var point:Vector3=owner.body.position+Vector3.UP if action.kind in ["melee","uppercut"] else action.point
 for target in actors.values():
  if not target.alive or not opponents(owner,target):continue
  var center:Vector3=target.body.position+Vector3.UP
  var delta:Vector3=center-point
  var hit:=false
  if action.kind=="ultimate":hit=delta.length()<6
  elif action.kind=="q":
   var end:Vector3=point+action.direction*action.length
   var obstacle:=ray(point,end)
   if not obstacle.is_empty() and obstacle.collider is StaticBody3D:end=obstacle.position
   hit=Geometry3D.get_closest_point_to_segment(center,point,end).distance_to(center)<1.3
  else:hit=delta.length()<(3.4 if int(action.get("stage",0))==3 else 3.1) and delta.normalized().dot(action.direction)>-0.1
  if hit:
   var obstruction:=ray(point,center)
   if obstruction.is_empty() or obstruction.collider==target.body:
    var health_before:float=target.hp
    var percent_before:float=float(target.get("percent",0))
    damage_actor(target.id,action.amount,action.owner,point)
    if (target.hp<health_before or float(target.get("percent",0))>percent_before) and target.alive:
     var stage:int=int(action.get("stage",0))
     var opener:bool=action.kind=="melee" and stage in [1,2]
     var finisher:bool=action.kind=="ultimate" or (action.kind=="melee" and stage==3)
     var strength:float=1.8 if opener else (14 if finisher else (10 if action.kind=="q" else 6.5))
     if not opener:strength*=1+0.8*(1-target.hp/target.maxhp)
     if stock_mode and not opener:strength=5+float(target.get("percent",0))*0.13+(3 if finisher else 0)
     var impulse:=Vector3(delta.x,0,delta.z).normalized()*strength
     impulse.y=1.0 if opener else (10 if action.kind=="uppercut" else (12 if action.kind=="ultimate" else 6.0))
     if action.kind=="uppercut":
      if owner.get("arsenal",[0,0,0])[1]==0:impulse.y+=3
      else:impulse+=Vector3(delta.x,0,delta.z).normalized()*3
      if bool(action.get("ex",false)):impulse.y+=3
     var duration:float=(0.72 if stage==1 else 0.28) if opener else (0.5 if finisher else 0.4)
     if float(target.get("escape",0))>0:duration=0
     else:
      if float(target.get("stun",0))<=0:target["stun_budget"]=0.0
      duration=minf(duration,maxf(0,1.3-float(target.get("stun_budget",0))))
      target["stun_budget"]=float(target.get("stun_budget",0))+duration
     if finisher or duration<=0:target["escape_after"]=0.65
     target["attack_epoch"]=int(target.get("attack_epoch",0))+1
     target["last_swing"]=0
     target["followup_left"]=0.0
     target.anim=0
     combat_impact.rpc(target.id,impulse,duration)
     var count:int=int(owner.get("hit_count",0))+1 if float(owner.get("combo_display",0))>0 and int(owner.get("hit_target",0))==target.id else 1
     combo_confirmed.rpc(owner.id,target.id,count,finisher)

@rpc("authority","call_local","reliable")
func combo_confirmed(id:int,victim:int,count:int,finisher:bool) -> void:
 if not actors.has(id):return
 if actors.has(victim):feel.impact(actors[victim].body.position+Vector3.UP,finisher,id==local_id or victim==local_id)
 actors[id]["hit_count"]=count
 actors[id]["hit_target"]=victim
 actors[id]["combo_display"]=1.1
 actors[id]["finisher"]=finisher

@rpc("authority","call_local","reliable")
func combat_impact(id:int,impulse:Vector3,duration:float=0.32) -> void:
 if not actors.has(id):return
 var actor:Dictionary=actors[id]
 actor["stun"]=maxf(float(actor.get("stun",0)),duration)
 actor["combo_display"]=0.0
 actor.anim=0
 if actor.visual.has_method("react_to_hit"):actor.visual.react_to_hit(maxf(0.12,duration))
 preload("res://game/pixel_sparks.gd").burst(self,actor.body.position+Vector3.UP,Color("ffb16c"),14,3)
 if id==local_id:
  stop_local_actions()
  hitstun=maxf(hitstun,duration)
  player.velocity=impulse
 elif multiplayer.is_server():actor.body.velocity=impulse

func actor_forward(actor:Dictionary) -> Vector3:
 return -model.global_basis.z if actor.id==local_id else -actor.body.global_basis.z

func damage_actor(id:int,amount:float,attacker:int=0,source:Vector3=Vector3.ZERO) -> void:
 if not actors.has(id) or not actors[id].alive:return
 if stock_mode and float(actors[id].get("protection",0))>0:return
 var actor:Dictionary=actors[id]
 if attacker!=0 and actors.has(attacker) and not opponents(actors[attacker],actor):return
 if attacker!=0 and actor.parry>0:
  var delta:Vector3=source-(actor.body.position+Vector3.UP)
  delta.y=0
  if delta.length()<0.1 or delta.normalized().dot(actor_forward(actor))>0.15:
   actor.parry=0
   if actor.get("arsenal",[0,0,0])[2]==0:actor.ult=minf(100,actor.ult+8)
   elif stock_mode:actor["percent"]=maxf(0,float(actor.get("percent",0))-8)
   else:actor.hp=minf(actor.maxhp,actor.hp+8)
   if multiplayer.has_multiplayer_peer():parry_success.rpc(id)
   if actors.has(attacker):
    var counter:Dictionary=actors[attacker]
    counter["attack_epoch"]=int(counter.get("attack_epoch",0))+1
    counter["last_swing"]=0
    counter["followup_left"]=0.0
    counter["combo_display"]=0.0
    var recoil:Vector3=(counter.body.position-actor.body.position).normalized()*3+Vector3.UP*2
    combat_impact.rpc(attacker,recoil,0.25)
   return
 var absorbed:=minf(float(actor.get("shield",0)),amount)
 actor["shield"]=float(actor.get("shield",0))-absorbed
 if stock_mode:
  var dealt:=maxf(0,amount-absorbed)
  actor["percent"]=float(actor.get("percent",0))+dealt
  orb_capture.erase(id)
  if attacker!=0 and actors.has(attacker):actors[attacker].ult=minf(100,actors[attacker].ult+dealt*0.75)
  return
 var actual:=minf(actor.hp,maxf(0,amount-absorbed))
 actor.hp=maxf(0,actor.hp-actual)
 orb_capture.erase(id)
 if attacker!=0 and actors.has(attacker):actors[attacker].ult=minf(100,actors[attacker].ult+actual*0.75*RULES.stats(actors[attacker].build).focus)
 if actor.hp<=0:eliminate(id)

@rpc("authority","call_local","reliable")
func parry_success(id:int) -> void:
 if not actors.has(id):return
 if id==local_id:
  stamina=minf(3,stamina+1)
  feel.sound("ready",player.position)
  abilities.parry_left=0
  abilities.parry_pose_left=0.12
 var effect:=Node3D.new()
 effect.set_script(preload("res://game/parry_fx.gd"))
 effect.arena=self
 effect.success=true
 effect.position=actors[id].body.position+Vector3.UP
 add_child(effect)

func eliminate(id:int) -> void:
 if not actors.has(id):return
 var actor:Dictionary=actors[id]
 if phase in ["preparation","elevator"]:
  actor.hp=actor.maxhp
  actor.body.position=spawn_center(actor.team,elevator.position.y)
  actor.body.velocity=Vector3.ZERO
  return
 actor.alive=false
 actor.hp=0
 actor.buff=0
 if id==local_id:stop_local_actions()
 actor.body.hide()
 actor.body.collision_layer=0
 actor.body.collision_mask=0

func update_enemies(dt:float) -> void:
 for actor in actors.values():
  if actor.id==local_id:continue
  if not multiplayer.is_server():actor.anim=maxf(0,actor.anim-dt)
  if not actor.alive:continue
  if not multiplayer.is_server() and actor.has("net_p"):
   actor.body.position=actor.body.position.lerp(actor.net_p,1-exp(-dt*18))
  if multiplayer.is_server() and actor.bot and phase in ["preparation","elevator","battle"]:bot_step(actor,dt)
  var pose:Dictionary=actor.get("pose",{})
  actor.visual.crouching=bool(pose.get("crouch",false))
  actor.visual.climbing=bool(pose.get("mantle",false))
  actor.visual.protecting=actor.parry>0
  actor.visual.animate(dt,actor.body.velocity,bool(pose.get("ground",actor.body.is_on_floor())),bool(pose.get("slide",false)),bool(pose.get("dash",false)),actor.anim,actor.combo)
  actor.label.text="%s\n%d / %d" % [actor.name,int(actor.hp),int(actor.maxhp)]
  actor.label.modulate=Color("8bdcff") if actor.team==0 else Color("ffad91")

func bot_step(actor:Dictionary,dt:float) -> void:
 if phase in ["preparation","elevator"] or float(actor.get("stun",0))>0:
  coast_body(actor.body,dt)
  if phase!="battle":constrain_to_spawn(actor.body,actor.team)
  actor["pose"]={"ground":actor.body.is_on_floor()}
  return
 var target:Dictionary={}
 var best:=INF
 for candidate in actors.values():
  if not opponents(actor,candidate) or not candidate.alive:continue
  var distance:float=actor.body.position.distance_to(candidate.body.position)
  if distance<best:best=distance;target=candidate
 if target.is_empty():return
 var delta:Vector3=target.body.position-actor.body.position
 if target.body.position.y>2.8 and actor.body.position.y<2.9 and absf(target.body.position.z)>16:
  var side:float=signf(target.body.position.z)
  var ramp_x:=0.0
  var best_route:=INF
  for candidate_x in [-20.0,0.0,20.0]:
   var entry:=Vector3(candidate_x,0,side*7)
   var exit_point:=Vector3(candidate_x,3.2,side*18)
   var cost:float=actor.body.position.distance_to(entry)+exit_point.distance_to(target.body.position)
   if cost<best_route:best_route=cost;ramp_x=candidate_x
  var aligned:bool=absf(actor.body.position.x-ramp_x)<3.0 and actor.body.position.z*side>6
  delta=Vector3(ramp_x,3.2 if aligned else 0,side*(18 if aligned else 7))-actor.body.position
 delta.y=0
 var direction:=delta.normalized()
 actor.body.rotation.y=atan2(-direction.x,-direction.z)
 var obstacle:=ray(actor.body.position+Vector3.UP,actor.body.position+Vector3.UP+direction*1.4)
 if not obstacle.is_empty() and obstacle.collider is StaticBody3D and obstacle.normal.y<0.65:direction=Vector3(-direction.z,0,direction.x)
 var speed:float=5.0*RULES.stats(actor.build).speed if best>2.2 else 0.0
 actor.body.velocity.x=move_toward(actor.body.velocity.x,direction.x*speed,dt*24)
 actor.body.velocity.z=move_toward(actor.body.velocity.z,direction.z*speed,dt*24)
 actor.body.velocity.y-=25*dt
 actor.body.move_and_slide()
 actor["pose"]={"ground":actor.body.is_on_floor()}
 if best<2.8:server_action(actor.id,"melee",{"stage":int(actor.get("last_swing",0))+1 if int(actor.get("last_swing",0)) in [1,2] and float(actor.get("followup_left",0))>0 else 1})
 if phase=="battle" and best<3 and actor.anim<=0 and float(actor.cooldowns.get("uppercut",0))<=0:server_action(actor.id,"uppercut",{})
 if phase=="battle" and actor.ult>=100:server_action(actor.id,"ultimate",{})

func coast_body(body:CharacterBody3D,dt:float) -> void:
 body.velocity.x=move_toward(body.velocity.x,0,dt*3)
 body.velocity.z=move_toward(body.velocity.z,0,dt*3)
 body.velocity.y-=25*dt
 body.move_and_slide()

@rpc("any_peer","call_remote","unreliable_ordered",1)
func submit_motion(point:Vector3,velocity:Vector3,facing:float,pose:Dictionary) -> void:
 if not multiplayer.is_server():return
 var id:=multiplayer.get_remote_sender_id()
 if not actors.has(id) or phase not in ["preparation","elevator","battle"] or not actors[id].alive:return
 if not point.is_finite() or not velocity.is_finite() or not is_finite(facing):return
 var actor:Dictionary=actors[id]
 var maximum:=7.0 if float(actor.cooldowns.get("q",0))>2.0 else 3.6
 var delta:Vector3=(point-actor.body.position).limit_length(maximum)
 actor.body.move_and_collide(delta)
 actor.body.velocity=velocity.limit_length(65)
 actor.body.rotation.y=facing
 if phase in ["preparation","elevator"]:constrain_to_spawn(actor.body,actor.team)
 actor["pose"]={}
 for key in ["ground","crouch","mantle","slide","dash"]:actor.pose[key]=bool(pose.get(key,false))

func local_pose() -> Dictionary:
 return {"ground":player.is_on_floor(),"crouch":crouching,"mantle":climbing,"slide":slide_time>0,"dash":dash_time>0}

func _physics_process(dt:float) -> void:
 if hitstun>0:jump_buffer=0
 energy_note=maxf(0,energy_note-dt)
 hitstun=maxf(0,hitstun-dt)
 if not multiplayer.is_server():
  if phase=="elevator":
   phase_time+=dt
   move_lifts(24*(1-smoothstep(0,5,phase_time)),true)
  for actor in actors.values():
   actor["combo_display"]=maxf(0,float(actor.get("combo_display",0))-dt)
   actor["stun"]=maxf(0,float(actor.get("stun",0))-dt)
 if not is_instance_valid(abilities):return
 if not actors.has(local_id) and not connection_failed:
  connection_wait+=dt
  if connection_wait>15:failed()
 if actors.has(local_id):
  actors[local_id]["pose"]=local_pose()
  movement_multiplier=RULES.stats(actors[local_id].build).speed
  if actors[local_id].buff>0:stamina=minf(3,stamina+dt*0.75)
 super._physics_process(dt)
 update_gates()
 if phase in ["preparation","elevator"] and actors.has(local_id):constrain_to_spawn(player,actors[local_id].team)
 if actors.has(local_id):
  combat_hud.health=actors[local_id].hp
  combat_hud.max_health=actors[local_id].maxhp
  ultimate_charge=actors[local_id].ult
  combat_hud.combo_hits=int(actors[local_id].get("hit_count",0)) if float(actors[local_id].get("combo_display",0))>0 else 0
  combat_hud.combo_finisher=bool(actors[local_id].get("finisher",false))
  combat_hud.energy_mode=true
  combat_hud.shield=float(actors[local_id].get("shield",0))
  if not actors[local_id].alive:
   for actor in actors.values():
    if actor.alive:
     pivot.position=actor.body.position+Vector3.UP*2
     break
 if multiplayer.is_server() and not connection_failed:server_tick(dt)
 network_timer-=dt
 if network_timer<=0 and not connection_failed:
  network_timer=0.066
  if multiplayer.is_server():snapshot.rpc(var_to_bytes(pack_state()).compress(FileAccess.COMPRESSION_GZIP))
  elif actors.has(local_id):submit_motion.rpc_id(1,player.position,player.velocity,model.rotation.y,local_pose())
 update_hud()

func server_tick(dt:float) -> void:
 phase_time+=dt
 for actor in actors.values():
  actor["shield_left"]=maxf(0,float(actor.get("shield_left",0))-dt)
  if actor.shield_left<=0:actor["shield"]=0.0
  actor["followup_left"]=maxf(0,float(actor.get("followup_left",0))-dt)
  actor["combo_display"]=maxf(0,float(actor.get("combo_display",0))-dt)
  if float(actor.get("stun",0))<=0:
   if float(actor.get("escape_after",0))>0:
    actor["escape"]=float(actor.escape_after)
    actor["escape_after"]=0.0
   else:actor["escape"]=maxf(0,float(actor.get("escape",0))-dt)
  actor["stun"]=maxf(0,float(actor.get("stun",0))-dt)
  actor.anim=maxf(0,actor.anim-dt)
  for key in actor.cooldowns.keys():actor.cooldowns[key]=maxf(0,actor.cooldowns[key]-dt)
  actor.parry=maxf(0,actor.parry-dt)
  actor.buff=maxf(0,actor.buff-dt)
  actor["ember_age"]=maxf(0,float(actor.get("ember_age",0))-dt)
  if actor.alive and actor.body.position.y < -8:eliminate(actor.id)
  if phase=="preparation" and actor.body.position.y<18:eliminate(actor.id)
 for i in range(actions.size()-1,-1,-1):
  actions[i].delay-=dt
  if actions[i].delay<=0:resolve_action(actions[i]);actions.remove_at(i)
 if phase=="preparation":
  if fill_bots or human_count()==team_size*2:
   preparation_left=maxf(0,preparation_left-dt)
   if preparation_left<=0:
    for actor in actors.values():actor.ready=true
    start_elevator()
 elif phase=="elevator":
  var height:=24*(1-smoothstep(0,5,phase_time))
  move_lifts(height,true)
  update_gates()
  if phase_time>=5:start_round()
 elif phase=="battle":
  round_time+=dt
  zone_radius=1000.0 if stock_mode else (START_RADIUS if round_time<35 else maxf(0,START_RADIUS*(1-(round_time-35)/105.0)))
  zone.show()
  if stock_mode:zone.hide()
  zone.scale=Vector3(maxf(0.01,zone_radius),1,maxf(0.01,zone_radius))
  # A thin ground ring keeps the arena readable from a steep camera.
  for actor in actors.values():
   if actor.alive and Vector2(actor.body.position.x,actor.body.position.z).length()>zone_radius:
    damage_actor(actor.id,dt*minf(12,4+round_time/35))
  tick_pickups(dt)
  var living:=[0,0]
  for actor in actors.values():
   if actor.alive or (stock_mode and int(actor.get("stocks",0))>0):living[actor.team]+=1
  if living[0]==0 or living[1]==0:
   var winner:=-1 if living[0]==0 and living[1]==0 else (0 if living[1]==0 else 1)
   finish_round(winner)
 elif phase=="round_end" and phase_time>=5:
  if scores[0]>=3 or scores[1]>=3:
   phase="match_end"
   network_message="Equipo %s gana la partida · Tab libera el cursor" % ("AZUL" if scores[0]>=3 else "ROJO")
   Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
  else:
   round_number+=1
   for actor in actors.values():
    actor.alive=true
    actor.body.show()
    actor.body.collision_layer=1 if actor.id==local_id else 2
    actor.body.collision_mask=1
   begin_descent()

func tick_pickups(dt:float) -> void:
 for pickup in pickups:
  pickup.timer-=dt
  if pickup.timer<=0:pickup.available=true
  pickup.node.visible=pickup.available
  pickup.node.rotation.y+=dt*2
  if not pickup.available:continue
  for actor in actors.values():
   if not actor.alive or actor.body.position.distance_to(pickup.node.position)>1.4:continue
   if pickup.kind=="heal":
    if actor.hp>=actor.maxhp:continue
    actor.hp=minf(actor.maxhp,actor.hp+25)
   else:
    if actor.ult>=100:continue
    actor.ult=minf(100,actor.ult+15)
   pickup.available=false
   pickup.timer=20 if pickup.kind=="heal" else 25
   break
 orb_available=round_time>=25 and not orb_taken
 orb.visible=orb_available
 orb.rotation.y+=dt*2
 if not orb_available:return
 for actor in actors.values():
  if not actor.alive:continue
  var near:=Vector2(actor.body.position.x,actor.body.position.z).length()<1.5
  var contested:=false
  for opponent in actors.values():
   if opponent.alive and opponent.team!=actor.team and Vector2(opponent.body.position.x,opponent.body.position.z).length()<3:contested=true
  if near and not contested:
   orb_capture[actor.id]=float(orb_capture.get(actor.id,0))+dt
   if orb_capture[actor.id]>=2:
    actor.buff=12
    orb_taken=true
    orb_available=false
    orb.hide()
    break
  else:orb_capture.erase(actor.id)

func finish_round(winner:int) -> void:
 phase="round_end"
 phase_time=0
 actions.clear()
 if winner>=0:scores[winner]+=1
 network_message="Ronda empatada" if winner<0 else "Equipo %s gana la ronda" % ("AZUL" if winner==0 else "ROJO")

func pack_state() -> Dictionary:
 var roster_state:Array=[]
 for actor in actors.values():
  roster_state.append({"id":actor.id,"team":actor.team,"bot":actor.bot,"name":actor.name,"p":actor.body.position,"v":actor.body.velocity,"yaw":actor.body.rotation.y if actor.id!=local_id else model.rotation.y,"build":actor.build,"hp":actor.hp,"maxhp":actor.maxhp,"alive":actor.alive,"ready":actor.ready,"ult":actor.ult,"buff":actor.buff,"anim":actor.anim,"combo":actor.combo,"pose":actor.get("pose",{}),"parry":actor.parry,"arsenal":actor.get("arsenal",[0,0,0]),"shield":float(actor.get("shield",0))})
 var items:Array=[]
 for pickup in pickups:items.append(pickup.available)
 return {"phase":phase,"time":phase_time,"round_time":round_time,"prep":preparation_left,"fill":fill_bots,"size":team_size,"round":round_number,"scores":scores,"actors":roster_state,"zone":zone_radius,"lift":elevator.position.y,"orb":orb_available,"capture":orb_capture,"items":items,"message":network_message}

@rpc("authority","call_remote","unreliable_ordered",2)
func snapshot(payload:PackedByteArray) -> void:
 var state:Dictionary=bytes_to_var(payload.decompress_dynamic(65536,FileAccess.COMPRESSION_GZIP))
 var previous:=phase
 phase=state.phase
 if phase=="match_end" and previous!=phase:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 phase_time=maxf(phase_time,state.time) if phase=="elevator" and previous==phase else state.time
 round_time=state.round_time
 preparation_left=state.prep
 fill_bots=state.fill
 team_size=state.size
 round_number=state.round
 scores=state.scores
 zone_radius=state.zone
 network_message=state.message
 move_lifts(24*(1-smoothstep(0,5,phase_time)) if phase=="elevator" else state.lift,phase=="elevator" and previous==phase)
 update_gates()
 zone.visible=phase=="battle"
 zone.scale=Vector3(maxf(0.01,zone_radius),1,maxf(0.01,zone_radius))
 orb.visible=state.orb
 orb_capture=state.capture
 for i in range(pickups.size()):pickups[i].node.visible=state.items[i]
 var present:Array=[]
 for data in state.actors:
  var id:int=data.id
  present.append(id)
  if not actors.has(id):add_actor(id,data.team,data.bot,data.name)
  var actor:Dictionary=actors[id]
  var was_alive:bool=actor.alive
  for key in ["team","build","hp","maxhp","alive","ready","ult","buff","anim","combo","pose","parry","arsenal","shield"]:actor[key]=data[key]
  actor["net_p"]=data.p
  if (previous!=phase and not (previous=="elevator" and phase=="battle" and id==local_id)) or not data.alive or actor.body.position.distance_to(data.p)>5:
   actor.body.position=data.p
  if id!=local_id:actor.body.velocity=data.v
  if id!=local_id:actor.body.rotation.y=data.yaw
  actor.body.visible=data.alive
  actor.body.collision_layer=(1 if id==local_id else 2) if data.alive else 0
  actor.body.collision_mask=1 if data.alive else 0
  if id==local_id and ((not was_alive and data.alive) or (previous!=phase and (phase=="preparation" or (phase=="elevator" and previous!="preparation")))):reset_local_combat()
  if id==local_id and ((was_alive and not data.alive) or (previous!=phase and phase=="elevator" and previous=="preparation")):stop_local_actions()
  if id==local_id:
   selected_ready=data.ready
   my_arsenal=data.arsenal.duplicate()
   for index in range(arsenal_pickers.size()):arsenal_pickers[index].select(int(my_arsenal[index]))
 for id in actors.keys():
  if not present.has(id):remove_actor(id)

func make_hud() -> void:
 var canvas:=CanvasLayer.new()
 canvas.layer=3
 add_child(canvas)
 var root:=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 canvas.add_child(root)
 var bars:=Control.new()
 bars.set_script(preload("res://game/descent/health_bars.gd"))
 bars.arena=self
 root.add_child(bars)
 header=Label.new()
 header.position=Vector2(24,16)
 header.add_theme_font_size_override("font_size",24)
 root.add_child(header)
 info=Label.new()
 info.position=Vector2(24,50)
 root.add_child(info)
 roster=Label.new()
 roster.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 roster.position=Vector2(-290,20)
 roster.size=Vector2(270,200)
 root.add_child(roster)
 attributes_panel=PanelContainer.new()
 attributes_panel.position=Vector2(24,100)
 attributes_panel.custom_minimum_size=Vector2(300,0)
 var panel_style:=StyleBoxFlat.new()
 panel_style.bg_color=Color(0.035,0.055,0.09,0.96)
 panel_style.border_color=Color("647e9b")
 panel_style.set_border_width_all(1)
 panel_style.content_margin_left=14
 panel_style.content_margin_right=14
 panel_style.content_margin_top=12
 panel_style.content_margin_bottom=12
 attributes_panel.add_theme_stylebox_override("panel",panel_style)
 root.add_child(attributes_panel)
 var column:=VBoxContainer.new()
 column.add_theme_constant_override("separation",6)
 attributes_panel.add_child(column)
 var title:=Label.new()
 title.text="ATRIBUTOS · 6 puntos, máximo 3"
 column.add_child(title)
 for i in range(4):
  var row:=HBoxContainer.new()
  column.add_child(row)
  var minus:=Button.new()
  minus.text="−"
  row.add_child(minus)
  minus.pressed.connect(func():change_attribute(i,-1))
  var label:=Label.new()
  label.custom_minimum_size.x=200
  row.add_child(label)
  attribute_labels.append(label)
  var plus:=Button.new()
  plus.text="+"
  row.add_child(plus)
  plus.pressed.connect(func():change_attribute(i,1))
 var description:=Label.new()
 description.add_theme_font_size_override("font_size",14)
 description.text="Por punto: +6 PV · +3 % daño\n+2 % velocidad · +5 % energía ganada\nObjetivos pasivos. Tab: cursor.\nTiempo agotado: última selección válida."
 column.add_child(description)
 ready_button=Button.new()
 ready_button.text="LISTO PARA DESCENDER"
 column.add_child(ready_button)
 ready_button.pressed.connect(submit_ready)
 var back:=Button.new()
 back.text="Salir al vestíbulo"
 column.add_child(back)
 back.pressed.connect(func():preload("res://game/game_modes.gd").main_menu(get_tree()))
 arsenal_panel=PanelContainer.new()
 arsenal_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 arsenal_panel.position=Vector2(-390,135)
 arsenal_panel.custom_minimum_size=Vector2(370,0)
 arsenal_panel.add_theme_stylebox_override("panel",panel_style.duplicate())
 root.add_child(arsenal_panel)
 var arsenal_column:=VBoxContainer.new()
 arsenal_column.add_theme_constant_override("separation",8)
 arsenal_panel.add_child(arsenal_column)
 var arsenal_title:=Label.new()
 arsenal_title.text="ARSENAL · 3 mejoras"
 arsenal_column.add_child(arsenal_title)
 for index in range(3):
  var caption:=Label.new()
  caption.text=ARSENAL.GROUPS[index]
  arsenal_column.add_child(caption)
  var picker:=OptionButton.new()
  for option in ARSENAL.OPTIONS[index]:picker.add_item(option)
  arsenal_column.add_child(picker)
  arsenal_pickers.append(picker)
  picker.item_selected.connect(func(_choice:int):choose_arsenal())
 var energy_help:=Label.new()
 energy_help.text="ENERGÍA COMPARTIDA · 0–100\nT · Filo EX: 25 · comparte cooldown F\nG · Guardia EX: 50 · comparte V\nX · Definitiva: 100\nGolpea para cargar; EX retrasa la ulti."
 energy_help.add_theme_font_size_override("font_size",14)
 arsenal_column.add_child(energy_help)
 capture_labels=Label.new()
 capture_labels.position=Vector2(24,80)
 root.add_child(capture_labels)

func change_attribute(index:int,delta:int) -> void:
 if selected_ready:return
 var total:=0
 for value in my_build:total+=int(value)
 if my_build[index]+delta<0 or my_build[index]+delta>3 or total+delta>6:return
 my_build[index]=int(my_build[index])+delta
 if actors.has(local_id) and RULES.valid_build(my_build):
  if multiplayer.is_server():set_ready(local_id,my_build,false)
  else:ready_request.rpc_id(1,my_build,false)

func update_hud() -> void:
 if header==null:return
 header.text="EL DESCENSO · %dv%d · %s · %d — %d" % [team_size,team_size,{"preparation":"PREPARACIÓN","elevator":"ASCENSOR","battle":"RONDA %d" % round_number,"round_end":"FIN DE RONDA","match_end":"PARTIDA TERMINADA"}.get(phase,phase),scores[0],scores[1]]
 info.text=network_message if phase in ["round_end","match_end"] or connection_failed else ("Tab libera el cursor · Esc vuelve al vestíbulo" if phase=="preparation" else ("Veneno: radio %.1f m · %.0f s" % [zone_radius,round_time] if phase=="battle" else "Descendiendo…"))
 if phase=="preparation" and not connection_failed:
  info.text=("ELIGE ATRIBUTOS · %d s · Tab: cursor" % ceili(preparation_left)) if fill_bots or human_count()==team_size*2 else "Esperando jugadores · después tendrás 45 s para elegir"
 roster.visible=phase=="preparation"
 if phase=="elevator":info.text="ASCENSOR %s · %.1f s · puedes moverte, saltar y hacer dash" % ["AZUL" if not actors.has(local_id) or actors[local_id].team==0 else "ROJO",maxf(0,5-phase_time)]
 attributes_panel.visible=phase in ["preparation","match_end"] or connection_failed
 arsenal_panel.visible=phase=="preparation" and not connection_failed
 for picker in arsenal_pickers:picker.disabled=selected_ready
 ready_button.disabled=not RULES.valid_build(my_build) or connection_failed or (phase=="match_end" and not multiplayer.is_server())
 ready_button.text=("NUEVA PARTIDA" if multiplayer.is_server() else "ESPERANDO AL ANFITRIÓN") if phase=="match_end" else ("CANCELAR LISTO" if selected_ready else "LISTO PARA DESCENDER")
 for i in range(attribute_labels.size()):attribute_labels[i].text="%s: %d" % [RULES.ATTRIBUTES[i],int(my_build[i])]
 roster.text="JUGADORES\n"
 for actor in actors.values():
  if not actor.bot:roster.text+="%s · %s\n" % [actor.name,"LISTO" if actor.ready else "eligiendo"]
 if actors.has(local_id) and not actors[local_id].alive:capture_labels.text="ELIMINADO · observando hasta la siguiente ronda"
 elif actors.has(local_id) and actors[local_id].buff>0:capture_labels.text="CORAZÓN · regeneración de stamina %.1f s" % actors[local_id].buff
 elif phase=="battle" and Vector2(player.position.x,player.position.z).length()>zone_radius:capture_labels.text="VENENO · vuelve al interior del círculo"
 elif orb.visible:capture_labels.text="ORBE CENTRAL · captura %d%% · mantén el centro libre 2 s" % int(clampf(float(orb_capture.get(local_id,0))/2,0,1)*100)
 else:capture_labels.text=""
 if energy_note>0:capture_labels.text="ENERGÍA INSUFICIENTE · T requiere 25 / G requiere 50"






