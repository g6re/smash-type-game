extends "res://game/arena.gd"
func _ready() -> void:
	use_y2k_character=false
	selected_character="samurai"
	super._ready()
	set_physics_process(false)
	var frames:SpriteFrames=visual.library
	for name in frames.get_animation_names():
		for f in range(frames.get_frame_count(name)):
			var texture:=frames.get_frame_texture(name,f) as AtlasTexture
			assert(texture!=null and texture.atlas.resource_path=="res://samurai/samurai-atlas.png")
	var dirs:=["south-west","west","north-west","north","north-east","east","south-east","south"]
	for i in range(8):
		var imported:=frames.get_frame_texture("run_%d" % (i+1),0).get_image()
		assert(frames.get_frame_count("run_%d" % (i+1))==6)
		assert(imported.get_size()==Vector2i(96,96))
	for i in range(8):
		model.rotation.y=i*PI/4
		visual.animate(0.016,-model.global_basis.z*8,true,false,false,0,1)
		assert(visual.state=="run" and not visual.sprite.flip_h)
		assert(visual.sprite.animation=="run_%d" % visual.direction_id)
	for i in range(8):
		assert(frames.get_frame_count("mantle_%d" % (i+1))==9)
		model.rotation.y=i*PI/4
		visual.mantle_active=true
		for progress in [0.0,0.5,1.0]:
			visual.mantle_progress=progress
			visual.animate(0.016,Vector3.ZERO,false,false,false,0,1)
			assert(visual.state=="mantle" and visual.sprite.frame==clampi(int(progress*9),0,8))
			assert(not visual.sprite.flip_h and visual.sprite.offset==Vector2(0,32))
		visual.mantle_active=false
	assert(frames.get_frame_count("walk_6")==17)
	for i in range(8):
		assert(frames.get_frame_count("jump_%d" % (i+1))==9)
		assert(frames.get_frame_count("fall_%d" % (i+1))==9)
		model.rotation.y=i*PI/4
		visual.animate(0.016,Vector3(0,10,0),false,false,false,0,1)
		assert(visual.state=="jump" and visual.sprite.frame==3)
		visual.animate(0.016,Vector3(0,-5,0),false,false,false,0,1)
		assert(visual.state=="fall" and visual.sprite.frame==6)
		visual.animate(0.016,Vector3.ZERO,true,false,false,0,1)
		assert(visual.sprite.frame==7 and visual.sprite.animation.begins_with("jump_"))
		visual.animate(0.2,Vector3.ZERO,true,false,false,0,1)
		assert(visual.sprite.animation.begins_with("idle_"))
	print("PASS: all character states share one atlas, six running frames in eight directions, no mirroring")
	get_tree().quit()





