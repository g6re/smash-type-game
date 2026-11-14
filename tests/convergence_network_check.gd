extends SceneTree
var host:=false
var elapsed:=0.0
var stage:=0
var victim:=0
func _initialize() -> void:
 host=OS.get_cmdline_user_args().has("host")
 assert(preload("res://game/descent/rules.gd").connect_match(self,host,"127.0.0.1",1,24692,false,"convergence")==OK)
func _process(dt:float) -> bool:
 elapsed+=dt
 if host and stage==2 and elapsed>12:
  print("PASS host network Convergence authoritative damage and stock loss")
  quit()
  return false
 if elapsed>20:push_error("Convergence network timeout stage %d" % stage);quit(1);return false
 var arena:Node=current_scene
 if arena==null or arena.human_count()<2:return false
 if host:
  if stage==0:
   for actor in arena.actors.values():actor.ready=true
   arena.check_ready()
   stage=1
  elif stage==1 and arena.phase=="battle":
   for actor in arena.actors.values():
    if actor.id!=1:victim=actor.id
   arena.actors[victim].protection=0
   arena.damage_actor(victim,85,1,Vector3.ZERO)
   arena.eliminate(victim)
   stage=2
  elif stage==2 and elapsed>12:
   print("PASS host network Convergence authoritative damage and stock loss")
   quit()
 else:
  if arena.actors.has(arena.local_id):
   var actor:Dictionary=arena.actors[arena.local_id]
   if actor.get("stocks",3)==2 and not actor.alive:stage=1
   if stage==1 and actor.alive and actor.get("percent",-1)==0:
    assert(arena.phase=="battle" and arena.stock_mode)
    assert(arena.objective_clock>0)
    print("PASS client received stocks, percentage, respawn and rotating objective state")
    quit()
 return false
