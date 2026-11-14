extends Node3D

var skeleton: Skeleton3D
var weapon: Node3D
var trail: MeshInstance3D
var mantle := 0.0
var clock := 0.0
var gait := 0.0
var rests: Array[Vector3] = []
var steel := StandardMaterial3D.new()
var dark := StandardMaterial3D.new()
var glow := StandardMaterial3D.new()

func add_bone(label: String, parent: int, position: Vector3) -> void:
	var id := skeleton.get_bone_count()
	skeleton.add_bone(label)
	if parent >= 0: skeleton.set_bone_parent(id, parent)
	var local := position - rests[parent] if parent >= 0 else position
	skeleton.set_bone_rest(id, Transform3D(Basis.IDENTITY, local))
	skeleton.set_bone_pose_position(id, local)
	rests.append(position)

func _ready() -> void:
	skeleton = Skeleton3D.new()
	add_child(skeleton)
	add_bone("hips", -1, Vector3(0, 0.95, 0))
	add_bone("spine", 0, Vector3(0, 1.22, 0))
	add_bone("head", 1, Vector3(0, 1.86, 0))
	add_bone("arm_l", 1, Vector3(-0.36, 1.63, 0))
	add_bone("forearm_l", 3, Vector3(-0.43, 1.28, 0))
	add_bone("arm_r", 1, Vector3(0.36, 1.63, 0))
	add_bone("forearm_r", 5, Vector3(0.43, 1.28, 0))
	add_bone("thigh_l", 0, Vector3(-0.18, 0.95, 0))
	add_bone("shin_l", 7, Vector3(-0.18, 0.5, 0))
	add_bone("thigh_r", 0, Vector3(0.18, 0.95, 0))
	add_bone("shin_r", 9, Vector3(0.18, 0.5, 0))
	var imported := load("res://archive/assets/grim_reaper/scene.gltf").instantiate() as Node3D
	add_child(imported)
	var meshes := imported.find_children("*", "MeshInstance3D", true, false)
	var bounds := AABB()
	var first := true
	for obj in meshes:
		var b: AABB = obj.global_transform * obj.get_aabb()
		bounds = b if first else bounds.merge(b)
		first = false
	var scale_factor := 2.15 / bounds.size.y
	var center := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	var facing := Basis(Vector3.UP, PI / 2)
	var skin := Skin.new()
	for bone in range(rests.size()):
		skin.add_bind(bone, Transform3D(Basis.IDENTITY, rests[bone]).affine_inverse())
	for obj in meshes:
		var result := ArrayMesh.new()
		for surface in range(obj.mesh.get_surface_count()):
			var arrays: Array = obj.mesh.surface_get_arrays(surface)
			for custom in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3]: arrays[custom] = null
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
			var bones := PackedInt32Array()
			var weights := PackedFloat32Array()
			bones.resize(vertices.size() * 4)
			weights.resize(vertices.size() * 4)
			for v in range(vertices.size()):
				var p: Vector3 = facing * ((obj.global_transform * vertices[v] - center) * scale_factor)
				vertices[v] = p
				normals[v] = (facing * obj.global_basis * normals[v]).normalized()
				if tangents.size() > 0:
					var t: Vector3 = facing * obj.global_basis * Vector3(tangents[v*4], tangents[v*4+1], tangents[v*4+2])
					tangents[v*4] = t.x
					tangents[v*4+1] = t.y
					tangents[v*4+2] = t.z
				var b1 := 0
				var b2 := 1
				var mix := clampf((p.y - 1.0) / 0.35, 0, 1)
				if p.y > 1.78:
					b1 = 1
					b2 = 2
					mix = clampf((p.y - 1.78) / 0.15, 0, 1)
				elif absf(p.x) > 0.32 and p.y > 0.93 and p.y < 1.78 and p.z < 0.17:
					b1 = 3 if p.x < 0 else 5
					b2 = b1 + 1
					mix = clampf((1.38 - p.y) / 0.18, 0, 1)
				elif p.y < 0.95 and absf(p.x) < 0.32 and p.z < 0.14:
					b1 = 7 if p.x < 0 else 9
					b2 = b1 + 1
					mix = clampf((0.6 - p.y) / 0.2, 0, 1)
				bones[v*4] = b1
				bones[v*4+1] = b2
				weights[v*4] = 1 - mix
				weights[v*4+1] = mix
			var source_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var filtered := PackedInt32Array()
			for triangle in range(0, source_indices.size(), 3):
				var p := (vertices[source_indices[triangle]] + vertices[source_indices[triangle+1]] + vertices[source_indices[triangle+2]]) / 3
				# Remove the static weapon silhouette from the source mesh.
				if p.y < 1.35 and absf(p.x) > 0.55: continue
				if p.y > 0.87 and p.y < 1.12 and p.z < -0.26: continue
				filtered.append(source_indices[triangle])
				filtered.append(source_indices[triangle+1])
				filtered.append(source_indices[triangle+2])
			arrays[Mesh.ARRAY_INDEX] = filtered
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_TANGENT] = tangents
			arrays[Mesh.ARRAY_BONES] = bones
			arrays[Mesh.ARRAY_WEIGHTS] = weights
			result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			result.surface_set_material(surface, obj.mesh.surface_get_material(surface))
		var body := MeshInstance3D.new()
		skeleton.add_child(body)
		body.mesh = result
		body.skin = skin
		body.skeleton = NodePath("..")
		body.extra_cull_margin = 3
	imported.queue_free()
	steel.albedo_color = Color("869da9")
	steel.metallic = 0.85
	steel.roughness = 0.3
	dark.albedo_color = Color("161b21")
	dark.metallic = 0.6
	glow.albedo_color = Color("62e6d2")
	glow.emission_enabled = true
	glow.emission = Color("25b6a4")
	glow.emission_energy_multiplier = 2
	var grip := BoneAttachment3D.new()
	skeleton.add_child(grip)
	grip.bone_name = "forearm_r"
	weapon = Node3D.new()
	grip.add_child(weapon)
	weapon.position = Vector3(0, -0.28, -0.04)
	weapon.rotation.z = -0.12
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.033
	shaft.bottom_radius = 0.045
	shaft.height = 2.6
	part(shaft, Vector3(0, 0.25, 0), dark)
	for y in [-0.9, -0.5, 0.1, 0.55, 1.35]:
		var band := CylinderMesh.new()
		band.top_radius = 0.048
		band.bottom_radius = 0.048
		band.height = 0.065
		part(band, Vector3(0, y, 0), steel)
	var blade := SurfaceTool.new()
	blade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for n in range(20):
		var t0 := float(n) / 20
		var t1 := float(n+1) / 20
		var a := blade_point(t0, false)
		var b := blade_point(t1, false)
		var c := blade_point(t0, true)
		var d := blade_point(t1, true)
		for depth in [-0.035, 0.035]:
			for p in [a,c,b,b,c,d]:
				blade.add_vertex(p + Vector3(0,0,depth))
		for p in [a,b,a+Vector3(0,0,0.07),b,b+Vector3(0,0,0.07),a+Vector3(0,0,0.07)]:
			blade.add_vertex(p + Vector3(0,0,-0.035))
	blade.generate_normals()
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	part(blade.commit(), Vector3.ZERO, steel)
	var gem := SphereMesh.new()
	gem.radius = 0.065
	gem.height = 0.13
	part(gem, Vector3(0,1.48,-0.07), glow)

