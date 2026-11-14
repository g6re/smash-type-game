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

static func make_library() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var clips := {"idle":"Idle","run":"Run","run_back":"RunBack","strafe_left":"RunStrafeLeft","strafe_right":"RunStrafeRight","jump":"Jump","fall":"Jump","crouch":"Crouch","crouch_walk":"Crouch","in_crouch":"InCrouch","out_crouch":"OutCrouch","slide":"CrouchGuard","dash":"RunningJump","climb":"GuardIdle","wall_slide":"GuardIdle","attack1":"Slash","attack2":"BackSlash","attack3":"SpinAttack"}
	for clip in clips:
		var source: String = clips[clip]
		for direction in range(1,9):
			var base := "res://archive/assets/iron_knight/BlueKnightUnarmed/%s/BlueKnight_Unarmed_export_%s_dir%d" % [source,source,direction]
			var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base+".json"))
			var texture := load(base+".png") as Texture2D
			var name := "%s_%d" % [clip,direction]
			frames.add_animation(name)
			frames.set_animation_speed(name,1)
			frames.set_animation_loop(name,not clip in ["jump","in_crouch","out_crouch","attack1","attack2","attack3"])
			var entries: Array = metadata.frames
			if clip == "fall": entries = entries.slice(maxi(0,entries.size()-3))
			for entry in entries:
				var region: Dictionary = entry.frame
				var tile := AtlasTexture.new()
				tile.atlas=texture
				tile.region=Rect2(region.x,region.y,region.w,region.h)
				frames.add_frame(name,tile,float(entry.duration))
	return frames

func _ready() -> void:
	if library == null: library=make_library()
	sprite=AnimatedSprite3D.new()
	add_child(sprite)
	sprite.sprite_frames=library
	sprite.pixel_size=0.037
	sprite.position.y=0.02
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.offset=Vector2(0,-8)
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

