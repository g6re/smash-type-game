extends SceneTree
func _initialize() -> void:call_deferred("run_check")
func settle() -> void:
 await process_frame
 await process_frame
func run_check() -> void:
 assert(change_scene_to_file("res://game/menu/main_menu.tscn")==OK)
 await settle()
 var menu:Node=current_scene
 assert(menu.player!=null and menu.stations.size()==3)
 if DisplayServer.get_name()!="headless":
  await create_timer(0.5).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://screenshots/main-menu.png")
 menu.open_station("lore")
 assert(menu.modal.visible)
 menu.close_modal()
 menu.open_station("network")
 assert(menu.format_picker.item_count==3 and menu.port.value==24567)
 assert(menu.contents.get_global_rect().end.y<root.size.y,"Network dialog fits viewport")
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://screenshots/descent-network-menu.png")
 menu.open_station("practice")
 assert(menu.map_picker.item_count==3)
 menu.map_picker.select(0)
 menu.character_picker.select(1)
 menu.practice_button.pressed.emit()
 await settle()
 assert(current_scene.selected_character=="box")
 current_scene.options_menu.open()
 assert(paused)
 current_scene.options_menu.find_child("ReturnMainMenu",true,false).pressed.emit()
 await settle()
 assert(not paused and current_scene.stations.size()==3)
 current_scene.open_station("practice")
 current_scene.map_picker.select(2)
 current_scene.practice_button.pressed.emit()
 await settle()
 assert(current_scene.get_script()==preload("res://maps/hollow_bastion/hollow_bastion.gd"))
 assert(current_scene.selected_character=="samurai")
 print("PASS playable hub, lore, network setup, practice, pause return and map selection")
 quit()
