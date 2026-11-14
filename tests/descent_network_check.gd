extends SceneTree
var host:=false
var elapsed:=0.0
var match_node:Node
var stage:=0
var stage_time:=0.0
var client_id:=0
var saw_battle:=false
var sent_parry:=false
var saw_hit_reaction:=false
var lift_started:=-1.0
var lift_start_point:=Vector3.ZERO
var saw_lift_movement:=false
func movement_key(pressed:bool) -> void:
 var event:=InputEventKey.new()
 event.physical_keycode=KEY_D
 event.keycode=KEY_D
 event.pressed=pressed
 Input.parse_input_event(event)
func _initialize() -> void:
 host=OS.get_cmdline_user_args().has("host")
 var result:=preload("res://game/descent/rules.gd").connect_match(self,host,"127.0.0.1",1,24671,false)
 assert(result==OK)
func _process(dt:float) -> bool:
 elapsed+=dt
 if elapsed>23:
  push_error("NETWORK TEST TIMEOUT role="+str(host)+" stage="+str(stage))
  quit(1)
  return false
 match_node=current_scene
 if match_node==null or not match_node.get("actors"):return false
 if not match_node.actors.has(match_node.local_id):return false
 if not host:
  if match_node.phase=="elevator" and lift_started<0:
   lift_started=elapsed
   lift_start_point=match_node.player.position
   movement_key(true)
  if lift_started>=0 and elapsed-lift_started>0.4 and not saw_lift_movement:
   movement_key(false)
   assert(Vector2(match_node.player.position.x-lift_start_point.x,match_node.player.position.z-lift_start_point.z).length()>0.8,"Remote player can move freely during lift descent")
   saw_lift_movement=true
  if match_node.hitstun>0:
   assert(match_node.visual.hurt_left>0)
   saw_hit_reaction=true
  if stage==0:
   match_node.submit_ready()
   stage=1
  if match_node.phase=="battle":
   saw_battle=true
   if not sent_parry:
    match_node.send_action("parry",{})
    sent_parry=true
   if match_node.actors[match_node.local_id].hp<112 and match_node.actors[match_node.local_id].hp>0 and stage==1:
    print("PASS client received host health damage")
    stage=2
  if match_node.phase=="round_end" and stage==2:
   assert(not match_node.actors[match_node.local_id].alive)
   print("PASS client eliminated without respawn")
   stage=3
  if match_node.phase=="battle" and match_node.round_number==2 and stage==3:
   assert(match_node.actors[match_node.local_id].alive)
   assert(match_node.scores[0]==1)
   assert(saw_hit_reaction,"Reliable hit reaction reaches remote victim")
   assert(saw_lift_movement)
   print("PASS CLIENT network phases, health, score and round respawn")
   quit()
  return false
 if stage==0 and match_node.human_count()==2:
  for id in match_node.actors:
   if id>1:client_id=id
  var rules=preload("res://game/descent/rules.gd")
  assert(rules.valid_build([2,2,1,1]))
  assert(not rules.valid_build([6,0,0,0]))
  assert(not rules.valid_build([1,1,1,1]))
  match_node.submit_ready()
  stage=1
 if stage==1 and match_node.phase=="elevator":
  print("PASS all humans ready starts shared elevator")
  stage=2
 if stage==2 and match_node.phase=="battle" and match_node.actors[client_id].parry>0:
  print("PASS client action RPC validated by host")
  match_node.actors[client_id].parry=0
  match_node.damage_actor(client_id,17,1,Vector3.ZERO)
  match_node.combat_impact.rpc(client_id,Vector3(2,1,0),0.72)
  assert(match_node.actors[client_id].hp==95)
  stage=3
  stage_time=elapsed
 if stage==3 and elapsed-stage_time>1:
  match_node.damage_actor(client_id,999,1,Vector3.ZERO)
  assert(not match_node.actors[client_id].alive)
  stage=4
 if stage==4 and match_node.phase=="round_end":
  assert(match_node.scores[0]==1)
  stage=5
 if stage==5 and match_node.phase=="battle" and match_node.round_number==2:
  assert(match_node.actors[client_id].alive)
  stage=6
  stage_time=elapsed
 if stage==6 and elapsed-stage_time>1:
  print("PASS HOST ENet two real processes, ready/elevator, authoritative damage and rounds")
  quit()
 return false

