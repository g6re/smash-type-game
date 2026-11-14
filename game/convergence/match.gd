extends "res://game/descent/match.gd"
var objective_index:=0
var objective_clock:=0.0
var objective_captured:=false
var objective_ring:MeshInstance3D
const OBJECTIVES=[{"name":"NÚCLEO · +35 energía","point":Vector3(0,1,0),"color":Color("77cfff")},{"name":"FUENTE · −25 puntos de daño","point":Vector3(0,1,26),"color":Color("78e0a2")},{"name":"IMPULSO · regeneración 8 s","point":Vector3(0,1,-26),"color":Color("ffc66c")}]

func build_map() -> void:
 enable_grind_rail=false
 spawn=spawn_center(0,24)
 preload("res://game/convergence/layout.gd").build(self)
 for team in range(2):make_lift(team)
 elevator=lifts[0].body

func _ready() -> void:
 stock_mode=true
 super._ready()
 team_size=mini(team_size,2)
 for item in pickups:item.node.queue_free()
 pickups.clear()
 # Keep the interaction controller, but remove the other map's cables.
 ropes.lines.clear()
 for child in ropes.get_children():
  if child is MeshInstance3D:child.queue_free()
 preparation_left=30
 combat_hud.health_mode=false
 objective_ring=MeshInstance3D.new()
 var ring_mesh:=TorusMesh.new()
 ring_mesh.inner_radius=1.95
 ring_mesh.outer_radius=2.05
 objective_ring.mesh=ring_mesh
 objective_ring.scale.y=0.15
 objective_ring.material_override=material(Color("77cfff"),true)
 add_child(objective_ring)
 var column:Node=attributes_panel.get_child(0)
 column.get_child(0).text="CONVERGENCIA · 3 VIDAS"
 for i in range(1,5):column.get_child(i).hide()
 column.get_child(5).text="Porcentaje y expulsiones.\nObjetivos rotativos; sin veneno.\nTab: cursor · listo para comenzar."

func add_actor(id:int,team:int,bot:bool,name_value:String) -> void:
 super.add_actor(id,team,bot,name_value)
 actors[id]["stocks"]=3
 actors[id]["percent"]=0.0
 actors[id]["respawn"]=0.0
 actors[id]["protection"]=0.0

func set_ready(id:int,_build:Array,value:bool) -> void:super.set_ready(id,[2,2,1,1],value)
func change_attribute(_index:int,_delta:int) -> void:pass

func start_round() -> void:
 super.start_round()
 objective_index=0
 objective_clock=0
 objective_captured=false
 for actor in actors.values():
  actor.stocks=3
  actor.percent=0.0
  actor.respawn=0.0
  actor.protection=1.5

func eliminate(id:int) -> void:
 if not actors.has(id):return
 if phase!="battle":super.eliminate(id);return
 var actor:Dictionary=actors[id]
 if not actor.alive:return
 actor.stocks=maxi(0,int(actor.stocks)-1)
 super.eliminate(id)
 actor.respawn=2.5 if actor.stocks>0 else 0.0
 actor["attack_epoch"]=int(actor.get("attack_epoch",0))+1
 orb_capture.erase(id)

func server_tick(dt:float) -> void:
 super.server_tick(dt)
 if phase!="battle":return
 for actor in actors.values():
  actor.protection=maxf(0,actor.protection-dt)
  if actor.alive or actor.stocks<=0:continue
  actor.respawn=maxf(0,actor.respawn-dt)
  if actor.respawn>0:continue
  actor.alive=true
  actor.hp=actor.maxhp
  actor.percent=0.0
  actor.protection=2.0
  actor.buff=0
  actor.ult=maxf(0,actor.ult-25)
  actor.body.position=Vector3(-25 if actor.team==0 else 25,0.2,12 if actor.team==0 else -12)
  actor.body.velocity=Vector3.ZERO
  actor.body.show()
  actor.body.collision_layer=1 if actor.id==local_id else 2
  actor.body.collision_mask=1
  actor["stun"]=0.0
  actor["shield"]=0.0
  actor.cooldowns={}
  if actor.id==local_id:reset_local_combat()

func tick_pickups(dt:float) -> void:
 objective_clock+=dt
 if objective_clock>=33:
  objective_clock=0
  objective_index=(objective_index+1)%OBJECTIVES.size()
  objective_captured=false
  orb_capture.clear()
 var objective:Dictionary=OBJECTIVES[objective_index]
 orb.position=objective.point
 orb_available=objective_clock>=8 and objective_clock<28 and not objective_captured
 orb.visible=orb_available
 if orb.material_override is StandardMaterial3D:
  orb.material_override.albedo_color=objective.color
  orb.material_override.emission=objective.color
 if not orb_available:return
 for actor in actors.values():
  if not actor.alive:continue
  var near:bool=actor.body.position.distance_to(objective.point)<2.3
  var contested:=false
  for other in actors.values():
   if other.alive and other.team!=actor.team and other.body.position.distance_to(objective.point)<4:contested=true
  if near and not contested:
   orb_capture[actor.id]=float(orb_capture.get(actor.id,0))+dt
   if orb_capture[actor.id]>=2:
    if objective_index==0:actor.ult=minf(100,actor.ult+35)
    elif objective_index==1:actor.percent=maxf(0,actor.percent-25)
    else:actor.buff=8
    objective_captured=true
    orb_available=false
    orb.hide()
    orb_capture.clear()
    break
  else:orb_capture.erase(actor.id)