func blade_point(t: float, inner: bool) -> Vector3:
	return Vector3(-1.5 * t, 1.5 + 0.18 * sin(t * PI) - 0.75 * t * t - (0.28 * (1-t) if inner else 0), 0)

func part(mesh: Mesh, pos: Vector3, mat: Material) -> void:
	var obj := MeshInstance3D.new()
	weapon.add_child(obj)
	obj.mesh = mesh
	obj.position = pos
	obj.material_override = mat

func pose(bone: int, euler: Vector3) -> void:
	skeleton.set_bone_pose_rotation(bone, Quaternion.from_euler(euler))

func animate(dt: float, velocity: Vector3, grounded: bool, sliding: bool, dashing: bool, attack: float, combo: int) -> void:
	clock += dt
	var speed := Vector2(velocity.x, velocity.z).length()
	gait += dt * speed * 1.5
	mantle = maxf(0, mantle - dt)
	var amount := clampf(speed / 8, 0, 1)
	for b in range(skeleton.get_bone_count()): pose(b, Vector3.ZERO)
	pose(1, Vector3(-0.08 * amount, 0, sin(gait) * 0.035 * amount))
	pose(2, Vector3(0.025 * sin(clock * 2), 0, 0))
	pose(3, Vector3(-sin(gait) * amount * 0.35, 0, -0.06))
	pose(5, Vector3(-0.25, 0, 0.05))
	pose(6, Vector3(-0.2, 0, 0))
	for side in range(2):
		var stride := sin(gait + side * PI) * amount
		pose(7 + side * 2, Vector3(stride * 0.5,0,0))
		pose(8 + side * 2, Vector3(maxf(0,-stride)*0.65,0,0))
	position.y = absf(sin(gait))*0.025*amount
	if not grounded:
		pose(7, Vector3(-0.5,0,0))
		pose(8, Vector3(0.7,0,0))
		pose(9, Vector3(0.2,0,0))
	if sliding:
		position.y = -0.4
		pose(0, Vector3(0.5,0,0))
		pose(7, Vector3(-1.0,0,0))
		pose(9, Vector3(-0.7,0,0))
	if dashing: pose(1,Vector3(-0.35,0,0))
	if mantle > 0: pose(3,Vector3(-2,0,0))
	if attack > 0:
		var phase := clampf(1 - attack / 0.82,0,1)
		var wind := smoothstep(0,0.28,phase)
		var swing := smoothstep(0.28,0.7,phase)
		var recover := smoothstep(0.7,1,phase)
		var sign_side := -1.0 if combo == 2 else 1.0
		var twist := (wind * -0.65 + swing * 1.5) * (1-recover) * sign_side
		pose(1,Vector3(-0.1,twist,0))
		pose(5,Vector3(-1.2*wind*(1-recover),-twist, -0.75*wind*(1-recover)))
		pose(6,Vector3(-0.3,0,0))
		pose(3,Vector3(-0.65*wind*(1-recover),0,-0.2))
		weapon.rotation = Vector3(0.1, (wind*-1.1+swing*2.6)*(1-recover)*sign_side, -0.12 + wind*(1-recover)*1.1)
		if combo == 3:
			pose(5,Vector3(-2.4*wind+2.8*swing-0.65*recover,0,-0.25))
			weapon.rotation.z = -0.2
	else:
		weapon.rotation = Vector3(0,0,-0.12)




