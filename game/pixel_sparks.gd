extends RefCounted

static func setup(particles:CPUParticles3D,color:Color) -> void:
 var image:=Image.create(7,7,false,Image.FORMAT_RGBA8)
 for y in range(7):
  for x in range(7):
   if (abs(x-3)<=1 and abs(y-3)<=2) or (abs(x-3)<=2 and y==3):
    image.set_pixel(x,y,Color.WHITE if x==3 and y==3 else Color(0.8,0.8,0.8,1))
 var mesh:=QuadMesh.new()
 mesh.size=Vector2(0.13,0.13)
 var mat:=StandardMaterial3D.new()
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.albedo_texture=ImageTexture.create_from_image(image)
 mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
 mat.alpha_scissor_threshold=0.4
 mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
 mat.vertex_color_use_as_albedo=true
 mesh.material=mat
 particles.mesh=mesh
 particles.scale_amount_min=0.7
 particles.scale_amount_max=1.7
 var gradient:=Gradient.new()
 gradient.colors=PackedColorArray([Color(1,0.95,0.7,1),color,Color(color.r*0.5,color.g*0.5,color.b*0.5,0)])
 particles.color_ramp=gradient

static func burst(parent:Node3D,point:Vector3,color:Color,count:int=24,speed:float=4.0) -> CPUParticles3D:
 var particles:=CPUParticles3D.new()
 setup(particles,color)
 particles.amount=count
 particles.lifetime=0.65
 particles.one_shot=true
 particles.explosiveness=1
 particles.direction=Vector3.UP
 particles.spread=100
 particles.gravity=Vector3(0,-3,0)
 particles.initial_velocity_min=speed*0.35
 particles.initial_velocity_max=speed
 particles.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE
 particles.emission_sphere_radius=0.25
 parent.add_child(particles)
 particles.global_position=point
 parent.get_tree().create_timer(1.0,false).timeout.connect(particles.queue_free)
 return particles

static func trail(parent:Node3D,color:Color,count:int=32) -> CPUParticles3D:
 var particles:=CPUParticles3D.new()
 setup(particles,color)
 particles.amount=count
 particles.lifetime=0.45
 particles.direction=Vector3.UP
 particles.spread=80
 particles.gravity=Vector3(0,1,0)
 particles.initial_velocity_min=0.3
 particles.initial_velocity_max=1.5
 parent.add_child(particles)
 return particles
