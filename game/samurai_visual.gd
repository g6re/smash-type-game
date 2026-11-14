extends "res://game/iso_visual.gd"
var was_airborne:=false
var landing_left:=0.0
var visible_bounds:Dictionary={}
var wall_normal:=Vector3.ZERO
var atlas_offsets:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://samurai/samurai-atlas.json")).offsets

func _ready() -> void:
	animation_frames=preload("res://samurai/base_rotations.tres")
	mirror_left_directions=false
	walk_speed_limit=4.0
	provisional_states=PackedStringArray()
	super._ready()
	sprite.pixel_size=0.031
	sprite.offset=Vector2(0,30)
	sprite.stop()

func animate(dt: float, velocity: Vector3, grounded: bool, sliding: bool, dashing: bool, attack: float, combo: int) -> void:
	if grounded and was_airborne:landing_left=0.14
	was_airborne=not grounded
	landing_left=maxf(0,landing_left-dt)
	super.animate(dt,velocity,grounded,sliding,dashing,attack,combo)
	# Idle and running use authored directional animation cycles.
	if state=="idle":
		if not sprite.is_playing(): sprite.play("idle_%d" % direction_id)
	elif state=="walk" and direction_id==6:
		if not sprite.is_playing(): sprite.play("walk_6")
		sprite.speed_scale=clampf(Vector2(velocity.x,velocity.z).length()/3.0,0.3,1.2)
	elif state=="wall_walk":
		if not sprite.is_playing():sprite.play()
		sprite.speed_scale=1.1
	elif state=="mantle":
		landing_left=0
		sprite.pause()
		sprite.frame=clampi(int(mantle_progress*library.get_frame_count(sprite.animation)),0,library.get_frame_count(sprite.animation)-1)
	elif state in ["jump","fall"]:
		# Match the airborne poses to physics instead of looping takeoff in midair.
		sprite.pause()
		sprite.frame=3 if velocity.y>6 else (4 if velocity.y>2 else (5 if velocity.y>-3 else 6))
	elif state.begins_with("attack"):
		# Parent selects the frame from the hit timer; stop() would reset it.
		sprite.pause()
	elif state in ["run","run_back","strafe_left","strafe_right"]:
		if library.get_frame_count(sprite.animation)>1:
			if not sprite.is_playing():sprite.play()
		else:sprite.stop()
	else:
		sprite.stop()
	if landing_left>0 and state in ["idle","walk","run","run_back","strafe_left","strafe_right"]:
		sprite.animation="jump_%d" % direction_id
		sprite.pause()
		sprite.frame=7 if landing_left>0.07 else 8
	var large_frame:=sprite.animation.begins_with("jump_") or sprite.animation.begins_with("fall_") or state in ["run","run_back","strafe_left","strafe_right"]
	sprite.offset=Vector2(0,32 if large_frame or state=="mantle" else 30)
	if state=="wall_walk" and direction_id!=6:sprite.offset.y=32
	var category:="attack" if state.begins_with("attack") else state
	if state in ["attack2","attack3"] and atlas_offsets.has("followup"):category="followup"
	if category in ["attack","slide","dash","protect","followup"]:
		var direction:String=["south-west","west","north-west","north","north-east","east","south-east","south"][direction_id-1]
		sprite.offset.y=atlas_offsets[category][direction]
	sprite.scale=Vector3.ONE
	sprite.basis=Basis.IDENTITY
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	if state=="wall_walk":
		var camera:=get_viewport().get_camera_3d()
		if camera!=null:
			var lean:float=-wall_normal.dot(camera.global_basis.x)*0.26
			sprite.billboard=BaseMaterial3D.BILLBOARD_DISABLED
			sprite.basis=global_basis.inverse()*camera.global_basis*Basis(Vector3.BACK,lean)
	sprite.position=Vector3(0,0.02,0)
	if hurt_left>0:
		if grounded:
			sprite.animation="idle_%d" % direction_id
			sprite.frame=0
		sprite.pause()
		var recoil:float=clampf(hurt_left/maxf(0.01,hurt_total),0,1)
		sprite.scale=Vector3(1+0.10*recoil,1-0.08*recoil,1)
		var view:=get_viewport().get_camera_3d()
		if view!=null:
			sprite.billboard=BaseMaterial3D.BILLBOARD_DISABLED
			sprite.basis=global_basis.inverse()*view.global_basis*Basis(Vector3.BACK,sin(hurt_left*28)*0.12*recoil)*Basis.from_scale(sprite.scale)
	keep_sprite_outside_walls()
	# Smooth slash accent complements the pixel-art sword.
	slash.visible=state.begins_with("attack") and attack<0.56 and attack>0.24
	if state=="attack3":
		slash.visible=attack<0.60 and attack>0.43
		slash.scale=Vector3.ONE*1.25
	else:slash.scale=Vector3.ONE
	if hurt_left>0:slash.hide()

func keep_sprite_outside_walls() -> void:
	var camera:=get_viewport().get_camera_3d()
	var body:=get_parent().get_parent() as CharacterBody3D
	if camera==null or body==null:return
	var texture:=library.get_frame_texture(sprite.animation,sprite.frame)
	var key:="%s_%d" % [sprite.animation,sprite.frame]
	if not visible_bounds.has(key):visible_bounds[key]=texture.get_image().get_used_rect()
	var rect:Rect2i=visible_bounds[key]
	var origin:Vector3=body.global_position+Vector3.UP*0.95
	var space:=get_world_3d().direct_space_state
	for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
		var query:=PhysicsRayQueryParameters3D.create(origin,origin+direction*2.5)
		query.exclude=[body.get_rid()]
		var hit:=space.intersect_ray(query)
		if hit.is_empty() or absf(hit.normal.y)>0.2:continue
		var normal:Vector3=hit.normal
		var clearance:=INF
		for x in [rect.position.x,rect.end.x]:
			for y in [rect.position.y,rect.end.y]:
				var horizontal:float=float(x)-texture.get_width()*0.5+sprite.offset.x
				var vertical:float=texture.get_height()*0.5-float(y)+sprite.offset.y
				var right:Vector3=sprite.global_basis.x if sprite.billboard==BaseMaterial3D.BILLBOARD_DISABLED else camera.global_basis.x
				var up_axis:Vector3=sprite.global_basis.y if sprite.billboard==BaseMaterial3D.BILLBOARD_DISABLED else camera.global_basis.y
				var corner:Vector3=sprite.global_position+(right*horizontal+up_axis*vertical)*sprite.pixel_size
				clearance=minf(clearance,(corner-hit.position).dot(normal))
		sprite.position+=global_basis.inverse()*normal*maxf(0,0.06-clearance)

