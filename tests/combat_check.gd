extends "res://game/arena.gd"
func _ready() -> void:
	use_y2k_character=false
	selected_character="samurai"
	super._ready()
	await get_tree().physics_frame
	player.position = Vector3(0, 0.05, 3)
	player.velocity = Vector3.ZERO
	enemies[0].body.position = Vector3(0, 1, 1.3)
	combo = 1
	attack_time = 0.82
	await get_tree().create_timer(0.65).timeout
	assert(enemies[0].damage > 0, "Melee must hit front target")
	assert(ultimate_charge>0,"Melee hits charge ultimate")
	var first_damage: float = enemies[0].damage
	await get_tree().create_timer(0.2).timeout
	assert(enemies[0].damage == first_damage, "Single attack must not hit twice")
	for state in range(6):
		visual.mantle = 0.2 if state == 5 else 0
		visual.animate(0.016, Vector3(0, 2, -8), state == 0, state == 1, state == 2, 0.4 if state == 3 else 0.0, 3)
	set_physics_process(false)
	visual.mantle=0
	visual.climbing=false
	visual.crouching=false
	visual.wall_sliding=false
	visual.posture_time=0
	visual.previous_crouch=false
	for direction in range(8):
		model.rotation.y=direction*PI/4
		for attack_combo in range(1,4):
			for frame in range(9):
				var remaining:=0.82-(frame+0.1)*(0.82/9.0)
				visual.animate(0.016,Vector3.ZERO,true,false,false,remaining,attack_combo)
				assert(visual.state=="attack%d" % attack_combo)
				assert(visual.sprite.sprite_frames.get_frame_count(visual.sprite.animation)==9)
				assert(visual.sprite.frame==frame,"Attack frame follows damage timer without resetting")
				assert(visual.sprite.offset.y==visual.atlas_offsets["followup" if attack_combo==2 else "attack"][["south-west","west","north-west","north","north-east","east","south-east","south"][visual.direction_id-1]],"Padded attack keeps feet anchored")
				assert(visual.slash.visible==(remaining<0.56 and remaining>0.24))
	visual.animate(0.016,Vector3.ZERO,true,false,false,0,1)
	assert(visual.state=="idle" and visual.sprite.is_playing())
	assert(visual.sprite.offset==Vector2(0,30))
	print("PASS: melee damage, one hit per swing, eight directional attack clips, timed frames, return to idle")
	get_tree().quit()