func finish_round(winner:int) -> void:
 super.finish_round(winner)
 phase="match_end"
 network_message="EMPATE" if winner<0 else "EQUIPO %s GANA · sin vidas rivales" % ("AZUL" if winner==0 else "ROJO")
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func pack_state() -> Dictionary:
 var state:=super.pack_state()
 for data in state.actors:
  for key in ["stocks","percent","respawn","protection"]:data[key]=actors[data.id].get(key,0)
 state["objective_index"]=objective_index
 state["objective_clock"]=objective_clock
 state["objective_captured"]=objective_captured
 return state

@rpc("authority","call_remote","unreliable_ordered",2)
func snapshot(payload:PackedByteArray) -> void:
 super.snapshot(payload)
 var state:Dictionary=bytes_to_var(payload.decompress_dynamic(65536,FileAccess.COMPRESSION_GZIP))
 objective_index=state.objective_index
 objective_clock=state.objective_clock
 objective_captured=state.objective_captured
 orb.position=OBJECTIVES[objective_index].point
 orb.material_override=material(OBJECTIVES[objective_index].color,true)
 for data in state.actors:
  for key in ["stocks","percent","respawn","protection"]:actors[data.id][key]=data[key]
 zone.hide()

func update_hud() -> void:
 super.update_hud()
 if header==null:return
 if is_instance_valid(objective_ring):
  objective_ring.visible=phase=="battle" and objective_clock>=3 and objective_clock<28 and not objective_captured
  objective_ring.position=OBJECTIVES[objective_index].point-Vector3.UP*0.95
  objective_ring.material_override.albedo_color=OBJECTIVES[objective_index].color
  objective_ring.material_override.emission=OBJECTIVES[objective_index].color
 combat_hud.health_mode=false
 header.text="CONVERGENCIA · %dv%d · %s" % [team_size,team_size,phase.to_upper()]
 if actors.has(local_id):
  damage=actors[local_id].get("percent",0)
  combat_hud.damage=damage
 for actor in actors.values():
  actor.label.hide()
  actor.label.text="%s · %d vidas · %d%%" % [actor.name,actor.get("stocks",3),int(actor.get("percent",0))]
  if float(actor.get("protection",0))>0:actor.label.text+=" · PROTEGIDO"
  actor.label.modulate=Color("83d9ff") if actor.team==0 else Color("ffa88a")
 if phase=="battle":
  var objective:Dictionary=OBJECTIVES[objective_index]
  info.text="%s · %s" % [objective.name,("ACTIVO · captura 2 s" if orb.visible else ("en %.0f s" % maxf(0,8-objective_clock) if objective_clock<8 else "completado / próximo objetivo"))]
  var remaining:=[0,0]
  for actor in actors.values():remaining[actor.team]+=int(actor.get("stocks",0))
  capture_labels.text="VIDAS AZUL %d — %d ROJO · captura %d%%" % [remaining[0],remaining[1],int(float(orb_capture.get(local_id,0))*50)]
  if actors.has(local_id) and not actors[local_id].alive:
   capture_labels.text="REAPARECES EN %.1f s" % actors[local_id].get("respawn",0) if actors[local_id].get("stocks",0)>0 else "SIN VIDAS · observando"

func bot_step(actor:Dictionary,dt:float) -> void:
 # Existing combat takes over at melee range; otherwise follow the actual bridges.
 if phase!="battle" or float(actor.get("stun",0))>0:super.bot_step(actor,dt);return
 var nearest:=INF
 for other in actors.values():
  if opponents(actor,other) and other.alive:nearest=minf(nearest,actor.body.position.distance_to(other.body.position))
 if nearest<7.0:super.bot_step(actor,dt);return
 var graph:Array=preload("res://game/convergence/layout.gd").POINTS
 var from:int=int(actor.get("nav_node",-1))
 var best:=INF
 if from<0:
  for i in range(graph.size()):
   var distance:float=actor.body.position.distance_to(graph[i])
   if distance<best:best=distance;from=i
  actor["nav_node"]=from
 var destination:Vector3=OBJECTIVES[objective_index].point if orb_available else Vector3.ZERO
 var goal:=0
 for i in range(graph.size()):
  if graph[i].distance_to(destination)<2:goal=i
 var next:int=goal if from==0 else 0
 if from==goal:next=goal
 var target:Vector3=graph[next]
 if actor.body.position.distance_to(target)<1.5:actor["nav_node"]=next
 var direction:Vector3=target-actor.body.position
 direction.y=0
 actor.body.velocity=direction.normalized()*5+Vector3.UP*(actor.body.velocity.y-25*dt)
 actor.body.rotation.y=atan2(-direction.x,-direction.z)
 actor.body.move_and_slide()
 actor["pose"]={"ground":actor.body.is_on_floor()}
