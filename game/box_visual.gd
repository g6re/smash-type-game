extends "res://game/y2k_visual.gd"
var magic:Node3D
var animation_player:AnimationPlayer
var source_clip:StringName
var arm_rest:Dictionary={}
var mantle_hands:Array[Vector3]=[]

func _ready() -> void:
	model_scene=preload("res://box/scene.gltf")
	fitted_height=1.85
	has_sword=false
	super._ready()
	# The downloaded mesh faces +Z; gameplay forward is -Z.
	character.rotation.y=PI
	var mapping:={"head":"Head_","chest":"Spine2_","thigh.L":"LeftUpLeg_","thigh.R":"RightUpLeg_","shin.L":"LeftLeg_","shin.R":"RightLeg_","upper_arm.L":"LeftArm_","upper_arm.R":"RightArm_","forearm.L":"LeftForeArm_","forearm.R":"RightForeArm_","hand.L":"LeftHand_","hand.R":"RightHand_"}
	for canonical in mapping:
		for bone in rest:
			if mapping[canonical] in bone:aliases[canonical]=bone
	# Find the bone axis that lowers each arm; imported rigs use different axes.
	for side in ["L","R"]:
		var hand_index:=-1
		for bone in rest:
			if ("LeftHand_" if side=="L" else "RightHand_") in bone:hand_index=skeleton.find_bone(bone)
		var best_height:=INF
		var best:=Vector3.ZERO
		if hand_index>=0:
			for axis in [Vector3.RIGHT,Vector3.UP,Vector3.BACK]:
				for angle in [-1.3,1.3]:
					pose("upper_arm."+side,axis*angle)
					var height:float=(skeleton.global_transform*skeleton.get_bone_global_pose(hand_index).origin).y
					if height<best_height:best_height=height;best=axis*angle
		arm_rest[side]=best
		pose("upper_arm."+side,Vector3.ZERO)
	animation_player=character.find_child("AnimationPlayer",true,false) as AnimationPlayer
	if animation_player!=null:
		for clip in animation_player.get_animation_list():
			if clip!=&"RESET":source_clip=clip;break
		if source_clip!=&"":
			animation_player.get_animation(source_clip).loop_mode=Animation.LOOP_LINEAR
	magic=Node3D.new()
	add_child(magic)
	magic.position=Vector3(-0.23,1.15,-0.35)
	var ring:=MeshInstance3D.new()
	var torus:=TorusMesh.new()
	torus.inner_radius=0.19
	torus.outer_radius=0.22
	ring.mesh=torus
	ring.rotation.x=PI/2
	var mat:=StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color("ad70ff")
	mat.emission_enabled=true
	mat.emission=Color("ad70ff")
	ring.material_override=mat
	magic.add_child(ring)
	magic.hide()

func animate(dt:float,velocity:Vector3,grounded:bool,sliding:bool,dashing:bool,attack:float,combo:int) -> void:
	if animation_player!=null:animation_player.pause()
	super.animate(dt,velocity,grounded,sliding,dashing,attack,combo)
	if state in ["idle","walk","run"]:
		for side in ["L","R"]:
			pose("upper_arm."+side,arm_rest[side])
			pose("forearm."+side,Vector3.ZERO)
			var phase:float=elapsed*(6 if state=="walk" else 11)+(0 if side=="L" else PI)
			var swing:float=sin(phase)*0.22 if state=="run" else 0.0
			var shoulder:=joint_position("upper_arm."+side)
			var right:=global_basis.x.normalized()
			var sign:=1.0 if (shoulder-global_position).dot(right)>0 else -1.0
			if state=="run":
				var target:=global_position+Vector3.UP*0.99+right*sign*0.43-global_basis.z.normalized()*swing
				solve_arm(side,target)
			else:
				# Relaxed walk: both hands meet behind the lower back.
				var target:=global_position+Vector3.UP*1.0+right*sign*0.055+global_basis.z.normalized()*0.28
				solve_arm(side,target,1.0,right*sign*0.25+Vector3.DOWN*0.8+global_basis.z*0.3)
	sword.hide()
	if state=="mantle":
		for side in ["L","R"]:
			pose("upper_arm."+side,arm_rest[side])
			pose("forearm."+side,Vector3.ZERO)
		if mantle_progress<0.55 and mantle_hands.size()==2:
			for side in ["L","R"]:
				var shoulder:=joint_position("upper_arm."+side)
				var target:Vector3=mantle_hands[0] if shoulder.distance_to(mantle_hands[0])<shoulder.distance_to(mantle_hands[1]) else mantle_hands[1]
				solve_arm(side,target,1.0-smoothstep(0.2,0.55,mantle_progress))

