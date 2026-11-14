extends SceneTree
func _initialize() -> void:call_deferred("check")
func has_collision(node:Node) -> bool:
 if node is CollisionObject3D:return true
 for child in node.get_children():
  if has_collision(child):return true
 return false
func check() -> void:
 assert(preload("res://game/descent/rules.gd").connect_match(self,true,"",3,24686,true)==OK)
 await process_frame
 await physics_frame
 var arena:Node=current_scene
 var art:Node=arena.get_node("SanctuaryArt")
 assert(art.decorated_obstacles>=12)
 assert(art.has_node("TerraceGardens"))
 assert(art.floor_material.get_shader_parameter("stone_color") is Texture2D)
 assert(art.floor_material.get_shader_parameter("grass_color") is Texture2D)
 var authored_tree:Node=art.get_node("TerraceGardens").get_child(0)
 assert(authored_tree.get_child(0) is MeshInstance3D)
 assert(authored_tree.get_child(0).mesh.get_surface_count()>=2,"Imported tree retains bark and leaf surfaces")
 assert(arena.has_node("UpperGardenNorth") and arena.has_node("UpperGardenSouth"))
 assert(not has_collision(art),"Background art adds no invisible gameplay barriers")
 assert(arena.get_node("OctagonalArena").get_child(0).shape is ConvexPolygonShape3D)
 for line in arena.ropes.lines:
  for step in range(21):assert(arena.mantle_space_clear(line.a.lerp(line.b,step/20.0)),"Art preserves rope clearances")
 if DisplayServer.get_name()!="headless":
  await create_timer(0.4).timeout
  arena.set_physics_process(false)
  arena.submit_ready()
  arena.server_tick(5.1)
  arena.player.position=Vector3(-4,0.1,6)
  arena.model.rotation.y=0.3
  arena.camera.global_position=Vector3(0.6,4,10.6)
  arena.camera.look_at(Vector3(-4,1.3,6))
  arena.energy_note=0
  arena.update_hud()
  await create_timer(0.6).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://screenshots/sanctuary-gameplay.png")
  arena.camera.projection=Camera3D.PROJECTION_ORTHOGONAL
  arena.camera.size=78
  arena.camera.global_position=Vector3(0,85,0)
  arena.camera.look_at(Vector3.ZERO,Vector3.FORWARD)
  for child in arena.get_children():
   if child is CanvasLayer:child.hide()
  await create_timer(0.4).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://screenshots/sanctuary-overview.png")
  arena.camera.size=85
  arena.camera.global_position=Vector3(55,68,78)
  arena.camera.look_at(Vector3(0,1,0))
  await create_timer(0.4).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://screenshots/sanctuary-gardens.png")
  arena.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
  arena.camera.global_position=Vector3(-13,5.5,-7)
  arena.camera.look_at(Vector3(-5,3.3,-22))
  await create_timer(0.5).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://screenshots/entrance-garden.png")
  arena.camera.global_position=Vector3(-16.0,2.2,-11.0)
  arena.camera.look_at(Vector3(-12.8,1.25,-19))
  await create_timer(0.4).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://screenshots/tunnel-entrance.png")
  arena.camera.global_position=Vector3(0,1.5,-20)
  arena.camera.look_at(Vector3(-14,1.4,-20))
  await create_timer(0.4).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://screenshots/tunnel-interior.png")
 print("PASS sanctuary materials, dressed obstacles, collision-free scenery, unchanged octagonal hull and rope clearances")
 quit()
