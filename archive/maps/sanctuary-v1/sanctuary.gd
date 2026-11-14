extends Node3D
var arena:Node3D
var rng:=RandomNumberGenerator.new()
var stone:ShaderMaterial
var floor_material:ShaderMaterial
var gold:StandardMaterial3D
var wood:StandardMaterial3D
var roof:StandardMaterial3D
var cliff:StandardMaterial3D
var leaves:Array[ShaderMaterial]=[]
var decorated_obstacles:=0

func color_material(color:Color,metal:float=0.0) -> StandardMaterial3D:
 var mat:=StandardMaterial3D.new()
 mat.albedo_color=color
 mat.roughness=0.77
 mat.metallic=metal
 mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 return mat

func mesh_node(parent:Node3D,mesh:Mesh,point:Vector3,mat:Material) -> MeshInstance3D:
 var node:=MeshInstance3D.new()
 node.mesh=mesh
 node.material_override=mat
 parent.add_child(node)
 node.position=point
 return node

func block(parent:Node3D,size:Vector3,point:Vector3,mat:Material) -> MeshInstance3D:
 var mesh:=BoxMesh.new()
 mesh.size=size
 return mesh_node(parent,mesh,point,mat)

func cylinder(parent:Node3D,point:Vector3,height:float,bottom:float,top:float,mat:Material,sides:int=8) -> MeshInstance3D:
 var mesh:=CylinderMesh.new()
 mesh.height=height
 mesh.bottom_radius=bottom
 mesh.top_radius=top
 mesh.radial_segments=sides
 return mesh_node(parent,mesh,point,mat)

func segment(parent:Node3D,a:Vector3,b:Vector3,bottom:float,top:float,mat:Material) -> void:
 var node:=cylinder(parent,(a+b)*0.5,a.distance_to(b),bottom,top,mat)
 node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())

func outline(width:float,depth:float,inset:float=0) -> PackedVector2Array:
 var x:=maxf(0.03,width/2-inset)
 var z:=maxf(0.03,depth/2-inset)
 var cut:=minf(0.22,minf(x,z)*0.24)
 return PackedVector2Array([Vector2(-x+cut,-z),Vector2(x-cut,-z),Vector2(x,-z+cut),Vector2(x,z-cut),Vector2(x-cut,z),Vector2(-x+cut,z),Vector2(-x,z-cut),Vector2(-x,-z+cut)])

func profiled_mesh(rings:Array[PackedVector2Array],heights:Array[float]) -> ArrayMesh:
 var st:=SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(rings.size()-1):
  for index in range(rings[row].size()):
   var next:=(index+1)%rings[row].size()
   var a:=Vector3(rings[row][index].x,heights[row],rings[row][index].y)
   var b:=Vector3(rings[row][next].x,heights[row],rings[row][next].y)
   var c:=Vector3(rings[row+1][next].x,heights[row+1],rings[row+1][next].y)
   var d:=Vector3(rings[row+1][index].x,heights[row+1],rings[row+1][index].y)
   for vertex in [a,c,b,a,d,c]:st.add_vertex(vertex)
 var last:=rings.size()-1
 for index in range(rings[last].size()):
  var next:=(index+1)%rings[last].size()
  for vertex in [Vector3(0,heights[last],0),Vector3(rings[last][next].x,heights[last],rings[last][next].y),Vector3(rings[last][index].x,heights[last],rings[last][index].y)]:st.add_vertex(vertex)
 st.generate_normals()
 return st.commit()

func stone_mesh(size:Vector3) -> ArrayMesh:
 var bevel:=minf(0.12,size.y*0.2)
 return profiled_mesh([outline(size.x,size.z,0.06),outline(size.x,size.z),outline(size.x,size.z),outline(size.x,size.z,0.07)],[-size.y/2,-size.y/2+bevel,size.y/2-bevel,size.y/2])

