extends "res://maps/parkour/parkour_arena.gd"
func _ready() -> void:
 super._ready()
 set_physics_process(false)
 assert(ropes.lines.size()==5)
 player.position=Vector3(5,0.2,8)
 await get_tree().physics_frame
 ropes.interact()
 assert(ropes.active==0,"E attaches at the starting rope")
 var start:=player.position
 for i in range(20):
  await get_tree().physics_frame
  ropes.drive(1.0/60)
 assert(player.position.distance_to(start)>2.0,"Rope carries the character")
 assert(ropes.active==0)
 ropes.detach()
 assert(ropes.active==-1 and player.velocity.y>0,"Jump releases with momentum")
 ropes.interact()
 assert(ropes.active==-1,"Reattach lock prevents accidental grabbing")
 reset_player()
 assert(ropes.active==-1 and player.position==spawn)
 print("PASS: parkour map, rope attachment, traversal, jump release, lock and respawn")
 if DisplayServer.get_name()!="headless":
  player.position=Vector3(0,1,8)
  pivot.position=Vector3(0,7,-2)
  pivot.rotation=Vector3.ZERO
  camera.position=Vector3(24,21,27)
  camera.look_at(Vector3(0,3,-4))
  await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://screenshots/parkour-islands.png")
 get_tree().quit()

