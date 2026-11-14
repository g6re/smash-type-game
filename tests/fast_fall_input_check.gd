extends "res://maps/parkour/parkour_arena.gd"
func press(code:int,physical_only:bool) -> void:
 var event:=InputEventKey.new()
 event.physical_keycode=code
 if not physical_only:event.keycode=code
 event.pressed=true
 Input.parse_input_event(event)
 await get_tree().process_frame
 event=InputEventKey.new()
 event.physical_keycode=code
 if not physical_only:event.keycode=code
 event.pressed=false
 Input.parse_input_event(event)
 await get_tree().process_frame

func _ready() -> void:
 super._ready()
 abilities.sparring=false
 await get_tree().physics_frame
 for code in [KEY_C,KEY_CTRL]:
  reset_player()
  player.position=Vector3(4,8,5)
  player.velocity=Vector3.ZERO
  await get_tree().physics_frame
  await get_tree().physics_frame
  await press(code,true)
  assert(not fast_falling)
  await get_tree().create_timer(0.15).timeout
  await press(code,true)
  assert(fast_falling and player.velocity.y < -30,"Two physical key presses must activate fast fall in the actual map")
  await get_tree().create_timer(0.4).timeout
  assert(not fast_falling and player.is_on_floor(),"Full physics loop must land")
 print("PASS: actual physical C and Ctrl double presses activate fast fall in parkour map and land")
 get_tree().quit()