func build(value:Node3D) -> void:
 arena=value
 rng.seed=17062026
 name="SanctuaryArt"
 stone=ShaderMaterial.new()
 stone.shader=preload("res://game/descent/art/textured_stone.gdshader")
 stone.set_shader_parameter("wall_color",load("res://assets/environment/materials/wall_color.png"))
 floor_material=ShaderMaterial.new()
 floor_material.shader=preload("res://game/descent/art/courtyard.gdshader")
 floor_material.set_shader_parameter("stone_color",load("res://assets/environment/materials/stone_color.png"))
 floor_material.set_shader_parameter("grass_color",load("res://assets/environment/materials/grass_color.png"))
 floor_material.set_shader_parameter("wall_color",load("res://assets/environment/materials/wall_color.png"))
 gold=color_material(Color("af8240"),0.45)
 wood=color_material(Color("493b37"))
 roof=color_material(Color("254846"),0.12)
 cliff=color_material(Color("475155"))
 cliff.albedo_texture=load("res://assets/environment/quaternius/Rocks_Diffuse.png")
 cliff.uv1_triplanar=true
 cliff.uv1_world_triplanar=true
 cliff.uv1_scale=Vector3.ONE*0.2
 for color in [Color("9e3528"),Color("be4c2d"),Color("d47434"),Color("802d2b"),Color("d7984c")]:
  var mat:=ShaderMaterial.new()
  mat.shader=preload("res://game/descent/art/foliage.gdshader")
  mat.set_shader_parameter("tint",color)
  leaves.append(mat)
 for node in arena.get_children():
  if node is WorldEnvironment:lighting(node.environment)
  elif node is DirectionalLight3D:
   node.light_color=Color("ffe5bc")
   node.light_energy=0.95
   node.rotation_degrees=Vector3(-53,-32,0)
   node.shadow_blur=2
  elif node is StaticBody3D:
   if node.name=="OctagonalArena":
    for child in node.get_children():
     if child is MeshInstance3D:child.material_override=floor_material
   elif node.name in ["BlueSpawnLift","RedSpawnLift"]:dress_lift(node)
   else:skin_obstacle(node)
  elif node is MeshInstance3D:node.material_override=gold
 underside()
 for side in [-1,1]:
  tree(Vector3(side*28,-2,side*25),1.25)
  tree(Vector3(side*33,-3,side*22),0.85)
  tree(Vector3(side*26,-2,-side*27),0.9)
  tower(Vector3(side*55,-2,-side*37),0.9)
  for z in [-1,1]:brazier(Vector3(side*24,-0.6,z*28.5))
  for index in range(6):
   var angle:float=rng.randf_range(-0.7,0.7)
   var point:=Vector3(side*(26+index*0.8),-1.1,side*(25+angle))
   foliage(self,point,Vector3(1.0,0.65,0.9),index%leaves.size())
 fallen_leaves()
 var gardens:=Node3D.new()
 gardens.set_script(preload("res://game/descent/art/river_gardens.gd"))
 add_child(gardens)
 gardens.build(self)
 preload("res://game/descent/art/nature_assets.gd").garden(self)
 var fill:=DirectionalLight3D.new()
 fill.rotation_degrees=Vector3(-25,145,0)
 fill.light_color=Color("9dbbcf")
 fill.light_energy=0.2
 add_child(fill)

func lighting(env:Environment) -> void:
 env.background_mode=Environment.BG_SKY
 var sky:=Sky.new()
 var sky_material:=ProceduralSkyMaterial.new()
 sky_material.sky_top_color=Color("637f96")
 sky_material.sky_horizon_color=Color("8ba6b2")
 sky_material.ground_bottom_color=Color("374856")
 sky_material.ground_horizon_color=Color("9badaf")
 sky_material.sky_curve=0.2
 sky.sky_material=sky_material
 env.sky=sky
 env.ambient_light_color=Color("c4d6df")
 env.ambient_light_energy=0.32
 env.fog_light_color=Color("90a8ad")
 env.fog_density=0.0006
 env.ssao_enabled=true
 env.ssao_radius=1.6
 env.ssao_intensity=1.0
 env.glow_enabled=true
 env.glow_intensity=0.35
 env.glow_hdr_threshold=1.3
 env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 env.tonemap_exposure=0.95
 env.adjustment_enabled=true
 env.adjustment_saturation=1.12
 env.adjustment_contrast=1.04

