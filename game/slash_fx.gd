extends Node3D
var pieces: Array[Dictionary]=[]
var points: Array[Vector3]=[]
var ribbon: MeshInstance3D
var ribbon_age:=0.0
var active:=false
var side:=Vector3.RIGHT
var axis:=Vector3.FORWARD
var up:=Vector3.UP
var power:=0.0
var spirals:Array[MeshInstance3D]=[]
var head_ring:MeshInstance3D
var flames:CPUParticles3D

func fire_material() -> ShaderMaterial:
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://game/shaders/anime_fire.gdshader")
	return mat

func glow(color: Color) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="shader_type spatial; render_mode unshaded,blend_add,cull_disabled,depth_draw_never; uniform vec4 tint : source_color; uniform float fade=1.0; void fragment(){ ALBEDO=tint.rgb; ALPHA=tint.a*fade; }"
	var mat:=ShaderMaterial.new()
	mat.shader=shader
	mat.set_shader_parameter("tint",color)
	return mat

func begin(direction: Vector3, charge:float=0.0) -> void:
	active=true
	points.clear()
	power=charge
	axis=direction.normalized()
	side=Vector3.UP.cross(direction).normalized()
	if side.length()<0.1: side=Vector3.RIGHT
	up=axis.cross(side).normalized()
	if ribbon!=null: pieces.append({"node":ribbon,"life":0.5,"total":0.5,"material":ribbon.material_override})
	ribbon=MeshInstance3D.new()
	add_child(ribbon)
	ribbon.material_override=glow(Color(1,0.42,0.06,0.3))
	spirals.clear()
	for strand in range(2):
		var spiral:=MeshInstance3D.new()
		ribbon.add_child(spiral)
		spiral.material_override=fire_material()
		spirals.append(spiral)
	head_ring=MeshInstance3D.new()
	head_ring.mesh=crescent_mesh(0.9+power*0.3,0.25)
	head_ring.material_override=fire_material()
	head_ring.basis=Basis(side,axis,up)
	ribbon.add_child(head_ring)
	flames=CPUParticles3D.new()
	ribbon.add_child(flames)
	flames.amount=32
	flames.lifetime=0.32
	flames.direction=Vector3.UP
	flames.spread=70
	flames.initial_velocity_min=0.8
	flames.initial_velocity_max=4.5
	flames.gravity=Vector3(0,1.8,0)
	flames.scale_amount_min=0.5
	flames.scale_amount_max=1.5
	flames.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE
	flames.emission_sphere_radius=0.4+power*0.3
	preload("res://game/pixel_sparks.gd").setup(flames,Color("ff862e"))
	ribbon_age=0

func append_point(point: Vector3) -> void:
	points.append(point)
	if flames!=null:flames.position=point
	if is_instance_valid(head_ring):head_ring.position=point
	if points.size()<2:return
	var mesh:=ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()-1):
		var width:=0.035+power*0.025
		var a:=points[i]-side*width
		var b:=points[i]+side*width
		var c:=points[i+1]-side*width
		var d:=points[i+1]+side*width
		for v in [a,b,c,c,b,d]:mesh.surface_add_vertex(v)
		# A crossing vertical ribbon keeps the trail visible at shallow angles.
		for v in [points[i]-up*width,points[i]+up*width,points[i+1]-up*width,points[i+1]-up*width,points[i]+up*width,points[i+1]+up*width]:mesh.surface_add_vertex(v)
	mesh.surface_end()
	ribbon.mesh=mesh
	rebuild_spirals()

func rebuild_spirals() -> void:
	var total:=0.0
	for i in range(points.size()-1):total+=points[i].distance_to(points[i+1])
	for strand in range(2):
		var mesh:=ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var distance:=0.0
		for i in range(points.size()-1):
			var length:=points[i].distance_to(points[i+1])
			var steps:=maxi(1,int(ceil(length/0.12)))
			for step in range(steps):
				var t0:=float(step)/steps
				var t1:=float(step+1)/steps
				var d0:=distance+length*t0
				var d1:=distance+length*t1
				var a0:=d0*1.25+strand*PI
				var a1:=d1*1.25+strand*PI
				var r0:=side*cos(a0)+up*sin(a0)
				var r1:=side*cos(a1)+up*sin(a1)
				var radius:=0.48+power*0.3
				var envelope0:=pow(clampf(d0/maxf(total,0.01),0,1),0.65)
				var envelope1:=pow(clampf(d1/maxf(total,0.01),0,1),0.65)
				var p0:=points[i].lerp(points[i+1],t0)+r0*radius*(0.12+envelope0)
				var p1:=points[i].lerp(points[i+1],t1)+r1*radius*(0.12+envelope1)
				var width:=0.22+power*0.12
				var w0:=width*(0.1+envelope0)
				var w1:=width*(0.1+envelope1)
				var vertices:=[p0-r0*w0,p0+r0*w0,p1-r1*w1,p1-r1*w1,p0+r0*w0,p1+r1*w1]
				var uvs:=[Vector2(d0,0),Vector2(d0,1),Vector2(d1,0),Vector2(d1,0),Vector2(d0,1),Vector2(d1,1)]
				for v in range(6):
					mesh.surface_set_uv(uvs[v])
					mesh.surface_add_vertex(vertices[v])
			distance+=length
		mesh.surface_end()
		spirals[strand].mesh=mesh

