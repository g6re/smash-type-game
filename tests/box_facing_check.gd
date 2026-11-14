extends "res://game/arena.gd"
func _ready() -> void:
	selected_character="box"
	super._ready()
	set_physics_process(false)
	player.collision_mask=0
	var press:=InputEventKey.new()
	press.keycode=KEY_W
	press.physical_keycode=KEY_W
	press.pressed=true
	Input.parse_input_event(press.duplicate())
	await get_tree().process_frame
	assert(Input.is_physical_key_pressed(KEY_W))
	var aligned:=true
	for camera_yaw in [0.0,0.7,1.5]:
		yaw=camera_yaw
		player.position=Vector3(0,8,6)
		player.velocity=Vector3.ZERO
		mantle_left=0
		for frame in range(20):
			await get_tree().physics_frame
			move_player(1.0/60)
		var movement:=Vector3(player.velocity.x,0,player.velocity.z).normalized()
		# +Z is the mesh's authored face/toe direction, not the controller's axis.
		var face:Vector3=visual.character.global_basis.z.normalized()
		face.y=0
		aligned=aligned and face.normalized().dot(movement)>0.99
	press.pressed=false
	Input.parse_input_event(press.duplicate())
	assert(aligned,"Box face and toes must point along forward movement")
	print("PASS: Box faces forward when pressing W across three camera angles")
	get_tree().quit()

func start_mantle(_front:Vector3) -> bool:
	return false


