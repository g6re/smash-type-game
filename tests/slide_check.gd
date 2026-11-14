extends SceneTree
func _initialize() -> void:
 var arena=load("res://game/arena.gd").new()
 var initial=Vector3(0,0,-8)
 var coast=arena.slide_momentum(initial,Vector3.ZERO,0.1,true)
 assert(is_equal_approx(coast.length(),7.5) and coast.z<0)
 var reverse=arena.slide_momentum(initial,Vector3.BACK,0.1,true)
 assert(reverse.dot(initial)>0 and is_equal_approx(reverse.length(),7.5))
 var turn=arena.slide_momentum(initial,Vector3.RIGHT,0.1,true)
 assert(turn.x>0 and turn.z<0 and is_equal_approx(turn.length(),7.5))
 assert(arena.slide_momentum(initial,Vector3.ZERO,0.1,false).length()>coast.length())
 arena.free()
 print("PASS: slide coasts, loses speed, turns gradually and preserves air momentum")
 quit()
