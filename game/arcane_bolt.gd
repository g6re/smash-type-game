extends Node3D
var arena:Node3D
var direction:=Vector3.FORWARD
var power:=0.0
var lifetime:=2.5
var orbit:Node3D

func _ready() -> void:
	orbit=Node3D.new()
	add_child(orbit)
	var core:=MeshInstance3D.new()
	var sphere:=SphereMesh.new()
	sphere.radius=0.15+power*0.12
	sphere.height=sphere.radius*2
	core.mesh=sphere
	core.material_override=arena.slash_effects.glow(Color(0.5,0.2,1,0.8))
	add_child(core)
	for i in range(2):
		var ring:=MeshInstance3D.new()
		var torus:=TorusMesh.new()
		torus.inner_radius=0.31+power*0.13
		torus.outer_radius=torus.inner_radius+0.035
		ring.mesh=torus
		ring.rotation=Vector3(PI/2,i*PI/2,0)
		ring.material_override=arena.slash_effects.glow(Color(0.7,0.4,1,0.7))
		orbit.add_child(ring)
	var light:=OmniLight3D.new()
	light.light_color=Color("b174ff")
	light.light_energy=1.5
	light.omni_range=3
	add_child(light)
	preload("res://game/pixel_sparks.gd").trail(self,Color("b28aff"),24)

func _physics_process(dt:float) -> void:
	lifetime-=dt
	if lifetime<=0:queue_free();return
	var start:=global_position
	var end:=start+direction*(22+power*8)*dt
	var obstacle:Dictionary=arena.ray(start,end)
	if not obstacle.is_empty():end=obstacle.position
	for i in range(arena.enemies.size()):
		var target:Vector3=arena.enemies[i].body.position
		if Geometry3D.get_closest_point_to_segment(target,start,end).distance_to(target)<0.85:
			arena.apply_hit(i,16+power*24,direction,3+power*3)
			impact(target)
			queue_free()
			return
	global_position=end
	orbit.rotation+=Vector3(3,5,2)*dt
	if not obstacle.is_empty():impact(end);queue_free()

func impact(point:Vector3) -> void:
	var ring:=MeshInstance3D.new()
	arena.slash_effects.add_child(ring)
	ring.mesh=arena.slash_effects.crescent_mesh(0.8,0.22)
	ring.position=point
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://game/shaders/parry_energy.gdshader")
	mat.set_shader_parameter("energy_color",Color("b56aff"))
	mat.set_shader_parameter("edge_color",Color("4421a0"))
	preload("res://game/pixel_sparks.gd").burst(arena.slash_effects,point,Color("be8aff"),28,5)
	ring.material_override=mat
	arena.slash_effects.pieces.append({"node":ring,"life":0.5,"total":0.5,"material":mat,"expand":true})
