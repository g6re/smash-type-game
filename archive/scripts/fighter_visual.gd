extends Node3D

var torso: Node3D
var hips: Node3D
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var hands: Array[Node3D] = []
var weapons: Array[Node3D] = []
var chains: Array = []
var clock := 0.0
var gait := 0.0
var mantle := 0.0
var landing := 0.0
var was_grounded := false
var steel := StandardMaterial3D.new()
var skin := StandardMaterial3D.new()
var dark := StandardMaterial3D.new()
var gold := StandardMaterial3D.new()

func mesh_part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var obj := MeshInstance3D.new()
	obj.mesh = mesh
	obj.material_override = mat
	parent.add_child(obj)
	obj.position = pos
	return obj

func joint(parent: Node3D, pos: Vector3) -> Node3D:
	var obj := Node3D.new()
	parent.add_child(obj)
	obj.position = pos
	return obj

func segment(parent: Node3D, length: float, radius: float, mat: Material) -> void:
	var c := CapsuleMesh.new()
	c.radius = radius
	c.height = length
	mesh_part(parent, c, Vector3(0, -length * 0.5, 0), mat)

func sphere(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	mesh_part(parent, s, pos, mat).scale = size

func _ready() -> void:
	steel.albedo_color = Color("b7c5ce")
	steel.metallic = 0.85
	steel.roughness = 0.26
	skin.albedo_color = Color("bda18a")
	skin.roughness = 0.85
	dark.albedo_color = Color("20252c")
	dark.metallic = 0.45
	gold.albedo_color = Color("ba8248")
	gold.metallic = 0.8
	hips = joint(self, Vector3(0, 0.93, 0))
	sphere(hips, Vector3.ZERO, Vector3(0.56, 0.3, 0.38), dark)
	torso = joint(hips, Vector3(0, 0.12, 0))
	sphere(torso, Vector3(0, 0.28, 0), Vector3(0.77, 0.72, 0.46), skin)
	sphere(torso, Vector3(0, 0.26, 0.05), Vector3(0.81, 0.52, 0.41), dark)
	var strap := BoxMesh.new()
	strap.size = Vector3(0.12, 0.65, 0.49)
	mesh_part(torso, strap, Vector3(0.17, 0.3, 0), gold).rotation.z = -0.35
	sphere(torso, Vector3(0, 0.8, 0), Vector3(0.34, 0.43, 0.35), skin)
	sphere(torso, Vector3(0, 0.69, -0.13), Vector3(0.27, 0.23, 0.13), dark)
	for side in [-1.0, 1.0]:
		var arm := joint(torso, Vector3(side * 0.43, 0.5, 0))
		sphere(arm, Vector3.ZERO, Vector3(0.32, 0.3, 0.34), gold if side < 0 else steel)
		segment(arm, 0.34, 0.105, skin)
		var elbow := joint(arm, Vector3(0, -0.32, 0))
		segment(elbow, 0.32, 0.095, dark)
		var hand := joint(elbow, Vector3(0, -0.31, 0))
		sphere(hand, Vector3.ZERO, Vector3(0.16, 0.2, 0.16), skin)
		arms.append(arm)
		elbows.append(elbow)
		hands.append(hand)
		var leg := joint(hips, Vector3(side * 0.19, -0.05, 0))
		segment(leg, 0.43, 0.135, dark)
		var knee := joint(leg, Vector3(0, -0.4, 0))
		sphere(knee, Vector3(0, 0, -0.07), Vector3(0.22, 0.23, 0.13), steel)
		segment(knee, 0.43, 0.105, dark)
		sphere(knee, Vector3(0, -0.38, -0.08), Vector3(0.24, 0.17, 0.4), dark)
		legs.append(leg)
		knees.append(knee)
		var weapon := joint(self, Vector3.ZERO)
		var blade_mesh := PrismMesh.new()
		blade_mesh.size = Vector3(0.32, 0.82, 0.09)
		mesh_part(weapon, blade_mesh, Vector3(0, -0.43, 0), steel).rotation.z = side * 0.2
		var edge := PrismMesh.new()
		edge.size = Vector3(0.12, 0.72, 0.1)
		var fire := StandardMaterial3D.new()
		fire.albedo_color = Color("ffb350")
		fire.emission_enabled = true
		fire.emission = Color("ff601b")
		fire.emission_energy_multiplier = 1.6
		mesh_part(weapon, edge, Vector3(side * 0.13, -0.43, 0), fire).rotation.z = side * 0.2
		segment(weapon, 0.2, 0.045, dark)
		sphere(weapon, Vector3(0, -0.16, 0), Vector3(0.35, 0.09, 0.12), gold)
		weapons.append(weapon)
		var links: Array[MeshInstance3D] = []
		var ring := TorusMesh.new()
		ring.inner_radius = 0.034
		ring.outer_radius = 0.057
		ring.rings = 8
		ring.ring_segments = 12
		for n in range(32):
			var link := mesh_part(self, ring, Vector3.ZERO, steel)
			links.append(link)
		chains.append(links)

func animate(dt: float, velocity: Vector3, grounded: bool, sliding: bool, dashing: bool, attack: float, combo: int) -> void:
	clock += dt
	var speed := Vector2(velocity.x, velocity.z).length()
	gait += dt * speed * 1.6
	var run := clampf(speed / 8.0, 0, 1)
	if grounded and not was_grounded: landing = 0.17
	was_grounded = grounded
	landing = maxf(0, landing - dt)
	mantle = maxf(0, mantle - dt)
	hips.position.y = 0.93 + sin(gait * 2) * 0.045 * run if grounded else 0.93
	hips.position.y -= landing * 0.8
	torso.rotation = Vector3(-0.15 * run, 0, sin(gait) * 0.04 * run)
	for i in range(2):
		var sign_side := -1.0 if i == 0 else 1.0
		var stride := sin(gait + i * PI) * run
		legs[i].rotation = Vector3(stride * 0.8, 0, sign_side * 0.04)
		knees[i].rotation.x = maxf(0, -stride) * 1.1 + 0.08
		arms[i].rotation = Vector3(-stride * 0.6 - 0.15, 0, sign_side * -0.12)
		elbows[i].rotation.x = -0.35 - run * 0.3
		if not grounded:
			legs[i].rotation.x = -0.55 if i == 0 else 0.3
			knees[i].rotation.x = 0.9
			arms[i].rotation.x = -0.65
		if sliding:
			hips.position.y = 0.47
			torso.rotation.x = 0.55
			legs[i].rotation.x = -1.25 if i == 0 else -0.3
			knees[i].rotation.x = 0.15 if i == 0 else 1.6
			arms[i].rotation.x = 0.6
		if dashing:
			torso.rotation.x = -0.5
			arms[i].rotation.x = 0.8
		if mantle > 0:
			torso.rotation.x = -0.5
			arms[i].rotation.x = -2.6
			elbows[i].rotation.x = -0.4
		if attack > 0:
			var phase := clampf(1 - attack / 0.58, 0, 1)
			var swing := sin(phase * PI)
			torso.rotation.y = sin(phase * TAU) * 0.65 * (1 if combo != 2 else -1)
			arms[i].rotation = Vector3(-1.25, sign_side * swing * 1.1, sign_side * -0.8)
			elbows[i].rotation.x = -0.15
			var angle := -1.8 + phase * 4.8
			if combo == 2: angle = 1.8 - phase * 4.8
			var reach := 0.5 + 2.4 * swing
			weapons[i].position = Vector3(sin(angle + i * 0.7) * reach, 1.3 + (sin(phase * TAU) * 0.7 if combo == 3 else 0), -cos(angle + i * 0.7) * reach)
			weapons[i].rotation = Vector3(0, angle, sign_side * -1.1)
		else:
			weapons[i].global_transform = hands[i].global_transform
			weapons[i].rotation.x += -0.2
		var start := to_local(hands[i].global_position)
		var finish := weapons[i].position
		var dist := start.distance_to(finish)
		var count := clampi(int(dist / 0.085) + 4, 4, 32)
		for n in range(32):
			var link: MeshInstance3D = chains[i][n]
			link.visible = n < count
			if not link.visible: continue
			var t := float(n) / maxf(1, count - 1)
			link.position = start.lerp(finish, t) + Vector3(0, -sin(t * PI) * (0.12 if attack > 0 else 0.18), 0)
			var tangent := (finish - start).normalized()
			if tangent.length() > 0.01:
				link.quaternion = Quaternion(Vector3.UP, tangent)
				link.rotate_object_local(Vector3.UP, PI * 0.5 if n % 2 == 0 else 0)
			link.scale = Vector3(1, 1, 1.5)
