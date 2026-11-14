extends Node3D
var arena:Node3D
var success:=false
var age:=0.0
var rings:Array[MeshInstance3D]=[]
var star:MeshInstance3D
var duration:=0.3

func energy_material() -> ShaderMaterial:
 var mat:=ShaderMaterial.new()
 mat.shader=preload("res://game/shaders/parry_energy.gdshader")
 return mat

func _ready() -> void:
 duration=0.42 if success else 0.3
 for i in range(3 if success else 2):
  var arc:=MeshInstance3D.new()
  arc.mesh=arena.slash_effects.crescent_mesh(1.0,0.24 if success else 0.14)
  arc.material_override=energy_material()
  add_child(arc)
  arc.position.z=-0.25 if success else -0.6
  arc.rotation=Vector3(PI/2,i*0.42 if success else 0,i*2.1)
  arc.scale=Vector3.ONE*(0.6+i*0.14)
  rings.append(arc)
 if success:
  star=MeshInstance3D.new()
  var mesh:=ImmediateMesh.new()
  mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
  for i in range(8):
   var angle:=i*TAU/8
   var radial:=Vector3(cos(angle),sin(angle),0)
   var tangent:=Vector3(-sin(angle),cos(angle),0)
   var length:=1.05 if i%2==0 else 0.55
   for point in [-tangent*0.065,radial*length,tangent*0.065]:mesh.surface_add_vertex(point)
  mesh.surface_end()
  star.mesh=mesh
  star.material_override=arena.slash_effects.glow(Color(1,0.94,0.67,0.9))
  add_child(star)
  preload("res://game/pixel_sparks.gd").burst(arena.slash_effects,global_position,Color("8df5ff"),30,6)

func _process(dt:float) -> void:
 age+=dt
 if age>=duration:queue_free();return
 var phase:=age/duration
 for i in range(rings.size()):
  var ring:MeshInstance3D=rings[i]
  ring.rotation.z+=dt*(8 if i%2==0 else -10)
  var radius:=0.45+phase*1.7+i*0.13 if success else 0.72+i*0.12+sin(age*22)*0.035
  ring.scale=Vector3.ONE*radius
  ring.material_override.set_shader_parameter("fade",pow(1-phase,0.6) if success else 1.0-phase*0.45)
 if success:
  var camera:Camera3D=arena.get_viewport().get_camera_3d()
  if camera!=null:
   star.global_basis=camera.global_basis
   star.global_position=global_position+camera.global_basis.z*0.45+Vector3.UP*0.15
  star.scale=Vector3.ONE*maxf(0,1-age/0.16)
