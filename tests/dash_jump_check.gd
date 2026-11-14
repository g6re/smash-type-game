extends "res://game/arena.gd"
func _ready() -> void:
 super._ready()
 set_physics_process(false)
 player.position=Vector3(0,8,6)
 player.collision_mask=0
 await get_tree().physics_frame
 player.move_and_slide()
 jumps=2
 stamina=3
 assert(try_dash())
 dash_time=0
 parkour.tick(2.0)
 assert(parkour.dash_jump_available,"Dash jump must not expire in the air")
 var before:=stamina
 jump()
 assert(player.velocity.y==10.5 and stamina==before and not parkour.dash_jump_available)
 player.velocity.y=-1
 jump()
 assert(player.velocity.y==-1,"Consumed dash jump cannot repeat with no normal jumps left")
 assert(try_dash())
 dash_time=0
 parkour.tick(1.0)
 jump()
 assert(player.velocity.y==10.5,"Each new dash grants another jump")
 parkour.reset()
 assert(not parkour.dash_jump_available)
 print("PASS: persistent post-dash jump, free at exhausted jumps, single use and renewed by next dash")
 get_tree().quit()
