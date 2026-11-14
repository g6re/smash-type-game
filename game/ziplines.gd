extends Node3D
var arena:Node3D
var lines:Array[Dictionary]=[]
var active:=-1
var progress:=0.0
var travel_sign:=1.0
var lock:=0.0
var hint:Label3D

func _ready() -> void:
 hint=Label3D.new()
 add_child(hint)
 hint.font_size=32
 hint.pixel_size=0.008
 hint.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 hint.no_depth_test=true
 hint.hide()

func add_rope(a:Vector3,b:Vector3) -> void:
 lines.append({"a":a,"b":b})
 var cable:=MeshInstance3D.new()
 var mesh:=CylinderMesh.new()
 mesh.top_radius=0.045
 mesh.bottom_radius=0.045
 mesh.height=a.distance_to(b)
 cable.mesh=mesh
 cable.material_override=arena.material(Color("ffcf62"),true)
 add_child(cable)
 cable.position=(a+b)*0.5+Vector3.UP*1.1
 cable.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
 var side:Vector3=(b-a).cross(Vector3.UP).normalized()
 if side.length()<0.1:side=Vector3.RIGHT
 for point in [a,b]:
  arena.box(self,Vector3(0.25,1.15,0.25),point+side*0.9+Vector3.UP*0.55,Color("d6944e"))
  arena.box(self,Vector3(0.8,0.15,0.8),point+Vector3.UP*0.06,Color("ffb654"))

func nearest() -> Dictionary:
 var best:={"index":-1,"distance":1.5,"point":Vector3.ZERO}
 for i in range(lines.size()):
  var point:=Geometry3D.get_closest_point_to_segment(arena.player.position,lines[i].a,lines[i].b)
  var distance:float=arena.player.position.distance_to(point)
  if distance<best.distance:best={"index":i,"distance":distance,"point":point}
 return best

func interact() -> void:
 if active>=0:
  detach()
  return
 if lock>0 or arena.charging or arena.slash_left>0 or arena.mantle_left>0:return
 var found:=nearest()
 if found.index<0:return
 if not arena.mantle_space_clear(found.point):return
 active=found.index
 var line:Dictionary=lines[active]
 progress=line.a.distance_to(found.point)/line.a.distance_to(line.b)
 var tangent:Vector3=(line.b-line.a).normalized()
 var aim:Vector3=-arena.camera.global_basis.z
 travel_sign=1 if aim.dot(tangent)>=0 else -1
 if progress<0.05:travel_sign=1
 if progress>0.95:travel_sign=-1
 arena.cancel_charge()
 arena.parkour.reset()
 arena.slide_time=0
 arena.dash_time=0
 arena.player.position=found.point
 hint.hide()

func release() -> void:
 active=-1
 lock=0.35

func detach() -> void:
 if active<0:return
 var line:Dictionary=lines[active]
 var tangent:Vector3=(line.b-line.a).normalized()*travel_sign
 release()
 arena.player.velocity=tangent*8+Vector3.UP*7
 arena.jumps=1

func drive(dt:float) -> bool:
 lock=maxf(0,lock-dt)
 if active<0:
  var found:=nearest()
  hint.visible=found.index>=0 and lock<=0
  if hint.visible:
   hint.position=found.point+Vector3.UP*2.3
   hint.text="E · CUERDA"
  return false
 var line:Dictionary=lines[active]
 var length:float=line.a.distance_to(line.b)
 var movement:Vector3=arena.parkour.input_direction()
 var tangent:Vector3=(line.b-line.a).normalized()
 if movement.length()>0.1 and absf(movement.dot(tangent))>0.25:travel_sign=signf(movement.dot(tangent))
 progress=clampf(progress+travel_sign*10*dt/length,0,1)
 var target:Vector3=line.a.lerp(line.b,progress)
 var collision:KinematicCollision3D=arena.player.move_and_collide(target-arena.player.position)
 if collision!=null:
  detach()
  return true
 arena.player.velocity=tangent*travel_sign*10
 arena.model.rotation.y=lerp_angle(arena.model.rotation.y,arena.yaw,1-exp(-dt*12))
 arena.status="CUERDA · ESPACIO PARA SOLTAR"
 if progress<=0 or progress>=1:detach()
 return true



