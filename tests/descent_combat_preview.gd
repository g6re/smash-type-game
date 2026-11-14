extends SceneTree
func _initialize() -> void:call_deferred("preview")
func preview() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",1,24680,true)==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 arena.set_physics_process(false)
 arena.submit_ready()
 arena.server_tick(5.1)
 arena.camera.global_position=Vector3(48,52,55)
 arena.camera.look_at(Vector3.ZERO)
 arena.update_hud()
 await create_timer(0.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://screenshots/descent-expanded-map.png")
 arena.player.position=Vector3(-2,0.1,8)
 var victim:Dictionary=arena.actors[-1]
 victim.body.position=Vector3(0,0.1,8)
 arena.model.rotation.y=-PI/2
 arena.camera.global_position=Vector3(4,4,14)
 arena.camera.look_at(Vector3(-0.5,1,8))
 await physics_frame
 arena.server_action(1,"melee",{"stage":1})
 arena.server_tick(0.25)
 victim.visual.animate(0.01,Vector3.ZERO,true,false,false,0,0)
 arena.combat_hud.combo_hits=1
 arena.combat_hud.queue_redraw()
 arena.update_hud()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://screenshots/combo-hit-reaction.png")
 print("PASS rendered expanded arena and hit reaction")
 quit()
