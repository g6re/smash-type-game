extends "res://game/descent/art/sanctuary.gd"
const NATURE=preload("res://game/descent/art/nature_assets.gd")

func build(value:Node3D) -> void:
 arena=value
 name="SanctuaryArt"
 rng.seed=18102026
 stone=ShaderMaterial.new()
 stone.shader=preload("res://game/descent/art/textured_stone.gdshader")
 stone.set_shader_parameter("wall_color",load("res://assets/environment/materials/wall_color.png"))
 floor_material=ShaderMaterial.new()
 floor_material.shader=preload("res://game/descent/art/courtyard.gdshader")
 for pair in [["stone_color","stone_color.png"],["grass_color","grass_color.png"],["wall_color","wall_color.png"]]:
  floor_material.set_shader_parameter(pair[0],load("res://assets/environment/materials/"+pair[1]))
 gold=color_material(Color("80704b"),0.2)
 wood=color_material(Color("342b26"))
 roof=color_material(Color("344d47"))
 cliff=color_material(Color("81917d"))
 cliff.albedo_texture=load("res://assets/environment/quaternius/Rocks_Diffuse.png")
 cliff.uv1_triplanar=true
 cliff.uv1_world_triplanar=true
 cliff.uv1_scale=Vector3.ONE*0.18
 for node in arena.get_children():
  if node is WorldEnvironment:
   lighting(node.environment)
   node.environment.fog_density=0.001
   node.environment.adjustment_saturation=0.95
   node.environment.glow_intensity=0.18
  elif node is DirectionalLight3D:
   node.light_color=Color("ffe9cd")
   node.light_energy=0.9
   node.rotation_degrees=Vector3(-48,-38,0)
   node.shadow_blur=2.0
  elif node is StaticBody3D:
   if node.has_meta("tunnel"):
    for part in node.get_children():
     if part is MeshInstance3D:part.material_override=floor_material if node.get_meta("roof",false) else stone
   elif node.name=="OctagonalArena" or node.has_meta("terrain"):
    for part in node.get_children():
     if part is MeshInstance3D:part.material_override=floor_material
   elif node.name in ["BlueSpawnLift","RedSpawnLift"]:dress_lift(node)
   else:skin_obstacle(node)
  elif node is MeshInstance3D:
   node.material_override=gold
 foundation()
 pavilions()
 gardens()
 waterways()
 preload("res://game/descent/art/tunnel_details.gd").build(self)

func foundation() -> void:
 # A continuous rock foundation joins the courts, retaining walls and gardens.
 var contour:=PackedVector2Array([Vector2(-32,-19),Vector2(-23,-28),Vector2(23,-28),Vector2(32,-19),Vector2(32,19),Vector2(23,28),Vector2(-23,28),Vector2(-32,19)])
 var lower:=PackedVector2Array()
 for p in contour:lower.append(p*0.88)
 mesh_node(self,profiled_mesh([lower,contour],[-12,-0.9]),Vector3.ZERO,cliff)
 for side in [-1,1]:
  for i in range(7):
   var p:=Vector3(-29+i*9.5,-5,side*28.5)
   NATURE.place(self,"Rock_Medium_%d" % (i%3+1),p,Vector3(3.5,4,3.0),i*1.7)
  # Bound the courtyard with stone coping; leave the ramps completely open.
  for x in [-25.8,-10.5,10.5,25.8]:
   var width:=3.6 if absf(x)>20 else 10.8
   block(self,Vector3(width,0.16,0.32),Vector3(x,3.24,side*16),roof)

func pavilions() -> void:
 for side in [-1,1]:
  for x in [-18,18]:
   mesh_node(self,roof_mesh(7.2,6.0),Vector3(x,7.0,side*23.2),roof)
   block(self,Vector3(6.0,0.35,0.45),Vector3(x,6.7,side*23.2),wood)
   block(self,Vector3(6.1,0.2,5.5),Vector3(x,3.28,side*23.2),stone)
   for dx in [-2.6,2.6]:
    segment(self,Vector3(x+dx,5.7,side*23.2),Vector3(x+dx-signf(dx)*1.0,6.7,side*23.2),0.13,0.13,wood)
  # The elevator entrance reads as a gallery aligned with its landing.
  var x:float=side*27
  var z:float=-side*12
  for offset in [-6.5,6.5]:
   for dx in [-3.7,3.7]:
    block(self,Vector3(0.48,2.0,0.48),Vector3(x+dx,3.6,z+offset),wood)
   block(self,Vector3(9.0,0.25,0.5),Vector3(x,4.7,z+offset),wood)
  brazier(Vector3(side*18,0.4,side*7))

func gardens() -> void:
 var root:=Node3D.new()
 root.name="TerraceGardens"
 add_child(root)
 # Clusters sit behind the upper routes; low vegetation marks their edges.
 for side in [-1,1]:
  for cluster in [-1,1]:
   var center:=Vector3(cluster*9,3.2,side*23)
   NATURE.place(root,"TwistedTree_2" if cluster==side else "CommonTree_3",center,Vector3.ONE*(0.50 if cluster==side else 0.8),side*1.4)
   NATURE.place(root,"Rock_Medium_2",center+Vector3(1.8,-0.15,side*1.0),Vector3(1.0,0.8,0.8),cluster)
   for i in range(7):
    var angle:float=i*2.399
    var p:=center+Vector3(cos(angle)*2.3,0,sin(angle)*1.5)
    NATURE.place(root,"Fern_1" if i%2==0 else "Bush_Common",p,Vector3.ONE*0.55,angle)
   for i in range(14):
    var angle:float=i*2.399
    var p:=center+Vector3(cos(angle)*3.2,0,sin(angle)*2.0)
    NATURE.place(root,"Grass_Wispy_Short",p,Vector3(0.65,0.30,0.65),angle)
   for i in range(4):
    NATURE.place(root,"Flower_3_Group",center+Vector3(-2+i,0,-side*2.3),Vector3.ONE*0.45,i)
  # Frame the outer corners, rather than planting a regular line of trees.
  for point in [Vector3(-29,-1,side*22),Vector3(30,-1,side*21),Vector3(-26,-1,side*29),Vector3(25,-1,side*29)]:
   NATURE.place(root,"CommonTree_1",point,Vector3.ONE*1.1,point.x)

func waterways() -> void:
 # A narrow watercourse is cut into the back garden; no disconnected river strips.
 var water:=ShaderMaterial.new()
 water.shader=preload("res://game/descent/art/water.gdshader")
 var root:=Node3D.new()
 root.name="Waterways"
 add_child(root)
 for side in [-1,1]:
  var mesh:=PlaneMesh.new()
  mesh.size=Vector2(36,1.3)
  mesh_node(root,mesh,Vector3(0,3.23,side*25.2),water)
  for z_offset in [-0.8,0.8]:
   block(self,Vector3(36,0.16,0.22),Vector3(0,3.25,side*25.2+z_offset),stone)
  # Coping and a flush cover bridge tie the canal to the central garden path.
  block(self,Vector3(4.0,0.18,2.0),Vector3(0,3.3,side*25.2),stone)
