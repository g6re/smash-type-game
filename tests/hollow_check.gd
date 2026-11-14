extends "res://maps/hollow_bastion/hollow_bastion.gd"
func _ready() -> void:
 super._ready()
 abilities.sparring=false
 await get_tree().create_timer(0.6).timeout
 assert(player.is_on_floor() and player.position.y>-0.5,"Stage platform must support the player")
 assert(not enable_grind_rail)
 var initial:=pitch
 var motion:=InputEventMouseMotion.new()
 motion.relative=Vector2(0,2500)
 _input(motion)
 if DisplayServer.get_name()!="headless":
  assert(is_equal_approx(pitch,-1.35),"Camera stops at upper viewing limit")
  motion.relative=Vector2(0,-2500)
  _input(motion)
  assert(is_equal_approx(pitch,1.15),"Camera stops at lower viewing limit")
 pitch=initial
 if DisplayServer.get_name()!="headless":
  set_physics_process(false)
  pivot.position=Vector3.ZERO
  pivot.rotation=Vector3.ZERO
  camera.position=Vector3(24,18,28)
  camera.look_at(Vector3(0,-1,0))
  await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://screenshots/hollow-bastion.png")
 print("PASS: Hollow Bastion loaded, player lands, map-specific collision and full camera orbit")
 get_tree().quit()

