extends Node3D
var art:Node3D
var rng:=RandomNumberGenerator.new()
var water_material:ShaderMaterial
var waterfall_material:ShaderMaterial
var grass:StandardMaterial3D
var bank:StandardMaterial3D
var river_count:=0
var waterfall_count:=0
var scenic_tree_count:=0
func build(source:Node3D) -> void:
 art=source
 name="RiverGardens"
 rng.seed=6172026
 water_material=ShaderMaterial.new()
 water_material.shader=preload("res://game/descent/art/water.gdshader")
 waterfall_material=water_material.duplicate()
 waterfall_material.set_shader_parameter("waterfall",true)
 grass=art.color_material(Color("496744"))
 bank=art.color_material(Color("737563"))
 for side in [-1,1]:
  river(side)
  for x in [-31,27]:bridge(Vector3(x,-3.5,river_z(x,side)),side)
  for index in range(14):
   var x:float=-62+index*9.4+rng.randf_range(-1.5,1.5)
   var z:float=river_z(x,side)+side*rng.randf_range(8.5,15)
   var scale_value:float=rng.randf_range(0.65,1.3)
   art.tree(Vector3(x,-4.3,z),scale_value)
   scenic_tree_count+=1
  for index in range(24):
   var x:float=rng.randf_range(-63,63)
   var z:float=river_z(x,side)+side*rng.randf_range(5.5,10.0)
   var point:=Vector3(x,-3.9,z)
   boulder(point,Vector3(rng.randf_range(0.7,2.3),rng.randf_range(0.7,1.6),rng.randf_range(0.7,1.8)))
   art.foliage(self,point+Vector3(1,0.3,0),Vector3(1.4,0.9,1.2),index)
   reeds(point+Vector3(0,0.25,side*-1.8))
  for index in range(5):
   var x:float=-63+index*31
   var point:=Vector3(x,-6,side*(64+index%2*10))
   boulder(point,Vector3(14,12+index%3*6,12))
   boulder(point+Vector3(8,3,5),Vector3(8,10,9))
  # Near-edge gardens grow below the arena lip; the combat surface stays clear.
  for index in range(11):
   var x:float=-24+index*4.8
   var point:=Vector3(x,-1.0,side*28.7)
   art.foliage(self,point,Vector3(1.4,0.8,1.0),index+2)
   if index%3==0:art.tree(point-Vector3.UP*1.6,0.65)
  lotus(side)

func river_z(x:float,side:int) -> float:
 return side*(40.5+sin(x*0.065)*2.2+cos(x*0.13)*0.8)

func ribbon(side:int,inner:float,outer:float,height:float,mat:Material) -> void:
 var st:=SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for index in range(80):
  var x0:float=-70+index*1.75
  var x1:float=x0+1.75
  var a:=Vector3(x0,height,river_z(x0,side)+inner)
  var b:=Vector3(x1,height,river_z(x1,side)+inner)
  var c:=Vector3(x1,height,river_z(x1,side)+outer)
  var d:=Vector3(x0,height,river_z(x0,side)+outer)
  var vertices:Array[Vector3]=[a,c,b,a,d,c]
  var uvs:Array[Vector2]=[Vector2(0,x0*0.3),Vector2(1,x1*0.3),Vector2(0,x1*0.3),Vector2(0,x0*0.3),Vector2(1,x0*0.3),Vector2(1,x1*0.3)]
  for vertex in range(6):
   st.set_uv(uvs[vertex])
   st.add_vertex(vertices[vertex])
 st.generate_normals()
 art.mesh_node(self,st.commit(),Vector3.ZERO,mat)

