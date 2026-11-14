extends "res://game/arena.gd"
func _ready() -> void:
	super._ready()
	set_physics_process(false)
	player.collision_mask=0
	player.position=Vector3(0,2,6)
	stamina=3
	assert(try_dash() and stamina==2)
	assert(dash_time==0.22 and Vector2(player.velocity.x,player.velocity.z).length()>17)
	var start:=player.position
	for frame in range(13):
		await get_tree().physics_frame
		parkour.tick(1.0/60)
		dash_time=maxf(0,dash_time-1.0/60)
		move_player(1.0/60)
	assert(player.position.distance_to(start)>3.3 and player.position.distance_to(start)<4.4,"Dash has a controllable distance")
	dash_time=0
	player.collision_mask=1
	player.position=Vector3(7,2,0)
	await get_tree().physics_frame
	parkour.begin_dash(Vector3.RIGHT)
	for frame in range(12):
		await get_tree().physics_frame
		dash_time=maxf(0,dash_time-1.0/60)
		parkour.tick(1.0/60)
		move_player(1.0/60)
	assert(player.position.x<8.2,"Dash stops at solid walls")
	dash_time=0
	parkour.wall_lock=0
	player.position=Vector3(8.05,2,0)
	player.velocity=Vector3(0,0,-8)
	await get_tree().physics_frame
	assert(parkour.update_wallrun(Vector3.FORWARD,0.016))
	assert(parkour.wallrunning and player.velocity.y<=2.5)
	assert((-model.global_basis.z).dot(parkour.wall_tangent)>0.99,"Wallrun faces its travel direction")
	var bars:=stamina
	jump()
	assert(not parkour.wallrunning and player.velocity.y==10 and stamina==bars)
	assert(parkour.bonus_window>0)
	jump()
	assert(dash_time>0 and stamina==bars and parkour.bonus_window==0)
	dash_time=0
	parkour.wall_budget=0
	parkour.wall_lock=0
	assert(not parkour.update_wallrun(Vector3.FORWARD,0.016),"Wallrun is finite")
	player.position=Vector3(0,parkour.RAIL_Y, -parkour.EDGE)
	player.velocity=Vector3(8,-1,0)
	await get_tree().physics_frame
	assert(parkour.try_grind())
	var initial:=player.position
	for frame in range(20):
		await get_tree().physics_frame
		assert(parkour.drive(0.03))
		motion_fx.update_effects(0.03)
	assert(player.position.x>initial.x+5)
	assert(parkour.grind_fire>0.2 and stamina==bars)
	if DisplayServer.get_name()!="headless":
		visual.animate(0.016,player.velocity,false,false,false,0,1)
		if visual.has_method("set_parkour_pose"):visual.set_parkour_pose(false,true)
		pivot.position=player.position+Vector3.UP*1.3
		pivot.rotation=Vector3(-0.18,-PI/2,0)
		camera.position=Vector3(0,0.6,5)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/grind-fire.png")
	jump()
	assert(not parkour.grinding and dash_time>0 and player.velocity.y==10)
	assert(parkour.fire_afterglow>0 and stamina==bars)
	assert(parkour.rail_lock>0,"Cannot reattach immediately")
	parkour.bonus_window=0.01
	parkour.tick(0.02)
	assert(parkour.bonus_window==0)
	reset_player()
	assert(not parkour.grinding and not parkour.wallrunning and dash_time==0)
	player.position=Vector3(0,3,6)
	player.velocity=Vector3.ZERO
	stamina=1
	assert(try_dash() and stamina==0)
	jump()
	assert(dash_time==0 and player.velocity.y==10.5 and stamina==0,"Space cancels dash into a free jump")
	assert(not parkour.dash_jump_available,"The free jump is consumed once")
	unlimited_stamina=true
	assert(spend_stamina() and stamina==STAMINA_MAX)
	assert(spend_stamina() and stamina==STAMINA_MAX)
	unlimited_stamina=false
	stamina=0
	assert(not spend_stamina(),"Training toggle can be turned off")
	var rail_point:Vector3=parkour.rail_point(5)
	assert(absf(rail_point.z)>12.0,"Rail lies outside the arena")
	assert(ray(rail_point-Vector3.UP*0.3,rail_point-Vector3.UP*5).is_empty(),"Void below floating rail")
	print("PASS: controlled dash, walls, finite wallrun, double-space boost, floating rail/fire, jump dash and reset")
	get_tree().quit()
