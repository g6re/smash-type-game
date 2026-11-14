extends "res://game/arena.gd"
func _ready() -> void:
	selected_character="box"
	super._ready()
	set_physics_process(false)
	player.position=Vector3(0,0.05,6)
	model.rotation.y=0
	for speed in [3.0,8.0]:
		for side in ["L","R"]:
			var min_x:=INF
			var max_x:=-INF
			var min_z:=INF
			var max_z:=-INF
			for frame in range(24):
				visual.elapsed=frame*TAU/24/(6 if speed==3 else 11)
				visual.animate(0,Vector3(0,0,-speed),true,false,false,0,1)
				var hand:Vector3=visual.global_transform.affine_inverse()*visual.joint_position("hand."+side)
				min_x=minf(min_x,absf(hand.x))
				max_x=maxf(max_x,absf(hand.x))
				min_z=minf(min_z,hand.z)
				max_z=maxf(max_z,hand.z)
			if speed==3:
				assert(max_x<0.15 and min_z>0.2,"Walking hands meet behind the back")
				assert(max_z-min_z<0.05,"Relaxed walking keeps the hands together")
			else:
				assert(min_x>0.31,"Running hands remain outside the trousers")
				assert(max_x-min_x<0.07,"Running arms do not move side to side")
				assert(max_z-min_z>0.18,"Running arms swing forward and backward")
	if DisplayServer.get_name()!="headless":
		visual.elapsed=0.4
		visual.animate(0,Vector3(0,0,-3),true,false,false,0,1)
		pivot.position=player.position+Vector3.UP*1.15
		pivot.rotation=Vector3(-0.15,0.7,0)
		camera.position=Vector3(0,0.4,3.4)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/box-chill-walk.png")
	print("PASS: relaxed walking with hands behind back, separate running arm swing")
	get_tree().quit()
