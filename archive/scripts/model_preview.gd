extends Node3D
func _ready():
	var m = load("res://archive/assets/grim_reaper/scene.gltf").instantiate()
	add_child(m)
	var bounds := AABB()
	var first := true
	for obj in m.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = obj.global_transform * obj.get_aabb()
		bounds = b if first else bounds.merge(b)
		first = false
	print("BOUNDS ",bounds)
	m.scale *= 2.3 / bounds.size.y
	m.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * m.scale.x
	var c := Camera3D.new()
	add_child(c)
	c.position = Vector3(3, 2, 4)
	c.look_at(Vector3(0,1.2,0))
	var l := DirectionalLight3D.new()
	add_child(l)
	l.rotation_degrees = Vector3(-40,-30,0)
	var e := WorldEnvironment.new()
	e.environment = Environment.new()
	e.environment.background_mode = Environment.BG_COLOR
	e.environment.background_color = Color("303b48")
	e.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.environment.ambient_light_color = Color.WHITE
	e.environment.ambient_light_energy = 0.7
	add_child(e)
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://screenshots/model_preview.png")
	get_tree().quit()
