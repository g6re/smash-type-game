extends Node3D
var arena:Node3D
var feet:Array[CPUParticles3D]=[]
var timer:=0.0
var previous:=Vector3.ZERO

func _ready() -> void:
	for side in [-1,1]:
		var particles:=CPUParticles3D.new()
		arena.model.add_child(particles)
		particles.position=Vector3(side*0.16,0.1,0)
		particles.amount=35
		particles.lifetime=0.4
		particles.direction=Vector3.UP
		particles.initial_velocity_min=0.2
		particles.initial_velocity_max=1.3
		particles.spread=35
		particles.gravity=Vector3(0,0.6,0)
		particles.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius=0.07
		preload("res://game/pixel_sparks.gd").setup(particles,Color("ff7b28"))
		particles.emitting=false
		feet.append(particles)
	previous=arena.player.position

func pulse(point:Vector3,direction:Vector3,strength:float) -> void:
	var ring:=MeshInstance3D.new()
	arena.slash_effects.add_child(ring)
	var shape:=TorusMesh.new()
	shape.inner_radius=0.32
	shape.outer_radius=0.38
	ring.mesh=shape
	ring.position=point
	ring.quaternion=Quaternion(Vector3.UP,direction.normalized())
	var mat:Material=arena.slash_effects.glow(Color(1,0.55,0.12,0.5))
	ring.material_override=mat
	arena.slash_effects.pieces.append({"node":ring,"life":0.3,"total":0.3,"material":mat})

func update_effects(dt:float) -> void:
	var active:bool=arena.dash_time>0 or arena.parkour.grinding or arena.parkour.wallrunning or arena.parkour.fire_afterglow>0
	for emitter in feet:
		emitter.emitting=active
		emitter.scale=Vector3.ONE*(0.6+maxf(arena.parkour.grind_fire,arena.parkour.fire_afterglow)*1.4)
	timer-=dt
	if active and timer<=0:
		timer=0.035
		var current:Vector3=arena.player.position+Vector3.UP*0.35
		var mesh:=ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var width:=Vector3.UP*0.12
		for v in [previous-width,previous+width,current-width,current-width,previous+width,current+width]:mesh.surface_add_vertex(v)
		mesh.surface_end()
		var trail:=MeshInstance3D.new()
		trail.mesh=mesh
		var mat:Material=arena.slash_effects.glow(Color(1,0.3,0.03,0.35))
		trail.material_override=mat
		arena.slash_effects.add_child(trail)
		arena.slash_effects.pieces.append({"node":trail,"life":0.35,"total":0.35,"material":mat})
	previous=arena.player.position+Vector3.UP*0.35
