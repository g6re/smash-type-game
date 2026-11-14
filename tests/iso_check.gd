extends "res://game/arena.gd"
func _ready() -> void:
	super._ready()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.25).timeout
	var seen: Array[int]=[]
	for i in range(8):
		model.rotation.y=i*PI/4
		visual.animate(0.016,Vector3.ZERO,true,false,false,0,1)
		seen.append(visual.direction_id)
		assert(visual.sprite.sprite_frames.has_animation("run_%d" % visual.direction_id))
	assert(seen.size()==8 and not seen.has(0))
	for id in range(1,9): assert(seen.has(id),"Missing facing "+str(id))
	var camera_basis:=Basis(Vector3.UP,0.7)
	assert(preload("res://game/iso_visual.gd").facing_direction(-camera_basis.z,camera_basis)==4)
	assert(preload("res://game/iso_visual.gd").facing_direction(camera_basis.z,camera_basis)==8)
	print(visual.sprite.animation, " ", visual.sprite.scale, " ", visual.sprite.get_aabb(), " ", visual.sprite.sprite_frames.get_frame_texture(visual.sprite.animation,0))
	print("PASS: eight distinct facings and camera-relative front/back")
	if DisplayServer.get_name()!="headless":
		player.position=Vector3(0,0.05,6)
		model.rotation.y=PI
		yaw=0
		pitch=-0.2
		await get_tree().create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/iso_front.png")
		model.rotation.y=0
		await get_tree().create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/iso_back.png")
	if DisplayServer.get_name()!="headless":
		pitch=-1.0
		await get_tree().create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/iso_above.png")
	get_tree().quit()