func ghost(sprite: AnimatedSprite3D, position: Vector3) -> void:
	var image:=Sprite3D.new()
	add_child(image)
	image.texture=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	image.pixel_size=sprite.pixel_size
	image.offset=sprite.offset
	image.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	image.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	image.shaded=false
	image.modulate=Color(1,0.35,0.08,0.18)
	image.position=position
	pieces.append({"node":image,"life":0.65,"total":0.65})

func crescent_mesh(radius:float,width:float) -> ImmediateMesh:
	var mesh:=ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(64):
		var a:=float(i)/64*TAU*0.9
		var b:=float(i+1)/64*TAU*0.9
		var r0:=Vector3(cos(a),0,sin(a))
		var r1:=Vector3(cos(b),0,sin(b))
		var taper0:=sin(float(i)/64*PI)*width
		var taper1:=sin(float(i+1)/64*PI)*width
		var verts:=[r0*(radius-taper0),r0*radius,r1*(radius-taper1),r1*(radius-taper1),r0*radius,r1*radius]
		var uvs:=[Vector2(a,0),Vector2(a,1),Vector2(b,0),Vector2(b,0),Vector2(a,1),Vector2(b,1)]
		for v in range(6):
			mesh.surface_set_uv(uvs[v])
			mesh.surface_add_vertex(verts[v])
	mesh.surface_end()
	return mesh

func burst(position: Vector3) -> void:
	var ring:=MeshInstance3D.new()
	add_child(ring)
	var mesh:=crescent_mesh(1.15,0.3)
	ring.mesh=mesh
	ring.position=position
	ring.scale=Vector3(0.25,0.06,0.25)
	var mat:=fire_material()
	ring.material_override=mat
	pieces.append({"node":ring,"life":0.45,"total":0.45,"material":mat,"expand":true})
	preload("res://game/pixel_sparks.gd").burst(self,position,Color("ffb34e"),24,4)

func ghost_model(source:Node3D) -> void:
	var copy:=source.duplicate() as Node3D
	add_child(copy)
	copy.global_transform=source.global_transform
	var mat:=glow(Color(1,0.27,0.025,0.12))
	paint_ghost(copy,mat)
	pieces.append({"node":copy,"life":0.35,"total":0.35,"material":mat})

func paint_ghost(n:Node,mat:Material) -> void:
	if n is MeshInstance3D:n.material_override=mat
	if n is AnimationPlayer:n.stop()
	for child in n.get_children():paint_ghost(child,mat)

func finish() -> void:
	if active and not points.is_empty():
		burst(points[-1])
	active=false
	if flames!=null:flames.emitting=false

func _process(dt: float) -> void:
	if not active and ribbon!=null:
		ribbon_age+=dt
		ribbon.material_override.set_shader_parameter("fade",maxf(0,1-ribbon_age/0.65))
		if is_instance_valid(head_ring):head_ring.material_override.set_shader_parameter("fade",maxf(0,1-ribbon_age/0.35))
		for spiral in spirals:spiral.material_override.set_shader_parameter("fade",maxf(0,1-ribbon_age/0.8))
		if ribbon_age>=0.8:
			ribbon.queue_free()
			ribbon=null
			flames=null
			spirals.clear()
	for i in range(pieces.size()-1,-1,-1):
		var effect: Dictionary=pieces[i]
		effect.life-=dt
		var fade:=maxf(0,effect.life/effect.total)
		if effect.has("material"):effect.material.set_shader_parameter("fade",fade)
		if effect.node is Sprite3D:effect.node.modulate.a=fade*0.18
		if effect.has("velocity"):effect.node.position+=effect.velocity*dt
		if effect.has("expand"):effect.node.scale=Vector3(1,0.03,1)*(0.25+(1-fade)*2)
		if effect.life<=0:
			effect.node.queue_free()
			pieces.remove_at(i)