func set_mantle_hands(point:Vector3,right:Vector3) -> void:
	mantle_hands=[point-right*0.32,point+right*0.32]

func joint_position(name:String) -> Vector3:
	var index:=skeleton.find_bone(aliases.get(name,name))
	return skeleton.global_transform*skeleton.get_bone_global_pose(index).origin

func aim_joint(name:String,child:String,target:Vector3) -> void:
	var index:=skeleton.find_bone(aliases[name])
	var origin:=joint_position(name)
	var from:Vector3=(joint_position(child)-origin).normalized()
	var to:Vector3=(target-origin).normalized()
	var delta:=Basis(Quaternion(from,to))
	var current:=skeleton.global_transform*skeleton.get_bone_global_pose(index)
	var parent:=skeleton.get_bone_parent(index)
	var parent_world:=skeleton.global_transform*(skeleton.get_bone_global_pose(parent) if parent>=0 else Transform3D.IDENTITY)
	var local:=skeleton.get_bone_rest(index).basis.inverse()*parent_world.basis.inverse()*delta*current.basis
	skeleton.set_bone_pose_rotation(index,local.orthonormalized().get_rotation_quaternion())

func solve_arm(side:String,target:Vector3,weight:float=1.0,bend_hint:Vector3=Vector3.ZERO) -> void:
	var upper:="upper_arm."+side
	var lower:="forearm."+side
	var hand:="hand."+side
	var upper_index:=skeleton.find_bone(aliases[upper])
	var lower_index:=skeleton.find_bone(aliases[lower])
	var neutral_upper:=skeleton.get_bone_pose_rotation(upper_index)
	var neutral_lower:=skeleton.get_bone_pose_rotation(lower_index)
	var shoulder:=joint_position(upper)
	var elbow:=joint_position(lower)
	var wrist:=joint_position(hand)
	var a:=shoulder.distance_to(elbow)
	var b:=elbow.distance_to(wrist)
	var offset:=target-shoulder
	var distance:=clampf(offset.length(),absf(a-b)+0.01,a+b-0.01)
	var direction:=offset.normalized()
	var outward:=global_basis.x*(1 if (shoulder-global_position).dot(global_basis.x)>0 else -1)
	if bend_hint.length()>0:outward=bend_hint.normalized()
	var bend:Vector3=(outward-direction*outward.dot(direction)).normalized()
	if bend.length()<0.1:bend=global_basis.z
	var along:=(a*a-b*b+distance*distance)/(2*distance)
	var desired_elbow:=shoulder+direction*along+bend*sqrt(maxf(0,a*a-along*along))
	aim_joint(upper,lower,desired_elbow)
	aim_joint(lower,hand,shoulder+direction*distance)
	skeleton.set_bone_pose_rotation(upper_index,neutral_upper.slerp(skeleton.get_bone_pose_rotation(upper_index),weight))
	skeleton.set_bone_pose_rotation(lower_index,neutral_lower.slerp(skeleton.get_bone_pose_rotation(lower_index),weight))

func set_casting(active:bool,power:float) -> void:
	magic.visible=active
	magic.scale=Vector3.ONE*(0.8+power*0.9)
	magic.rotation.z=elapsed*3
	if active:
		pose("upper_arm.L",Vector3(-0.8,0,-0.4))
		pose("forearm.L",Vector3(-0.8,0,0))

func set_parkour_pose(wallrun:bool,grind:bool) -> void:
	if grind:
		pose("chest",Vector3(0.15,0,0))
		pose("thigh.L",Vector3(-0.2,0,0))
		pose("thigh.R",Vector3(-0.15,0,0))
		for side in ["L","R"]:
			pose("upper_arm."+side,arm_rest[side])
			pose("forearm."+side,Vector3.ZERO)
			var shoulder:=joint_position("upper_arm."+side)
			var right:=global_basis.x.normalized()
			var sign:=1.0 if (shoulder-global_position).dot(right)>0 else -1.0
			solve_arm(side,global_position+Vector3.UP*1.23+right*sign*0.50)
		state="grind"
	elif wallrun:
		pose("chest",Vector3(0.12,0,0.08))
		state="wallrun"
