extends RefCounted
const PORT=24567
const BUDGET=6
const CAP=3
const ATTRIBUTES=["Vitalidad","Fuerza","Agilidad","Foco"]
static func valid_build(build:Array) -> bool:
 if build.size()!=4:return false
 var total:=0
 for value in build:
  if not (value is int or value is float):return false
  if value!=int(value) or value<0 or value>CAP:return false
  total+=int(value)
 return total==BUDGET
static func stats(build:Array) -> Dictionary:
 return {"health":100.0+float(build[0])*6,"power":1.0+float(build[1])*0.03,"speed":1.0+float(build[2])*0.02,"focus":1.0+float(build[3])*0.05}
static func connect_match(tree:SceneTree,host:bool,address:String,team_size:int,port:int=PORT,fill_bots:bool=true,mode:String="descent") -> Error:
 var peer:=ENetMultiplayerPeer.new()
 var result:Error=peer.create_server(port,6) if host else peer.create_client(address,port)
 if result!=OK:return result
 tree.set_meta("descent_size",clampi(team_size,1,3))
 tree.set_meta("descent_bots",fill_bots)
 tree.set_meta("descent_peer",peer)
 tree.set_meta("game_mode",mode)
 tree.paused=false
 return tree.change_scene_to_file("res://game/convergence/match.tscn" if mode=="convergence" else "res://game/descent/match.tscn")
