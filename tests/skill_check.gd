extends "res://game/arena.gd"
func _ready() -> void:
	selected_character="samurai"
	super._ready()
	abilities.sparring=false
	player.position=Vector3(0,0.05,6)
	yaw=0
	await get_tree().create_timer(0.2).timeout
	assert(player.is_on_floor())
	jump()
	assert(stamina==3,"Ground jump is free")
	await get_tree().create_timer(0.05).timeout
	jump()
	assert(stamina==3,"Double jump is free")
	assert(try_dash() and stamina==2,"Dash consumes one bar")
	dash_time=0
	assert(try_dash() and stamina==1)
	dash_time=0
	assert(try_dash() and stamina==0)
	dash_time=0
	assert(not try_dash(),"No dash without full bar")
	player.position=Vector3(8.1,2,0)
	player.velocity=Vector3(20,0,0)
	player.move_and_slide()
	await get_tree().physics_frame
	player.velocity=Vector3(20,0,0)
	player.move_and_slide()
	assert(player.is_on_wall(),"Wall setup")
	var before:=stamina
	jump()
	assert(stamina==before and player.velocity.y==10,"Wall jump is free at zero stamina")
	player.position=Vector3(0,4,6)
	player.velocity=Vector3.ZERO
	stamina_delay=0
	stamina=0
	assert(begin_charge())
	var anchor:=hover_position
	await get_tree().create_timer(1.6).timeout
	assert(player.position.is_equal_approx(anchor),"Charge holds air position")
	assert(charge_time==CHARGE_SECONDS,"Charge capped")
	assert(stamina>0 and stamina<1,"Slow partial refill")
	assert(not try_dash(),"Dash blocked while charging")
	assert(charge_sword.visible and combat_hud.charging)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/skill_charge.png")
	enemies[0].body.position=Vector3(0,1,0)
	enemies[0].body.velocity=Vector3.ZERO
	camera.look_at(enemies[0].body.position)
	release_charge()
	assert(not charging and skill_cooldown>0 and slash_left>0)
	assert(not begin_charge(),"Ability cooldown")
	if DisplayServer.get_name()!="headless":
		await get_tree().create_timer(0.10).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/skill_slash.png")
	await get_tree().create_timer(0.4).timeout
	assert(enemies[0].damage>=39,"Fully charged slash hits")
	assert(ultimate_charge>0,"Hits charge ultimate")
	assert(slash_left<=0,"Slash finishes")
	skill_cooldown=0
	assert(begin_charge())
	cancel_charge()
	assert(slash_left<=0 and not charge_sword.visible,"Cancel must not slash")
	player.position=Vector3(7,2,0)
	assert(begin_charge())
	charge_time=CHARGE_SECONDS
	release_charge()
	slash_direction=Vector3.RIGHT
	advance_slash(0.24)
	assert(player.position.x<8.2 and slash_left<=0,"Solid wall stops slash")
	print("PASS: three stamina bars, free ground/wall jump, free double jump/dash costs, refill, hover, slash damage + wall collision, ultimate, cooldown, cancel")
	get_tree().quit()




