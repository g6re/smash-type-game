extends SceneTree
var host:=false
var stage:=0
var elapsed:=0.0
func _initialize() -> void:
 host=OS.get_cmdline_user_args().has("host")
 assert(preload("res://game/descent/rules.gd").connect_match(self,host,"127.0.0.1",1,24685,false)==OK)
func _process(dt:float) -> bool:
 elapsed+=dt
 if elapsed>15:push_error("Energy network timeout");quit(1);return false
 var a:Node=current_scene
 if a==null or not a.get("actors") or not a.actors.has(a.local_id):return false
 if stage==0 and (not host or a.human_count()==2):
  if not host:a.arsenal_request.rpc_id(1,[1,1,1])
  a.submit_ready()
  stage=1
 if host:
  if stage==1 and a.phase=="battle":
   for actor in a.actors.values():
    if actor.id!=1:
     assert(actor.get("arsenal")==[1,1,1],"Loadout accepted before ready")
     actor.ult=100
   stage=2
  if stage==2:
   for actor in a.actors.values():
    if actor.id!=1 and float(actor.get("shield",0))==25:
     assert(actor.ult==50)
     print("PASS HOST remote EX request charged once and created shield")
     stage=3
     elapsed=0
  if stage==3 and elapsed>1:quit()
 else:
  if stage==1 and a.phase=="battle" and a.ultimate_charge>=100:
   a.send_action("ex_guard",{})
   stage=2
  if stage==2 and a.actors[a.local_id].get("shield",0)==25:
   assert(a.actors[a.local_id].ult==50)
   assert(a.my_arsenal==[1,1,1])
   print("PASS CLIENT replicated energy spend, EX shield and arsenal")
   quit()
 return false
