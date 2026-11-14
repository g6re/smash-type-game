extends SceneTree
func _initialize() -> void:call_deferred("check")
func check() -> void:
 assert(change_scene_to_file("res://game/menu/main_menu.tscn")==OK)
 await process_frame
 await process_frame
 var menu:Node=current_scene
 assert(menu.stations[0].action=="smash")
 menu.open_station("smash")
 assert(menu.practice_button.text=="ENTRAR A SMASH")
 menu.practice_button.pressed.emit()
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.set_physics_process(false)
 assert(get_meta("game_mode")=="smash")
 assert(arena.combo_limit==2 and not arena.tactical_combat and not arena.combat_hud.health_mode)
 var target:Dictionary=arena.enemies[0]
 arena.apply_hit(0,12,Vector3.RIGHT,5,1)
 assert(target.damage==12 and target.body.velocity.y==5 and target.body.velocity.x>5)
 arena.apply_hit(0,20,Vector3.RIGHT,8,2)
 assert(target.damage==32 and target.body.velocity.y==8)
 arena.start_melee(2)
 arena.attack_time=0.3
 arena.request_melee()
 assert(not arena.combo_queued,"Smash retains its original two-hit chain")
 target.body.position.y=-11
 arena.update_enemies(0.016)
 assert(target.damage==0,"Falling out resets target percentage")
 print("PASS explicit Smash entry, percentage damage, increasing knockback, original two-hit attacks and ring-out respawn")
 quit()
