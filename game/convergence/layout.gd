extends RefCounted
const POINTS=[Vector3(0,0,0),Vector3(-25,0,12),Vector3(25,0,-12),Vector3(0,0,-26),Vector3(0,0,26)]
static func build(arena:Node3D) -> void:
 var stone:=ShaderMaterial.new()
 stone.shader=preload("res://game/descent/art/courtyard.gdshader")
 for pair in [["stone_color","stone_color.png"],["grass_color","grass_color.png"],["wall_color","wall_color.png"]]:stone.set_shader_parameter(pair[0],load("res://assets/environment/materials/"+pair[1]))
 var masonry:=ShaderMaterial.new()
 masonry.shader=preload("res://game/descent/art/textured_stone.gdshader")
 masonry.set_shader_parameter("wall_color",load("res://assets/environment/materials/wall_color.png"))
 for i in range(POINTS.size()):
  var radius:float=11 if i==0 else 8
  var body:=StaticBody3D.new()
  body.name="Plaza%d" % i
  arena.add_child(body)
  body.position=POINTS[i]-Vector3.UP*0.7
  var col:=CollisionShape3D.new()
  var shape:=CylinderShape3D.new()
  shape.radius=radius
  shape.height=1.4
  col.shape=shape
  body.add_child(col)
  var mesh:=MeshInstance3D.new()
  var cylinder:=CylinderMesh.new()
  cylinder.top_radius=radius
  cylinder.bottom_radius=radius
  cylinder.height=1.4
  cylinder.radial_segments=64
  mesh.mesh=cylinder
  mesh.material_override=stone
  body.add_child(mesh)
  var foundation:=MeshInstance3D.new()
  var base:=CylinderMesh.new()
  base.top_radius=radius*0.94
  base.bottom_radius=radius*0.7
  base.height=6
  foundation.mesh=base
  foundation.material_override=masonry
  body.add_child(foundation)
  foundation.position.y=-3.6
  var ring:=MeshInstance3D.new()
  var torus:=TorusMesh.new()
  torus.inner_radius=radius-0.22
  torus.outer_radius=radius-0.10
  ring.mesh=torus
  ring.scale.y=0.2
  ring.material_override=arena.material(Color("a68d58"))
  arena.add_child(ring)
  ring.position=POINTS[i]+Vector3.UP*0.05
 for i in range(1,POINTS.size()):bridge(arena,POINTS[0],POINTS[i],5.5,stone)
 for pair in [[1,4],[4,2],[2,3],[3,1]]:bridge(arena,POINTS[pair[0]],POINTS[pair[1]],3.5,stone)
 var nature=preload("res://game/descent/art/nature_assets.gd")
 for x in [-1,1]:
  for z in [-1,1]:
   var p:=Vector3(x*16,-4,z*15)
   nature.place(arena,"Rock_Medium_1",p,Vector3(3,5,3),x+z)
   nature.place(arena,"Rock_Medium_3",p+Vector3(x*3,-2,z*2),Vector3(2.5,3,2.5),z)
 var env:WorldEnvironment=null
 for child in arena.get_children():
  if child is WorldEnvironment:env=child
 if env!=null:
  env.environment.background_color=Color("536879")
  env.environment.fog_density=0.003
  env.environment.ambient_light_energy=0.45

static func bridge(arena:Node3D,a:Vector3,b:Vector3,width:float,mat:Material) -> void:
 var body:=StaticBody3D.new()
 body.name="Bridge"
 arena.add_child(body)
 body.position=(a+b)/2-Vector3.UP*0.45
 body.rotation.y=atan2((b-a).x,(b-a).z)
 var size:=Vector3(width,0.9,a.distance_to(b))
 var collision:=CollisionShape3D.new()
 var shape:=BoxShape3D.new()
 shape.size=size
 collision.shape=shape
 body.add_child(collision)
 var visual:MeshInstance3D=arena.box(body,size,Vector3.ZERO,Color.WHITE)
 visual.material_override=mat
