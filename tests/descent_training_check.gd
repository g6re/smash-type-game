extends SceneTree
func _initialize() -> void:call_deferred("run_check")
func run_check() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",1,24678,true)==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.set_physics_process(false)
 var dummy:Dictionary=arena.actors[-101]
 var before:Vector3=dummy.body.position
 arena.server_action(-101,"melee",{})
 assert(arena.actions.is_empty(),"Training targets cannot attack, even through the action handler")
 arena.bot_step(dummy,0.1)
 assert(Vector2(dummy.body.position.x-before.x,dummy.body.position.z-before.z).length()<0.01)
 assert(arena.actors[1].hp==112)
 arena.combat_impact(-101,Vector3(8,3.5,0))
 arena.bot_step(dummy,0.1)
 assert(dummy.body.position.x>before.x+0.05,"Dummy keeps knockback momentum instead of chasing")
 assert(dummy.label.visible==false)
 arena.server_tick(44)
 assert(arena.phase=="preparation" and arena.preparation_left>0)
 arena.server_tick(1.1)
 assert(arena.phase=="elevator","Time limit locks last valid build and descends")
 arena.server_tick(5.1)
 assert(arena.phase=="battle")
 arena.combat_impact(1,Vector3(12,4,0))
 assert(arena.hitstun>0)
 var start:Vector3=arena.player.position
 arena.move_player(0.1)
 assert(arena.player.position.x>start.x+0.1,"Player knockback survives movement steering")
 arena.restart_match()
 arena.fill_bots=false
 arena.server_tick(60)
 assert(arena.phase=="preparation" and arena.preparation_left==45,"Wait for missing humans before starting selection clock")
 print("PASS passive training targets, persistent knockback for bots/players, 45 s selection limit and waiting for players")
 quit()

