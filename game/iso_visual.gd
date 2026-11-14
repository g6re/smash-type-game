extends Node3D

var library: SpriteFrames
@export var animation_frames: SpriteFrames
@export var provisional_states := PackedStringArray(["jump", "fall", "crouch", "crouch_walk", "in_crouch", "out_crouch", "slide", "dash", "climb", "wall_slide", "attack1", "attack2", "attack3"])
@export var mirror_left_directions := true
@export var walk_speed_limit := 0.0
var sprite: AnimatedSprite3D
var shadow: MeshInstance3D
var mantle := 0.0
var mantle_progress:=0.0
var mantle_active:=false
var climbing := false
var crouching := false
var wall_sliding := false
var wall_running:=false
var protecting:=false
var state := "idle"
var direction_id := 4
var elapsed := 0.0
var posture_time := 0.0
var previous_crouch := false
var transition := ""
var slash: MeshInstance3D
var effect_material: StandardMaterial3D

func _ready() -> void:
	library=animation_frames if animation_frames != null else load("res://character_base/animations.tres")
	sprite=get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if sprite==null:
		sprite=AnimatedSprite3D.new()
		add_child(sprite)
	sprite.sprite_frames=library
	sprite.pixel_size=0.035
	sprite.position.y=0.02
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.offset=Vector2(0,31)
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

var hurt_left:=0.0
var hurt_total:=0.0
func react_to_hit(duration:float) -> void:
	hurt_left=duration
	hurt_total=duration

func animate(dt: float, velocity: Vector3, grounded: bool, sliding: bool, dashing: bool, attack: float, combo: int) -> void:
	if not sprite.is_playing() and attack<=0:sprite.play()
	hurt_left=maxf(0,hurt_left-dt)
	sprite.modulate=Color(2,1.7,1.4) if hurt_total-hurt_left<0.07 and hurt_left>0 else (Color(1,0.55,0.5) if hurt_left>0 else Color.WHITE)
	elapsed+=dt
	mantle=maxf(0,mantle-dt)
	posture_time=maxf(0,posture_time-dt)
	shadow.visible=grounded
	if crouching != previous_crouch:
		transition="in_crouch" if crouching else "out_crouch"
		posture_time=0.30
		previous_crouch=crouching
	var camera:=get_viewport().get_camera_3d()
	if camera != null:
		var facing:Vector3=-global_basis.z
		direction_id=facing_direction(facing,camera.global_basis)
	sprite.flip_h = mirror_left_directions and direction_id in [5,6,7]
	var next:="idle"
	var speed:=Vector2(velocity.x,velocity.z).length()
	if speed>0.3:
		next="run"
		var local:=global_basis.inverse()*velocity
		if local.z>speed*0.6: next="run_back"
		elif absf(local.x)>speed*0.6: next="strafe_left" if local.x<0 else "strafe_right"
		if walk_speed_limit>0 and speed<=walk_speed_limit: next="walk"
	if not grounded: next="jump" if velocity.y>0 else "fall"
	if wall_sliding: next="wall_slide"
	if wall_running and library.has_animation("wall_walk_%d" % direction_id):next="wall_walk"
	if dashing: next="dash"
	if attack>0: next="attack%d" % combo
	if crouching and grounded: next="crouch_walk" if speed>0.3 else "crouch"
	if posture_time>0 and grounded: next=transition
	if sliding: next="slide"
	if mantle_active or mantle>0: next="mantle" if library.has_animation("mantle_%d" % direction_id) else "climb"
	if protecting and library.has_animation("protect_%d" % direction_id):next="protect"
	var full:="%s_%d" % [next,direction_id]
	if next=="attack3":full="attack2_%d" % direction_id
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
		var duration:=1.05 if combo==3 else 0.82
		sprite.frame=clampi(int((duration-attack)/duration*count),0,count-1)
	sprite.speed_scale=clampf(speed/(3.0 if next=="walk" else 7.0),0.35,1.5) if next in ["walk","run","run_back","strafe_left","strafe_right","crouch_walk"] else 1.0
	sprite.position.y=0.02
	if next=="climb" and state in provisional_states: sprite.position.y+=sin(elapsed*14)*0.035


	# This asset only supplies idle/walk/run. Traversal and attacks use provisional
	# transforms over those frames rather than pretending to be authored clips.
	var desired_height := 0.66 if (crouching or sliding) and state in provisional_states else 1.0
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






