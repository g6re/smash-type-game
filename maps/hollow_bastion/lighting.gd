extends Node3D
var arena:Node3D

func _ready() -> void:
 var environment:Environment
 for node in arena.get_children():
  if node is WorldEnvironment:environment=node.environment
  if node is DirectionalLight3D:
   node.rotation_degrees=Vector3(-32,-38,0)
   node.light_color=Color("ffcf93")
   node.light_energy=1.3
   node.directional_shadow_max_distance=75
   node.shadow_blur=1.6
 var sky:=Sky.new()
 var sky_material:=ShaderMaterial.new()
 sky_material.shader=preload("res://maps/hollow_bastion/shaders/twilight.gdshader")
 sky.sky_material=sky_material
 environment.sky=sky
 environment.background_mode=Environment.BG_SKY
 environment.ambient_light_color=Color("a5a4db")
 environment.ambient_light_energy=0.48
 environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 environment.tonemap_exposure=0.95
 environment.glow_enabled=true
 environment.glow_intensity=0.45
 environment.glow_bloom=0.04
 environment.glow_hdr_threshold=1.25
 environment.ssao_enabled=true
 environment.ssao_radius=1.2
 environment.ssao_intensity=1.4
 environment.ssao_power=1.15
 environment.fog_light_color=Color("30233e")
 environment.fog_density=0.0015
 environment.fog_sun_scatter=0.18
 var rim:=DirectionalLight3D.new()
 rim.rotation_degrees=Vector3(-25,140,0)
 rim.light_color=Color("9d9aff")
 rim.light_energy=0.38
 add_child(rim)
 soften_materials(arena.stage)
 var sea:=MeshInstance3D.new()
 var plane:=PlaneMesh.new()
 plane.size=Vector2(2048,2048)
 sea.mesh=plane
 sea.position.y=-22
 sea.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var sea_material:=ShaderMaterial.new()
 sea_material.shader=preload("res://maps/hollow_bastion/shaders/mist_sea.gdshader")
 sea.material_override=sea_material
 add_child(sea)
 # World-only finish: the HUD and options are drawn on a higher canvas layer.
 var finish:=CanvasLayer.new()
 finish.layer=0
 add_child(finish)
 var rect:=ColorRect.new()
 rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var finish_material:=ShaderMaterial.new()
 finish_material.shader=preload("res://maps/hollow_bastion/shaders/finish.gdshader")
 rect.material=finish_material
 finish.add_child(rect)
 add_motes()

func soften_materials(node:Node) -> void:
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var original:Material=node.get_active_material(surface)
   if original is StandardMaterial3D:
    var mat:StandardMaterial3D=original.duplicate()
    mat.roughness=0.85
    mat.metallic=0.12
    mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    node.set_surface_override_material(surface,mat)
 for child in node.get_children():soften_materials(child)

func add_motes() -> void:
 var motes:=CPUParticles3D.new()
 motes.amount=55
 motes.lifetime=9
 motes.preprocess=9
 motes.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
 motes.emission_box_extents=Vector3(15,4,8)
 motes.position=Vector3(0,3,0)
 motes.direction=Vector3(0.3,1,0)
 motes.spread=35
 motes.gravity=Vector3.ZERO
 motes.initial_velocity_min=0.12
 motes.initial_velocity_max=0.35
 motes.scale_amount_min=0.025
 motes.scale_amount_max=0.055
 var sphere:=SphereMesh.new()
 sphere.radius=0.5
 sphere.height=1
 motes.mesh=sphere
 var mat:=StandardMaterial3D.new()
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.albedo_color=Color("ffdc9d")
 mat.emission_enabled=true
 mat.emission=Color("ffbd6b")
 mat.emission_energy_multiplier=1.5
 sphere.material=mat
 add_child(motes)

