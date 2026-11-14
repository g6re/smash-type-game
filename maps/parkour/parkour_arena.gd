extends "res://game/arena.gd"
var ropes:Node3D
var route_points:Array[Vector3]=[Vector3(10,0,6),Vector3(10,0,-6),Vector3(0,2.4,-10),Vector3(-10,0,-6),Vector3(-10,0,6),Vector3(0,0,10)]
var route_index:=0
var lap_time:=0.0
var best_lap:=0.0
var lap_running:=false
var lap_label:Label3D
var route_markers:Array[MeshInstance3D]=[]

func deck(center:Vector3,width:float,depth:float,color:Color) -> void:
 platform(Vector3(width,0.6,depth),center-Vector3.UP*0.3,color)
 for x in [-width/2+0.08,width/2-0.08]:
  box(self,Vector3(0.07,0.025,depth),center+Vector3(x,0.02,0),Color("7ca5ab"))

func signpost(point:Vector3,text:String,color:Color) -> Label3D:
 var sign:=Label3D.new()
 add_child(sign)
 sign.position=point
 sign.text=text
 sign.modulate=color
 sign.font_size=30
 sign.pixel_size=0.009
 sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 return sign

func build_map() -> void:
 grind_extent=27.0
 spawn=Vector3(0,0.15,4)
 deck(Vector3.ZERO,12,12,Color("344954"))
 deck(Vector3(0,0,9),16,6,Color("344954"))
 # Outer circuits create room to disengage and re-enter from either flank.
 for side in [-1,1]:
  deck(Vector3(side*11,0,11),8,4,Color("365963"))
  deck(Vector3(side*19,0,7),10,8,Color("365963"))
  deck(Vector3(side*19,1.2,-2),10,10,Color("55717a"))
  deck(Vector3(side*19,2.4,-11),10,8,Color("67586c"))
  deck(Vector3(side*13,2.4,-12),4,4,Color("55717a"))
  platform(Vector3(0.5,4,18),Vector3(side*24.3,3.2,-2),Color("587782"))
  for z in [-8,0,6]:box(self,Vector3(0.03,0.10,3),Vector3(side*24.03,2.6,z),Color("4fd8d1"))
  signpost(Vector3(side*19,4,-4),"RUTA EXTERIOR",Color("8be0d9"))
 for side in [-1,1]:
  for z in [-6,6]:
   deck(Vector3(side*10,0,z),4,6,Color("365963"))
   deck(Vector3(side*13,-1.1,z),1.5,5,Color("3e4853"))
  platform(Vector3(0.5,4.5,18),Vector3(side*12.3,2.25,0),Color("587782"))
  for z in [-7,0,7]:
   box(self,Vector3(0.03,0.10,2),Vector3(side*12.03,1.6,z),Color("4fd8d1"))
  deck(Vector3(side*10,5.2,-10),4,6,Color("75614d"))
  for x in [-1.6,1.6]:
   platform(Vector3(0.3,5.2,0.3),Vector3(side*10+x,2.3,-12.6),Color("52646b"))
 for i in range(3):
  platform(Vector3(4,0.8*(i+1),1.6),Vector3(0,0.4*(i+1),-6.8-i*1.6),Color("88674e"))
 deck(Vector3(0,2.4,-10.5),16,4.2,Color("55717a"))
 for side in [-1,1]:
  deck(Vector3(side*9,0.8,-9.5),2,2,Color("55717a"))
  deck(Vector3(side*7,1.6,-10.5),2,2,Color("55717a"))
 platform(Vector3(4,0.35,4),Vector3(0,1.38,1),Color("728890"))
 for x in [-2.1,2.1]:platform(Vector3(0.25,1.55,4),Vector3(x,0.77,1),Color("728890"))
 signpost(Vector3(0,2.3,2),"SLIDE · ATAJO",Color("ffc681"))
 signpost(Vector3(0,3.3,-10),"CRUCE NORTE",Color("c2e7ed"))
 signpost(Vector3(10,2.5,1),"WALLRUN",Color("6cf3e5"))
 signpost(Vector3(-10,2.5,1),"WALLRUN",Color("6cf3e5"))
 signpost(Vector3(0,1.7,11),"CIRCUITO · SIGUE LOS AROS VERDES",Color("a2f4b1"))
 lap_label=signpost(Vector3(0,2.5,11),"ENTRA EN EL ARO 1 PARA EMPEZAR",Color("e0eeed"))
 for i in range(route_points.size()):
  var marker:=MeshInstance3D.new()
  var shape:=TorusMesh.new()
  shape.inner_radius=1.0
  shape.outer_radius=1.08
  marker.mesh=shape
  marker.material_override=material(Color("7ce9a1") if i==0 else Color("4a7478"),i==0)
  add_child(marker)
  marker.position=route_points[i]+Vector3.UP*0.08
  route_markers.append(marker)
  signpost(route_points[i]+Vector3.UP*0.5,str(i+1),Color("a4ddbf"))

func _ready() -> void:
 super._ready()
 ropes=Node3D.new()
 ropes.name="AbilityRopes"
 ropes.set_script(preload("res://game/ziplines.gd"))
 ropes.arena=self
 add_child(ropes)
 ropes.add_rope(Vector3(5,0.15,8),Vector3(5,3.2,-10))
 ropes.add_rope(Vector3(-10,0.15,-6),Vector3(-10,5.4,-6))
 ropes.add_rope(Vector3(-10,5.4,-10),Vector3(10,5.4,-10))
 ropes.add_rope(Vector3(10,0.15,-6),Vector3(10,5.4,-6))
 ropes.add_rope(Vector3(10,5.4,-6),Vector3(3,0.15,10))

func _physics_process(dt:float) -> void:
 super._physics_process(dt)
 if lap_running:lap_time+=dt
 var target:=route_points[route_index]
 if Vector2(player.position.x-target.x,player.position.z-target.z).length()<2.0 and absf(player.position.y-target.y)<0.8:
  if not lap_running:
   lap_running=true
   lap_time=0
  route_markers[route_index].material_override=material(Color("4a7478"))
  route_index+=1
  if route_index==route_points.size():
   if best_lap==0 or lap_time<best_lap:best_lap=lap_time
   route_index=0
   lap_running=false
  route_markers[route_index].material_override=material(Color("7ce9a1"),true)
 lap_label.text=("VUELTA %.1f s · ARO %d/6" % [lap_time,route_index+1]) if lap_running else "MEJOR %.1f s · ARO 1 PARA EMPEZAR" % best_lap

func _input(event:InputEvent) -> void:
 if is_instance_valid(abilities) and (abilities.recovery>0 or abilities.parry_left>0 or abilities.ember_dash):
  super._input(event)
  return
 if is_instance_valid(ropes) and not get_tree().paused and event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_E and (ropes.active>=0 or ropes.nearest().index>=0):
   ropes.interact()
   return
  if event.keycode in [KEY_SPACE,KEY_SHIFT] and ropes.active>=0:
   ropes.detach()
   if event.keycode==KEY_SHIFT:try_dash()
   return
 super._input(event)

func move_player(dt:float) -> void:
 if is_instance_valid(ropes) and ropes.drive(dt):return
 super.move_player(dt)

func begin_charge() -> bool:
 if is_instance_valid(ropes) and ropes.active>=0:ropes.detach()
 return super.begin_charge()

func reset_player() -> void:
 if is_instance_valid(ropes):ropes.release()
 lap_running=false
 lap_time=0
 route_index=0
 for i in range(route_markers.size()):route_markers[i].material_override=material(Color("7ce9a1") if i==0 else Color("4a7478"),i==0)
 super.reset_player()




