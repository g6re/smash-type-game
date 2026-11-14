extends "res://game/arena.gd"
func _ready() -> void:
	selected_character="box"
	super._ready()
	await get_tree().create_timer(0.4).timeout
	set_physics_process(false)
	assert(visual.skeleton!=null and not visual.has_sword)
	assert(visual.aliases.has("upper_arm.L"))
	player.position=Vector3(0,0.05,6)
	model.rotation.y=PI
	pivot.position=player.position+Vector3.UP*1.2
	pivot.rotation=Vector3(-0.15,0,0)
	camera.position=Vector3(0,0.4,4)
	visual.animate(0.1,Vector3.ZERO,true,false,false,0,1)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/box-game.png")
	assert(begin_charge())
	charge_time=CHARGE_SECONDS
	var position_before:=player.position
	visual.set_casting(true,1)
	assert(visual.magic.visible)
	camera.look_at(Vector3(0,1,0))
	release_charge()
	assert(not charging and slash_left==0 and skill_cooldown>0)
	assert(not visual.magic.visible and not charge_sword.visible)
	assert(player.position==position_before)
	var bolt:Node3D
	for child in get_children():
		if child.get_script()==preload("res://game/arcane_bolt.gd"):bolt=child
	assert(bolt!=null)
	bolt.set_physics_process(false)
	enemies[0].body.position=Vector3(0,1,0)
	bolt.position=Vector3(0,1,1)
	bolt.direction=Vector3.FORWARD
	bolt._physics_process(0.1)
	assert(enemies[0].damage>=40 and ultimate_charge>0)
	select_character("samurai",true)
	assert(visual.sprite!=null and selected_character=="samurai")
	select_character("box",true)
	assert(not visual.has_sword)
	print("PASS: Box model, charged arcane projectile, no slash or sword, damage/ultimate, independent character selection")
	get_tree().quit()
