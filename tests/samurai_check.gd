extends "res://game/arena.gd"
func _ready() -> void:
	use_y2k_character=false
	selected_character="samurai"
	super._ready()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.25).timeout
	# Isolate authored visual states from the player's initial fall to the floor.
	set_physics_process(false)
	var seen: Array[int]=[]
	for i in range(8):
		model.rotation.y=i*PI/4
		visual.animate(0.016,Vector3.ZERO,true,false,false,0,1)
		if i>0:
			assert(visual.sprite.frame==2 and is_equal_approx(visual.sprite.frame_progress,0.4),"Turning preserves the idle phase")
		seen.append(visual.direction_id)
		assert(visual.sprite.sprite_frames.get_frame_count("idle_%d" % visual.direction_id)==6)
		assert(visual.sprite.is_playing())
		assert(not visual.sprite.flip_h)
		var directions:=["south-west","west","north-west","north","north-east","east","south-east","south"]
		var original:Image=load("res://samurai/Idle/base/%s.png" % directions[visual.direction_id-1]).get_image()
		for f in range(6):
			var pose:Image=visual.sprite.sprite_frames.get_frame_texture(visual.sprite.animation,f).get_image()
			for y in range(44,64):
				for x in range(64):
					var source_color:=original.get_pixel(x,y)
					var frame_color:=pose.get_pixel(x,y)
					assert(frame_color.a==source_color.a and (source_color.a==0 or frame_color==source_color),"Feet and lower body stay anchored")
		visual.sprite.set_frame_and_progress(0,0)
		await get_tree().create_timer(0.36).timeout
		assert(visual.sprite.frame>0,"Every directional idle must advance over time")
		visual.animate(0.016,Vector3(8,0,0),true,false,false,0,1)
		assert(not visual.sprite.is_playing(),"Movement still uses the base pose")
		visual.animate(0.016,Vector3.ZERO,true,false,false,0,1)
		assert(visual.sprite.is_playing(),"Idle resumes after movement")
		visual.sprite.set_frame_and_progress(2,0.4)
	assert(seen.size()==8 and not seen.has(0))
	for id in range(1,9): assert(seen.has(id),"Missing facing "+str(id))
	var camera_basis:=Basis(Vector3.UP,0.7)
	assert(preload("res://game/iso_visual.gd").facing_direction(-camera_basis.z,camera_basis)==4)
	assert(preload("res://game/iso_visual.gd").facing_direction(camera_basis.z,camera_basis)==8)
	print(visual.sprite.animation, " ", visual.sprite.scale, " ", visual.sprite.get_aabb(), " ", visual.sprite.sprite_frames.get_frame_texture(visual.sprite.animation,0))
	print("PASS: eight distinct facings, eight animated idle views, movement and idle transitions")
	set_physics_process(true)
	if DisplayServer.get_name()!="headless":
		player.position=Vector3(0,0.05,6)
		model.rotation.y=PI
		yaw=0
		pitch=-0.2
		await get_tree().create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/samurai_front.png")
		model.rotation.y=0
		await get_tree().create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/samurai_back.png")
	if DisplayServer.get_name()!="headless":
		pitch=-1.0
		await get_tree().create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/samurai_above.png")
	get_tree().quit()








