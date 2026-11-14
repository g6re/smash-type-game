extends "res://game/arena.gd"

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _ready() -> void:
	selected_character="samurai"
	use_y2k_character=false
	super._ready()
	await get_tree().create_timer(0.2).timeout
	player.position = Vector3(0,0.05,6)
	key(KEY_C,true)
	await get_tree().create_timer(0.4).timeout
	assert(crouching and is_equal_approx(collider.shape.height,1.0),"C must lower collision")
	assert(visual.state=="crouch","C must play crouch")
	await capture("pixel_crouch.png")
	player.position = Vector3(4,0.02,4)
	key(KEY_C,false)
	await get_tree().create_timer(0.2).timeout
	assert(crouching,"Low ceiling must prevent standing")
	player.position = Vector3(0,0.05,6)
	await get_tree().create_timer(0.2).timeout
	assert(not crouching and is_equal_approx(collider.shape.height,1.8),"Clear space restores standing")
	player.position=Vector3(8,0.05,0)
	yaw=-PI/2
	key(KEY_E,true)
	var before:=player.position.y
	await get_tree().create_timer(0.35).timeout
	assert(not climbing and player.position.y<=before+0.05,"E does not climb walls")
	
	
	assert(is_equal_approx(stamina,3),"Climbing preserves dash/jump bars")
	key(KEY_E,false)
	player.position=Vector3(-4,0.05,5.7)
	player.velocity=Vector3.ZERO
	yaw=0
	assert(start_mantle(Vector3(0,0,-1)),"Low ledge must be mantleable")
	var origin:=player.position
	await get_tree().create_timer(0.15).timeout
	assert(mantle_left>0 and player.position.y>origin.y,"Mantle must interpolate")
	await get_tree().create_timer(0.45).timeout
	assert(player.position.y>1.15 and mantle_left<=0,"Mantle must finish on top")
	for clip in ["idle","run","crouch","mantle","jump","fall","attack1","slide"]:
		assert(visual.sprite.sprite_frames.has_animation(clip+"_4"),"Missing clip "+clip)
	print("PASS: crouch collider, ceiling clearance, no wall climb, stamina, fast mantle, sprite clips")
	get_tree().quit()

func capture(filename: String) -> void:
	if DisplayServer.get_name()=="headless": return
	pivot.position=player.position+Vector3.UP*1.4
	pivot.rotation=Vector3(-0.12,yaw,0)
	camera.position=Vector3(0,0.6,5)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://"+filename)



