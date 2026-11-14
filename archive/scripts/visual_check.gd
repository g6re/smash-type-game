extends "res://game/arena.gd"

func _ready() -> void:
	super._ready()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.8).timeout
	yaw = 0.55
	pitch = -0.16
	await get_tree().create_timer(0.3).timeout
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://screenshots/preview_idle.png")
	combo = 1
	attack_time = 0.82
	await get_tree().create_timer(0.4).timeout
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://screenshots/preview_attack.png")
	for state in range(5):
		visual.animate(0.016, Vector3(0, 2, -8), state == 0, state == 1, state == 2, 0.25 if state == 3 else 0.0, 3)
	get_tree().quit()


