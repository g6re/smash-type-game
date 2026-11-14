extends "res://game/arena.gd"
var stage:Node3D
func _ready() -> void:
 super._ready()
 var lighting:=Node3D.new()
 lighting.set_script(preload("res://maps/hollow_bastion/lighting.gd"))
 lighting.arena=self
 add_child(lighting)

func build_map() -> void:
 enable_grind_rail=false
 spawn=Vector3(0,0.3,4)
 stage=preload("res://maps/hollow_bastion/assets/scene.gltf").instantiate()
 add_child(stage)
 stage.name="HollowBastionModel"
 add_stage_collision(stage)

func add_stage_collision(node:Node) -> void:
 # Only the fighting platforms are solid. The castle under the stage is scenery.
 if node is MeshInstance3D and node.name in ["Cube_Material_003_0","Cube_017_Material_003_0"]:
  node.create_trimesh_collision()
 for child in node.get_children():
  if not child is StaticBody3D:add_stage_collision(child)