func skin_obstacle(body:StaticBody3D) -> void:
 var size:=Vector3.ZERO
 for child in body.get_children():
  if child is CollisionShape3D and child.shape is BoxShape3D:size=child.shape.size
 if size==Vector3.ZERO:return
 for child in body.get_children():
  if child is MeshInstance3D:
   child.mesh=stone_mesh(size)
   child.material_override=stone
 decorated_obstacles+=1
 var cap_height:=minf(0.17,size.y*0.2)
 mesh_node(body,stone_mesh(Vector3(size.x,cap_height,size.z)),Vector3(0,size.y/2-cap_height/2,0),roof)
 mesh_node(body,stone_mesh(Vector3(size.x,cap_height,size.z)),Vector3(0,-size.y/2+cap_height/2,0),gold)
 var clearance:float=body.position.y-size.y/2
 if size.y<1 and clearance>0.5 and size.x>=4 and size.z>=4:
  var support_size:=Vector3(size.x*0.72,clearance,size.z*0.72)
  var support_point:=Vector3(0,-size.y/2-clearance/2,0)
  mesh_node(body,stone_mesh(support_size),support_point,stone)
  var support_collision:=CollisionShape3D.new()
  var support_shape:=BoxShape3D.new()
  support_shape.size=support_size
  support_collision.shape=support_shape
  support_collision.position=support_point
  body.add_child(support_collision)
 if size.y<1:return
 if size.x>size.z*2:
  for x in [-size.x/2+0.3,size.x/2-0.3]:block(body,Vector3(0.17,size.y-0.35,size.z+0.015),Vector3(x,0,0),gold)
  for z in [-size.z/2-0.01,size.z/2+0.01]:block(body,Vector3(size.x-0.4,0.07,0.035),Vector3(0,size.y*0.24,z),gold)
 elif size.z>size.x*2:
  for z in [-size.z/2+0.3,size.z/2-0.3]:block(body,Vector3(size.x+0.015,size.y-0.35,0.17),Vector3(0,0,z),gold)
  for x in [-size.x/2-0.01,size.x/2+0.01]:block(body,Vector3(0.035,0.07,size.z-0.4),Vector3(x,size.y*0.24,0),gold)
 else:
  for x in [-1,1]:
   for z in [-1,1]:cylinder(body,Vector3(x*(size.x/2-0.18),0,z*(size.z/2-0.18)),size.y-0.25,0.12,0.09,gold)
  var lid:=stone_mesh(Vector3(size.x*0.75,0.22,size.z*0.75))
  mesh_node(body,lid,Vector3(0,size.y/2-0.13,0),gold)

func dress_lift(body:StaticBody3D) -> void:
 for child in body.get_children():
  if child is MeshInstance3D:
   child.material_override=floor_material if child.mesh is BoxMesh and child.mesh.size.y>0.5 and child.mesh.size.x>10 else gold
  elif child is StaticBody3D:
   for part in child.get_children():
    if part is MeshInstance3D:part.material_override=gold
  elif child is Label3D:
   child.font_size=24
   child.text="ATRIO AZUL" if body.name=="BlueSpawnLift" else "ATRIO ROJO"
   child.position=Vector3(0,5.1,0)
 for x in [-5.8,5.8]:
  for z in [-5.8,5.8]:
   cylinder(body,Vector3(x,3.2,z),6.4,0.19,0.15,wood)
   cylinder(body,Vector3(x,0.2,z),0.4,0.3,0.25,gold)
   cylinder(body,Vector3(x,6.3,z),0.35,0.35,0.2,gold)
 block(body,Vector3(11.9,0.28,0.35),Vector3(0,6.35,-5.8),roof)
 block(body,Vector3(11.9,0.28,0.35),Vector3(0,6.35,5.8),roof)
 for x in [-5.8,5.8]:block(body,Vector3(0.35,0.28,11.9),Vector3(x,6.35,0),roof)
 var ring:=TorusMesh.new()
 ring.inner_radius=2.1
 ring.outer_radius=2.17
 mesh_node(body,ring,Vector3(0,0.035,0),gold).scale.y=0.1

