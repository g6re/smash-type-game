extends Node3D
var mantle:=0.0
var mantle_progress:=0.0
var mantle_active:=false
var climbing:=false
var crouching:=false
var wall_sliding:=false
var state:="idle"
var elapsed:=0.0
var character:Node3D
var skeleton:Skeleton3D
var rest:Dictionary={}
var sword:Node3D
@export var model_scene:PackedScene
@export var fitted_height:=0.0
@export var has_sword:=true
var base_offset:=Vector3.ZERO
var aliases:Dictionary={}

func _ready() -> void:
	character=model_scene.instantiate()
	add_child(character)
	character.scale=Vector3.ONE*0.82
	# The exported character already faces the controller's -Z direction.
	skeleton=find_skeleton(character)
	assert(skeleton!=null)
	for i in range(skeleton.get_bone_count()):rest[skeleton.get_bone_name(i)]=skeleton.get_bone_pose_rotation(i)
	if fitted_height>0:
		character.scale=Vector3.ONE
		var bounds:=mesh_bounds(character)
		var factor:=fitted_height/maxf(bounds.size.y,0.01)
		character.scale=Vector3.ONE*factor
		base_offset.y=-bounds.position.y*factor
		character.position=base_offset
	style_meshes(character)
	var hand:Node3D=BoneAttachment3D.new() if has_sword else Node3D.new()
	if hand is BoneAttachment3D:hand.bone_name="hand.L"
	skeleton.add_child(hand)
	sword=Node3D.new()
	hand.add_child(sword)
	sword.rotation.z=PI
	for part in [[Vector3(0,0.5,0),Vector3(0.035,0.95,0.018),Color("d9e0df")],[Vector3.ZERO,Vector3(0.18,0.025,0.09),Color("d2a04a")],[Vector3(0,-0.1,0),Vector3(0.055,0.2,0.055),Color("491927")]]:
		var mesh:=MeshInstance3D.new()
		var shape:=BoxMesh.new()
		shape.size=part[1]
		mesh.mesh=shape
		mesh.position=part[0]
		var mat:=StandardMaterial3D.new()
		mat.albedo_color=part[2]
		mesh.material_override=mat
		sword.add_child(mesh)
	sword.hide()

func find_skeleton(n:Node) -> Skeleton3D:
	if n is Skeleton3D:return n
	for child in n.get_children():
		var result:=find_skeleton(child)
		if result!=null:return result
	return null

func style_meshes(n:Node) -> void:
	if n is MeshInstance3D:
		for i in range(n.mesh.get_surface_count()):
			var mat=n.get_active_material(i)
			if mat is BaseMaterial3D:mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	for child in n.get_children():style_meshes(child)

func pose(bone:String,rotation:Vector3) -> void:
	bone=aliases.get(bone,bone)
	var index:=skeleton.find_bone(bone)
	if index>=0:skeleton.set_bone_pose_rotation(index,rest[bone]*Quaternion.from_euler(rotation))

func animate(dt:float,velocity:Vector3,grounded:bool,sliding:bool,dashing:bool,attack:float,combo:int) -> void:
	elapsed+=dt
	mantle=maxf(0,mantle-dt)
	for bone in rest:pose(bone,Vector3.ZERO)
	var speed:=Vector2(velocity.x,velocity.z).length()
	state="idle"
	character.position=base_offset
	if speed>0.3:
		state="walk" if speed<=4 else "run"
		var cycle:=elapsed*(6 if state=="walk" else 11)
		var stride:=0.35 if state=="walk" else 0.65
		for side in ["L","R"]:
			var swing:=sin(cycle+(0 if side=="L" else PI))*stride
			pose("thigh."+side,Vector3(swing,0,0))
			pose("shin."+side,Vector3(maxf(0,-swing)*0.8,0,0))
			pose("upper_arm."+side,Vector3(-swing*0.7,0,0))
		character.position.y+=absf(sin(cycle))*0.025
	else:pose("chest",Vector3(sin(elapsed*2.5)*0.015,0,0))
	if not grounded:
		state="jump" if velocity.y>0 else "fall"
		pose("thigh.L",Vector3(-0.45,0,0))
		pose("shin.L",Vector3(0.8,0,0))
		pose("upper_arm.R",Vector3(-0.6,0,0.25))
	if crouching or sliding:
		state="slide" if sliding else "crouch"
		character.position.y-=0.34
		pose("chest",Vector3(0.4,0,0))
		for side in ["L","R"]:
			pose("thigh."+side,Vector3(-0.7,0,0))
			pose("shin."+side,Vector3(1.0,0,0))
	if mantle_active or mantle>0:
		state="mantle"
		pose("chest",Vector3(0.25*sin(mantle_progress*PI),0,0))
		pose("upper_arm.L",Vector3(-0.65,0,-0.3))
		pose("upper_arm.R",Vector3(-0.65,0,0.3))
	if dashing:pose("chest",Vector3(0.5,0,0))
	sword.visible=attack>0 and has_sword
	if attack>0:
		state="attack"
		var phase:=clampf((0.82-attack)/0.82,0,1)
		var swing:=sin(phase*PI)
		pose("chest",Vector3(0,swing*0.7*(1 if combo!=2 else -1),0))
		pose("upper_arm.L",Vector3(lerpf(-2.2,0.35,phase),0,swing*0.65))
		pose("forearm.L",Vector3(-0.4,0,0))
		character.position.z=-swing*0.18

func emit_ghost(fx:Node3D,_sprite_position:Vector3) -> void:
	fx.ghost_model(character)

func mesh_bounds(n:Node) -> AABB:
	var bounds:=AABB()
	if n is MeshInstance3D:bounds=(character.global_transform.affine_inverse()*n.global_transform)*n.get_aabb()
	for child in n.get_children():
		var next:=mesh_bounds(child)
		if next.size.length()>0:bounds=next if bounds.size.length()==0 else bounds.merge(next)
	return bounds
