extends "res://game/arena.gd"

func _ready() -> void:
	use_y2k_character=false
	selected_character="samurai"
	super._ready()
	set_physics_process(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	for i in range(8):
		model.rotation.y=i*PI/4
		visual.animate(0.016,Vector3(3,0,0),true,false,false,0,1)
		if visual.direction_id==6:break
	assert(visual.direction_id==6)
	assert(visual.state=="walk" and visual.sprite.animation=="walk_6")
	assert(visual.sprite.sprite_frames.get_frame_count("walk_6")==17)
	assert(visual.sprite.is_playing() and not visual.sprite.flip_h)
	visual.sprite.set_frame_and_progress(0,0)
	await get_tree().create_timer(0.15).timeout
	assert(visual.sprite.frame>0,"East walking advances")
	visual.animate(0.016,Vector3(8,0,0),true,false,false,0,1)
	assert(visual.state!="walk" and not visual.sprite.is_playing(),"Running does not reuse walking")
	visual.animate(0.016,Vector3(3,0,0),true,false,false,0.4,1)
	assert(visual.state.begins_with("attack"),"Attacks override walking")
	visual.animate(0.016,Vector3(3,2,0),false,false,false,0,1)
	assert(visual.state=="jump")
	for i in range(8):
		model.rotation.y=i*PI/4
		visual.animate(0.016,Vector3(3,0,0),true,false,false,0,1)
		assert(not visual.sprite.flip_h,"Asymmetric character is never mirrored")
		if visual.direction_id!=6:
			assert(not visual.sprite.is_playing())
			assert(visual.sprite.sprite_frames.get_frame_count(visual.sprite.animation)==1)
	visual.animate(0.016,Vector3.ZERO,true,false,false,0,1)
	assert(visual.state=="idle" and visual.sprite.is_playing())
	print("PASS: 17-frame east walking, separate running, traversal/attack priority, no mirroring")
	get_tree().quit()


