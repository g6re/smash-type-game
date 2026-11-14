extends RefCounted

static func build(arena:Node3D) -> void:
	arena.platform(Vector3(32, 1, 32), Vector3(0, -0.5, 0), Color("343a42"))
	for side in [-1,1]:
		arena.platform(Vector3(0.5,3.5,10),Vector3(side*15,1.75,0),Color("526876"))
		arena.platform(Vector3(4,0.5,4),Vector3(side*12,2.25,-10),Color("625444"))
		for step in range(2):arena.platform(Vector3(3,1+step,2),Vector3(side*12,0.5+step*0.5,7-step*3),Color("526876"))
	for x in [-9, 9]:
		arena.platform(Vector3(1, 6, 10), Vector3(x, 3, -3), Color("555b65"))
	arena.platform(Vector3(6, 2, 3), Vector3(0, 1, -7), Color("625444"))
	arena.platform(Vector3(4, 3.5, 4), Vector3(-5, 1.75, -6), Color("555b65"))
	arena.platform(Vector3(5, 0.5, 4), Vector3(5, 3.5, -6), Color("625444"))
	arena.platform(Vector3(3,1.2,2),Vector3(-4,0.6,4),Color("526876"))
	arena.platform(Vector3(3,2.5,2),Vector3(-4,1.25,1),Color("526876"))
	arena.platform(Vector3(3,0.3,2),Vector3(4,1.25,4),Color("526876"))
	decorate(arena)

static func decorate(arena:Node3D) -> void:
	for x in [-15.8, 15.8]:
		arena.box(arena, Vector3(0.15, 0.06, 32), Vector3(x, 0.03, 0), Color("cb9650"))
	for z in [-15.8, 15.8]:
		arena.box(arena, Vector3(32, 0.06, 0.15), Vector3(0, 0.03, z), Color("cb9650"))
	for i in range(9):
		arena.box(arena, Vector3(0.025, 0.01, 24), Vector3(-12 + i * 3, 0.008, 0), Color("222830"))
		arena.box(arena, Vector3(24, 0.01, 0.025), Vector3(0, 0.008, -12 + i * 3), Color("222830"))
	for pos in [Vector3(-10, 0, -10), Vector3(10, 0, -10), Vector3(-10, 0, 10), Vector3(10, 0, 10)]:
		arena.platform(Vector3(1.2, 0.4, 1.2), pos + Vector3.UP * 0.2, Color("252b34"))
		var pillar := MeshInstance3D.new()
		var shape := CylinderMesh.new()
		shape.top_radius = 0.3
		shape.bottom_radius = 0.45
		shape.height = 3.0
		pillar.mesh = shape
		pillar.material_override = arena.material(Color("535964"))
		arena.add_child(pillar)
		pillar.position = pos + Vector3.UP * 1.9
		var fire:MeshInstance3D = arena.box(arena, Vector3(0.7, 0.15, 0.7), pos + Vector3.UP * 3.4, Color("ff983d"))
		fire.material_override = arena.material(Color("ff983d"), true)
		var lamp := OmniLight3D.new()
		arena.add_child(lamp)
		lamp.position = pos + Vector3.UP * 3.7
		lamp.light_color = Color("ffad65")
		lamp.light_energy = 3
		lamp.omni_range = 9
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 4.85
	torus.outer_radius = 4.92
	ring.mesh = torus
	ring.scale.y = 0.12
	ring.position.y = 0.025
	ring.material_override = arena.material(Color("ad8553"))
	arena.add_child(ring)
	for i in range(16):
		var angle := i * TAU / 16
		var p := Vector3(cos(angle) * 40, -7, sin(angle) * 40)
		arena.box(arena, Vector3(5, 20 + i % 4 * 5, 5), p, Color("202b3b"))