func river(side:int) -> void:
 ribbon(side,-5,5,-3.55,water_material)
 ribbon(side,5,18,-3.9,grass)
 ribbon(side,-11,-5,-3.9,grass)
 ribbon(side,-5.6,-4.9,-3.7,bank)
 ribbon(side,4.9,5.6,-3.7,bank)
 river_count+=1
 for end in [-1,1]:
  var x:float=end*70
  var z:float=river_z(x,side)
  var st:=SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for index in range(12):
   var y0:float=-3.55-index*1.6
   var y1:=y0-1.6
   var a:=Vector3(x,y0,z-5)
   var b:=Vector3(x,y0,z+5)
   var c:=Vector3(x+end*0.35,y1,z+5)
   var d:=Vector3(x+end*0.35,y1,z-5)
   var vertices:Array[Vector3]=[a,c,b,a,d,c]
   var uvs:Array[Vector2]=[Vector2(0,index*0.2),Vector2(1,(index+1)*0.2),Vector2(1,index*0.2),Vector2(0,index*0.2),Vector2(0,(index+1)*0.2),Vector2(1,(index+1)*0.2)]
   for vertex in range(6):st.set_uv(uvs[vertex]);st.add_vertex(vertices[vertex])
  st.generate_normals()
  art.mesh_node(self,st.commit(),Vector3.ZERO,waterfall_material)
  waterfall_count+=1
  for offset in [-6,6]:boulder(Vector3(x,-9,z+offset),Vector3(3,9,4))
  mist(Vector3(x,-21,z))

func boulder(point:Vector3,size:Vector3) -> void:
 var key:="Rock_Medium_%d" % (posmod(int(point.x+point.z),3)+1)
 preload("res://game/descent/art/nature_assets.gd").place(self,key,point,size/2.5,rng.randf()*TAU)

func bridge(point:Vector3,side:int) -> void:
 var root:=Node3D.new()
 add_child(root)
 root.position=point
 for index in range(19):
  var z:float=-7.2+index*0.8
  var y:float=sin((index/18.0)*PI)*1.4
  art.block(root,Vector3(3.8,0.22,0.74),Vector3(0,y,z),art.wood)
  if index%3==0:
   for x in [-1.8,1.8]:
    art.cylinder(root,Vector3(x,y+0.75,z),1.5,0.13,0.11,art.gold)
 for x in [-1.8,1.8]:
  for index in range(18):
   var z0:float=-7.2+index*0.8
   var z1:=z0+0.8
   var y0:float=sin(index/18.0*PI)*1.4+1.4
   var y1:float=sin((index+1)/18.0*PI)*1.4+1.4
   art.segment(root,Vector3(x,y0,z0),Vector3(x,y1,z1),0.075,0.075,art.gold)
 for z in [-7.5,7.5]:art.cylinder(root,Vector3(0,-1,z),2.0,2.5,2.0,bank)

func reeds(point:Vector3) -> void:
 for index in range(4):
  var height:float=rng.randf_range(0.45,1.0)
  var node:MeshInstance3D=art.cylinder(self,point+Vector3(index*0.12,height/2,0),height,0.045,0.005,grass,4)
  node.rotation.z=rng.randf_range(-0.3,0.3)

func lotus(side:int) -> void:
 var pads:=MultiMesh.new()
 pads.transform_format=MultiMesh.TRANSFORM_3D
 var mesh:=CylinderMesh.new()
 mesh.height=0.015
 mesh.top_radius=0.32
 mesh.bottom_radius=0.32
 mesh.radial_segments=7
 pads.mesh=mesh
 pads.instance_count=30
 for index in range(30):
  var x:float=rng.randf_range(-62,62)
  var point:=Vector3(x,-3.47,river_z(x,side)+rng.randf_range(-3.8,3.8))
  pads.set_instance_transform(index,Transform3D(Basis(Vector3.UP,rng.randf()*TAU),point))
  if index%6==0:art.cylinder(self,point+Vector3.UP*0.08,0.16,0.12,0.025,art.leaves[4],6)
 var node:=MultiMeshInstance3D.new()
 node.multimesh=pads
 node.material_override=grass
 add_child(node)

func mist(point:Vector3) -> void:
 var particles:=CPUParticles3D.new()
 particles.amount=18
 particles.lifetime=3
 particles.direction=Vector3.UP
 particles.spread=70
 particles.initial_velocity_min=0.4
 particles.initial_velocity_max=1.2
 particles.gravity=Vector3(0,0.1,0)
 particles.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
 particles.emission_box_extents=Vector3(1,0.2,4)
 var mesh:=SphereMesh.new()
 mesh.radial_segments=6
 mesh.rings=3
 mesh.radius=0.25
 mesh.height=0.5
 particles.mesh=mesh
 var mat:StandardMaterial3D=art.color_material(Color(0.65,0.8,0.78,0.18))
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 particles.material_override=mat
 add_child(particles)
 particles.position=point