func underside() -> void:
 var top:PackedVector2Array=PackedVector2Array([Vector2(-32,-19),Vector2(-23,-28),Vector2(23,-28),Vector2(32,-19),Vector2(32,19),Vector2(23,28),Vector2(-23,28),Vector2(-32,19)])
 var middle:=PackedVector2Array()
 var bottom:=PackedVector2Array()
 for p in top:middle.append(p*0.97);bottom.append(p*0.7)
 mesh_node(self,profiled_mesh([bottom,middle,top],[-10,-3,-1.02]),Vector3.ZERO,cliff)
 for index in range(18):
  var angle:=index*TAU/18
  var rock:=SphereMesh.new()
  rock.radial_segments=7
  rock.rings=3
  var node:=mesh_node(self,rock,Vector3(cos(angle)*25,-3.5,sin(angle)*22),cliff)
  node.scale=Vector3(rng.randf_range(4,7),rng.randf_range(3,6),rng.randf_range(3,5))
  node.rotation=Vector3(rng.randf(),rng.randf(),rng.randf())

func foliage(parent:Node3D,point:Vector3,size:Vector3,index:int) -> void:
 preload("res://game/descent/art/nature_assets.gd").place(parent,"Bush_Common_Flowers" if index%4==0 else "Bush_Common",point-Vector3.UP*0.25,size*0.7,index*1.2)

func tree(point:Vector3,size:float) -> void:
 var variants:=["CommonTree_1","CommonTree_3","CommonTree_5"]
 var variant:int=posmod(int(point.x*3+point.z),variants.size())
 preload("res://game/descent/art/nature_assets.gd").place(self,variants[variant],point,Vector3.ONE*size,rng.randf()*TAU)

func roof_mesh(width:float,depth:float) -> ArrayMesh:
 return profiled_mesh([outline(width,depth),outline(width*0.88,depth*0.88),outline(width*0.15,depth*0.15)],[0.3,0.0,1.8])

func tower(point:Vector3,size:float) -> void:
 var root:=Node3D.new()
 add_child(root)
 root.position=point
 root.scale=Vector3.ONE*size
 cylinder(root,Vector3(0,-3,0),6,5,8,cliff)
 cylinder(root,Vector3.ZERO,1.2,7.5,7.5,stone)
 for level in range(3):
  var width:=12-level*2
  var height:=1.5+level*4
  block(root,Vector3(width-3,3.5,width-3),Vector3(0,height+1.5,0),wood)
  for x in [-1,1]:
   for z in [-1,1]:cylinder(root,Vector3(x*(width-3)/2.0,height+1.5,z*(width-3)/2.0),3.5,0.25,0.22,gold)
  mesh_node(root,roof_mesh(width,width),Vector3(0,height+3.2,0),roof)
  mesh_node(root,roof_mesh(width*1.01,width*1.01),Vector3(0,height+3.12,0),gold)
 cylinder(root,Vector3(0,15,0),3,0.35,0.05,gold)

func brazier(point:Vector3) -> void:
 cylinder(self,point,1.5,0.6,0.4,stone)
 cylinder(self,point+Vector3.UP*0.85,0.45,0.6,0.85,gold)
 var fire:=ShaderMaterial.new()
 fire.shader=preload("res://game/descent/art/flame.gdshader")
 cylinder(self,point+Vector3.UP*1.5,1.1,0.34,0.03,fire,6)
 var light:=OmniLight3D.new()
 light.position=point+Vector3.UP*2
 light.light_color=Color("ffb263")
 light.light_energy=2
 light.omni_range=7
 add_child(light)

func fallen_leaves() -> void:
 var multi:=MultiMesh.new()
 multi.transform_format=MultiMesh.TRANSFORM_3D
 var mesh:=PrismMesh.new()
 mesh.size=Vector3(0.12,0.015,0.25)
 multi.mesh=mesh
 multi.instance_count=160
 for index in range(160):
  var side:=1 if index%2==0 else -1
  var point:=Vector3(side*rng.randf_range(20,28),0.025,side*rng.randf_range(18,25))
  if absf(point.x)+absf(point.z)>50:point*=0.92
  multi.set_instance_transform(index,Transform3D(Basis(Vector3.UP,rng.randf()*TAU),point))
 var node:=MultiMeshInstance3D.new()
 node.multimesh=multi
 node.material_override=color_material(Color("af5b2e"))
 add_child(node)


