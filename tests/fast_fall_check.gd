extends "res://game/arena.gd"
func _ready() -> void:
 super._ready()
 set_physics_process(false)
 abilities.sparring=false
 player.position=Vector3(0,6,6)
 player.velocity=Vector3.ZERO
 await get_tree().physics_frame
 air_crouch_tap()
 assert(not fast_falling and crouch_tap_window>0)
 crouch_tap_window=0
 air_crouch_tap()
 assert(not fast_falling,"Expired tap must not trigger")
 var before:=stamina
 air_crouch_tap()
 assert(fast_falling and player.velocity.y==-32 and stamina==before)
 assert(not try_dash() and not begin_charge())
 var start:=player.position
 for i in range(30):
  await get_tree().physics_frame
  if fast_falling:move_fast_fall(1.0/60)
 assert(not fast_falling and player.is_on_floor() and player.position.y>=-0.02,"Fast fall lands with collision")
 assert(start.y-player.position.y>5 and stamina==before)
 air_crouch_tap()
 air_crouch_tap()
 assert(not fast_falling,"Ground crouch never activates fast fall")
 reset_player()
 assert(not fast_falling and crouch_tap_window==0)
 print("PASS: double aerial crouch, expired taps, free fast fall, solid landing and reset")
 get_tree().quit()
