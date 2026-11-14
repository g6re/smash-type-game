extends "res://game/arena.gd"
func _ready() -> void:
	selected_character="box"
	super._ready()
	set_physics_process(false)
	await get_tree().physics_frame
	player.position=Vector3(8,0.05,0)
	await get_tree().physics_frame
	assert(not start_mantle(Vector3.RIGHT),"Tall walls cannot be climbed")
	var press:=InputEventKey.new()
	press.keycode=KEY_E
	press.physical_keycode=KEY_E
	press.pressed=true
	Input.parse_input_event(press)
	await get_tree().process_frame
	move_player(0.1)
	press.pressed=false
	Input.parse_input_event(press.duplicate())
	assert(not climbing and player.velocity.y<=0,"E never moves the player up a wall")
	player.position=Vector3(-4,0.05,5.7)
	player.velocity=Vector3(0,0,-8)
	await get_tree().physics_frame
	var before:=player.position
	var bars:=stamina
	assert(start_mantle(Vector3.FORWARD),"Reachable ledge starts mantle")
	assert(player.position==before,"Starting mantle does not teleport")
	assert(mantle_duration<=0.34 and mantle_duration>=0.22)
	assert(not start_mantle(Vector3.FORWARD),"Cannot restart a mantle")
	var highest_hand_distance:=0.0
	for frame in range(40):
		await get_tree().physics_frame
		if mantle_left<=0:break
		move_player(0.01)
		visual.animate(0.01,player.velocity,false,false,false,0,1)
		if mantle_left>0:
			assert(visual.state=="mantle")
			for side in ["L","R"]:
				assert(visual.joint_position("hand."+side).distance_to(visual.joint_position("head"))>0.22,"Hands stay outside the box head")
	assert(mantle_left==0 and player.position.y>1.2)
	assert(player.position.distance_to(mantle_end)<0.05)
	assert(player.velocity.z<-7.9,"Mantle preserves forward momentum")
	assert(stamina==bars,"Mantle does not consume dash/air-jump bars")
	player.position=before
	platform(Vector3(2,0.4,2),Vector3(-4,2.3,4.5),Color.GRAY)
	await get_tree().physics_frame
	assert(not start_mantle(Vector3.FORWARD),"Blocked landing is rejected")
	print("PASS: no wall climbing, fast swept mantle, momentum, head clearance, stamina and blocked landing")
	get_tree().quit()


