extends "res://game/arena.gd"

func _ready() -> void:
	super._ready()
	await get_tree().create_timer(0.35).timeout
	assert(not hud.visible and hud.text.is_empty())
	assert(not options_menu.visible and not get_tree().paused)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/clean_hud.png")
	var escape:=InputEventKey.new()
	escape.keycode=KEY_ESCAPE
	escape.pressed=true
	options_menu._input(escape)
	assert(options_menu.visible and get_tree().paused)
	assert(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	var training:=options_menu.find_child("UnlimitedStamina",true,false) as CheckButton
	assert(training!=null)
	stamina=0
	training.button_pressed=true
	assert(unlimited_stamina and stamina==STAMINA_MAX)
	training.button_pressed=false
	assert(not unlimited_stamina)
	var frozen_position:=player.position
	var cooldown_before:=attack_cooldown
	await get_tree().create_timer(0.15).timeout
	assert(player.position==frozen_position and attack_cooldown==cooldown_before)
	var click:=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT
	click.pressed=true
	_input(click)
	assert(attack_time==0 and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/options_menu.png")
	options_menu._input(escape)
	assert(not options_menu.visible and not get_tree().paused)
	assert(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)
	options_menu.open()
	reset_player()
	options_menu.resume()
	assert(player.position==spawn and player.velocity==Vector3.ZERO)
	print("PASS: clean HUD, Escape menu, paused simulation, blocked attacks, resume and restart")
	get_tree().quit()
