extends SceneTree
func _initialize() -> void:
	var frames:=SpriteFrames.new()
	frames.remove_animation("default")
	var directions:=["south-west","west","north-west","north","north-east","east","south-east","south"]
	var texture:Texture2D=load("res://samurai/samurai-atlas.png")
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://samurai/samurai-atlas.json"))
	var animations:Dictionary=manifest.animations
	var run_timing:Dictionary=manifest.timings.run
	var clips:=["idle","walk","run","run_back","strafe_left","strafe_right","jump","fall","crouch","crouch_walk","in_crouch","out_crouch","slide","dash","mantle","wall_slide","wall_walk","protect","attack1","attack2","attack3"]
	for state in clips:
		for i in range(8):
			var direction:String=directions[i]
			var name:="%s_%d" % [state,i+1]
			frames.add_animation(name)
			var category:="base"
			if state=="idle":category="idle"
			elif state=="walk" and direction=="east":category="walk"
			elif state in ["run","run_back","strafe_left","strafe_right"]:category="run"
			elif state in ["jump","fall"]:category="jump"
			elif state=="mantle":category="mantle"
			elif state=="wall_walk":category="walk" if animations.walk.has(direction) else "run"
			elif state in ["slide","dash","protect"]:category=state
			elif state in ["crouch","crouch_walk","in_crouch"]:category="crouch"
			elif state=="attack2" and animations.has("followup"):category="followup"
			elif state.begins_with("attack"):category="attack"
			var tiles:Array=animations[category][direction]
			frames.set_animation_speed(name,17 if category=="walk" else 1)
			frames.set_animation_loop(name,category=="idle" or (tiles.size()>1 and category in ["walk","run"]))
			for f in range(tiles.size()):
				var rect:Array=tiles[f]
				var tile:=AtlasTexture.new()
				tile.atlas=texture
				tile.region=Rect2(rect[0],rect[1],rect[2],rect[3])
				var durations:=[0.28,0.18,0.24,0.32,0.24,0.18]
				frames.add_frame(name,tile,durations[f] if category=="idle" else (run_timing[direction][f] if category=="run" else (manifest.timings.wallrun[direction][f] if category=="wallrun" else (0.2 if category=="jump" else 1.0))))
	assert(ResourceSaver.save(frames,"res://samurai/base_rotations.tres")==OK)
	quit()



