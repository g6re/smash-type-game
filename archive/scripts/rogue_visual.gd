extends Node3D

static var library: SpriteFrames
var sprite: AnimatedSprite3D
var shadow: MeshInstance3D
var mantle := 0.0
var climbing := false
var crouching := false
var wall_sliding := false
var state := "idle"
var direction_id := 4
var elapsed := 0.0
var posture_time := 0.0
var previous_crouch := false
var transition := ""
var slash: MeshInstance3D
var effect_material: StandardMaterial3D

static func make_library() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var directions := ["south-west","west","north-west","north","north-east","east","south-east","south"]
	var clips := ["idle","run","run_back","strafe_left","strafe_right","jump","fall","crouch","crouch_walk","in_crouch","out_crouch","slide","dash","climb","wall_slide","attack1","attack2","attack3"]
	for clip in clips:
		var source := "walk" if clip in ["run","run_back","strafe_left","strafe_right","crouch_walk","dash","climb"] else "idle"
		for direction in range(1,9):
			var folder := "res://archive/assets/pixel_rogue/rogue-hero-128/%s_%s/" % [source,directions[direction-1]]
			var files := DirAccess.get_files_at(folder)
			files.sort()
			var name := "%s_%d" % [clip,direction]
			frames.add_animation(name)
			frames.set_animation_speed(name,12 if source == "walk" else 8)
			frames.set_animation_loop(name, true)
			for file in files:
				if file.ends_with(".png"):
					frames.add_frame(name,load(folder+file))
	return frames

func _ready() -> void:
	if library == null: library=make_library()
	sprite=AnimatedSprite3D.new()
	add_child(sprite)
	sprite.sprite_frames=library
	sprite.pixel_size=0.0145
	sprite.position.y=0.02
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.offset=Vector2(0,64)
	sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded=false
	sprite.play("idle_4")
	shadow=MeshInstance3D.new()
	var circle:=CylinderMesh.new()
	circle.top_radius=0.35
	circle.bottom_radius=0.35
	circle.height=0.008
	shadow.mesh=circle
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color(0.02,0.025,0.04,0.5)
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override=mat
	add_child(shadow)
	shadow.position.y=0.012
	slash=MeshInstance3D.new()
	add_child(slash)
	effect_material=StandardMaterial3D.new()
	effect_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	effect_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	effect_material.albedo_color=Color(0.65,0.91,0.94,0.55)
	effect_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	slash.material_override=effect_material


static func facing_direction(forward: Vector3, camera_basis: Basis) -> int:
	var right:=Vector3(camera_basis.x.x,0,camera_basis.x.z).normalized()
	var toward:=Vector3(camera_basis.z.x,0,camera_basis.z.z).normalized()
	var angle:=atan2(forward.dot(right),forward.dot(toward))
	var sector:=posmod(int(round(angle/(PI/4))),8)
	return [8,7,6,5,4,3,2,1][sector]

func animate(dt: float, velocity: Vector3, grounded: bool, sliding: bool, dashing: bool, attack: float, combo: int) -> void:
	elapsed+=dt
	mantle=maxf(0,mantle-dt)
	posture_time=maxf(0,posture_time-dt)
	shadow.visible=grounded
	if crouching != previous_crouch:
		transition="in_crouch" if crouching else "out_crouch"
		posture_time=0.30
		previous_crouch=crouching
	var camera:=get_viewport().get_camera_3d()
	if camera != null: direction_id=facing_direction(-global_basis.z,camera.global_basis)
	var next:="idle"
	var speed:=Vector2(velocity.x,velocity.z).length()
	if speed>0.3:
		next="run"
		var local:=global_basis.inverse()*velocity
		if local.z>speed*0.6: next="run_back"
		elif absf(local.x)>speed*0.6: next="strafe_left" if local.x<0 else "strafe_right"
	if not grounded: next="jump" if velocity.y>0 else "fall"
	if wall_sliding: next="wall_slide"
	if dashing: next="dash"
	if attack>0: next="attack%d" % combo
	if crouching and grounded: next="crouch_walk" if speed>0.3 else "crouch"
	if posture_time>0 and grounded: next=transition
	if sliding: next="slide"
	if climbing or mantle>0: next="climb"
	var full:="%s_%d" % [next,direction_id]
	if sprite.animation!=full:
		var old_frame:=sprite.frame
		var old_progress:=sprite.frame_progress
		var same_state:=state==next
		sprite.play(full)
		if same_state: sprite.set_frame_and_progress(mini(old_frame,library.get_frame_count(full)-1),old_progress)
	state=next
	if attack>0 and next.begins_with("attack"):
		sprite.pause()
		var count:=library.get_frame_count(full)
		sprite.frame=clampi(int((0.82-attack)/0.82*count),0,count-1)
	sprite.speed_scale=clampf(speed/7,0.6,1.4) if next in ["run","run_back","strafe_left","strafe_right"] else 1.0
	sprite.position.y=0.02
	if next=="climb": sprite.position.y+=sin(elapsed*14)*0.035


	# This asset only supplies idle/walk. Traversal and attacks use provisional
	# transforms over those frames rather than pretending to be authored clips.
	var desired_height := 0.66 if crouching or sliding else 1.0
	sprite.scale.y=lerpf(sprite.scale.y,desired_height,1-exp(-dt*20))
	sprite.position.z=0
	if attack>0:
		var phase:=clampf((0.82-attack)/0.82,0,1)
		sprite.position.z=-sin(phase*PI)*0.20
	slash.visible=attack<0.56 and attack>0.24
	if slash.visible:
		var mesh:=ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var phase:=clampf((0.82-attack)/0.82,0,1)
		var angle: float=lerpf(-1.2,1.2,phase)*(1 if combo!=2 else -1)
		for step in range(14):
			var a0:=angle-float(step)*0.035
			var a1:=a0-0.035
			var outer0:=Vector3(sin(a0)*2.1,1.0,-cos(a0)*2.1)
			var outer1:=Vector3(sin(a1)*2.1,1.0,-cos(a1)*2.1)
			var inner0:=Vector3(sin(a0)*1.8,1.0,-cos(a0)*1.8)
			var inner1:=Vector3(sin(a1)*1.8,1.0,-cos(a1)*1.8)
			for v in [outer0,inner0,outer1,outer1,inner0,inner1]: mesh.surface_add_vertex(v)
		mesh.surface_end()
		slash.mesh=mesh


