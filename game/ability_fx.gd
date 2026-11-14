extends Node3D
var arena:Node3D
var kind:="uppercut"
var age:=0.0
var detonated:=false
var aftermath:=0.0
var arcs:Array[MeshInstance3D]=[]
var cut:MeshInstance3D
var cross_cut:MeshInstance3D
var fire_light:OmniLight3D
var pixels:CPUParticles3D
const PIXELS=preload("res://game/pixel_sparks.gd")

func arc(radius:float,width:float,position_value:Vector3,rotation_value:Vector3) -> MeshInstance3D:
 var node:=MeshInstance3D.new()
 node.mesh=arena.slash_effects.crescent_mesh(radius,width)
 node.material_override=arena.slash_effects.fire_material()
 add_child(node)
 node.position=position_value
 node.rotation=rotation_value
 return node

func _ready() -> void:
 if kind=="ember":
  for i in range(3):arcs.append(arc(0.46+i*0.1,0.1,Vector3.ZERO,Vector3(i*0.8,0,i)))
  pixels=PIXELS.trail(self,Color("ff852f"),20)
 elif kind=="uppercut":
  arcs.append(arc(2.6,0.6,Vector3.UP*1.6,Vector3(PI/2,0,0)))
  arcs.append(arc(2.1,0.22,Vector3.UP*0.1,Vector3.ZERO))
  PIXELS.burst(self,global_position+Vector3.UP,Color("ffad3b"),36,7)
 elif kind=="ultimate":
  # The outer boundary remains exactly the six-metre damage radius.
  arcs.append(arc(6,0.13,Vector3.UP*0.1,Vector3.ZERO))
  for i in range(4):
   arcs.append(arc(5.5-i*0.95,0.6+i*0.1,Vector3.UP*(0.3+i*0.65),Vector3(i*0.08,0,i*0.06)))
  cut=arc(4.7,0.8,Vector3.UP*3.5,Vector3(PI/2,0,0))
  cut.hide()
  cross_cut=arc(3.8,0.6,Vector3.UP*3.0,Vector3(PI/2,PI/2,0))
  cross_cut.hide()
  fire_light=OmniLight3D.new()
  fire_light.light_color=Color("ff9838")
  fire_light.omni_range=12
  fire_light.light_energy=0.8
  add_child(fire_light)
  pixels=PIXELS.trail(self,Color("ff9f38"),96)
  pixels.emission_shape=CPUParticles3D.EMISSION_SHAPE_RING
  pixels.emission_ring_radius=5.6
  pixels.emission_ring_inner_radius=2
  pixels.emission_ring_height=0.1
  pixels.initial_velocity_min=1
  pixels.initial_velocity_max=3
  pixels.gravity=Vector3(0,2,0)

func detonate() -> void:
 if detonated:return
 detonated=true
 aftermath=0
 if is_instance_valid(cut):cut.show()
 if is_instance_valid(cross_cut):cross_cut.show()
 if is_instance_valid(pixels):pixels.emitting=false
 PIXELS.burst(self,global_position+Vector3.UP,Color("ffd35e"),100,10)

func _process(dt:float) -> void:
 age+=dt
 if kind=="ember":
  for i in range(arcs.size()):
   arcs[i].rotation.y+=dt*(4+i*1.5)
   arcs[i].rotation.z+=dt*(1+i)
 elif kind=="uppercut":
  if age>0.6:queue_free();return
  var phase:=age/0.6
  arcs[0].rotation.z=-1.2+phase*2.8
  arcs[0].position.y=1.4+phase*1.2
  for node in arcs:node.material_override.set_shader_parameter("fade",1-phase)
 elif kind=="ultimate":
  if not detonated:
   var phase:=clampf(age/1.15,0,1)
   fire_light.light_energy=0.6+phase*0.7
   for i in range(arcs.size()):
    arcs[i].rotation.y+=dt*(1+i*0.5)*(1 if i%2==0 else -1)
    if i>0:
     arcs[i].scale=Vector3.ONE*(1-phase*0.15)
     arcs[i].position.y=0.3+(i-1)*0.65+sin(age*6+i)*0.12
  else:
   aftermath+=dt
   var phase:=aftermath/0.65
   if phase>=1:queue_free();return
   cut.rotation.z=-0.9+phase*1.8
   cross_cut.rotation.z=0.8-phase*1.6
   cross_cut.material_override.set_shader_parameter("fade",1-phase)
   fire_light.light_energy=3.0*(1-phase)
   cut.material_override.set_shader_parameter("fade",1-phase)
   for i in range(arcs.size()):
    arcs[i].scale=Vector3.ONE*(1+phase*0.4)
    arcs[i].position.y+=dt*(1+i*0.25)
    arcs[i].material_override.set_shader_parameter("fade",1-phase)
