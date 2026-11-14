extends RefCounted
const ROOT="res://assets/environment/quaternius/"
static var scenes:Dictionary={}
static var materials:Dictionary={}

static func place(parent:Node3D,key:String,point:Vector3,size:Vector3=Vector3.ONE,angle:float=0.0) -> Node3D:
 if not scenes.has(key):scenes[key]=load(ROOT+key+".gltf")
 var node:Node3D=scenes[key].instantiate()
 node.name=key
 parent.add_child(node)
 node.position=point
 node.scale=size
 node.rotation.y=angle
 finish_materials(node)
 return node

static func finish_materials(node:Node) -> void:
 if node is MeshInstance3D:
  for i in range(node.mesh.get_surface_count()):
   var source:Material=node.mesh.surface_get_material(i)
   if not source is StandardMaterial3D:continue
   var key:=str(source.get_instance_id())
   if not materials.has(key):
    var mat:StandardMaterial3D=source.duplicate()
    mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    mat.roughness=0.92
    if "Leaves" in mat.resource_name or "Grass" in mat.resource_name:
     mat.cull_mode=BaseMaterial3D.CULL_DISABLED
     mat.alpha_scissor_threshold=0.35
    materials[key]=mat
   node.set_surface_override_material(i,materials[key])
 for child in node.get_children():finish_materials(child)

static func garden(art:Node3D) -> void:
 var root:=Node3D.new()
 root.name="EntranceGarden"
 art.add_child(root)
 # A composed grove beside the northern entrance: a focal tree, supporting
 # trees behind it, rocks at the roots and low plants toward the courtyard.
 place(root,"TwistedTree_2",Vector3(-25,-1.5,-27),Vector3.ONE*0.66,0.8)
 place(root,"Rock_Medium_2",Vector3(-26,-0.15,-25),Vector3(1.4,0.8,1.1),0.4)
 place(root,"Rock_Medium_3",Vector3(-23,-0.2,-27),Vector3.ONE*0.8,1.8)
 var points=[Vector3(-22,0,-25),Vector3(-25,0,-22),Vector3(-19,0,-26),Vector3(-27,0,-19),Vector3(-26,0,-24)]
 for i in range(points.size()):
  place(root,"Fern_1" if i%2==0 else "Bush_Common_Flowers",points[i],Vector3.ONE*(0.65+i*0.04),i*1.3)
 for i in range(18):
  var angle:float=i*2.399
  var p:=Vector3(-24+cos(angle)*(1.8+i*0.12),0.015,-24+sin(angle)*(1.5+i*0.11))
  place(root,"Grass_Wispy_Short",p,Vector3(0.5,0.28,0.5),angle)
 for i in range(7):
  place(root,"RockPath_Round_Small_1",Vector3(-20+i*0.8,0.008,-22+i*0.55),Vector3(0.7,0.25,0.7),i*0.8)
