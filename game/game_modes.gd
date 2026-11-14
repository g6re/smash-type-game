extends RefCounted
const MAPS=[
 {"name":"Arena original","scene":"res://maps/original/arena.tscn"},
 {"name":"Circuito de parkour","scene":"res://maps/parkour/parkour_arena.tscn"},
 {"name":"Hollow Bastion","scene":"res://maps/hollow_bastion/hollow_bastion.tscn"}
]
# Add future modes here without coupling the main menu to their game rules.
const MODES=[{"id":"smash","name":"Modo Smash","description":"Porcentaje de daño, empuje creciente y caídas al vacío."},{"id":"practice","name":"Modo práctica","description":"Entrena movimiento, combos y habilidades a tu ritmo."},{"id":"descent","name":"El Descenso","description":"Combate por equipos y rondas en red."},{"id":"convergence","name":"Convergencia","description":"Tres vidas, porcentaje y objetivos rotativos en red."}]
static func start_smash(tree:SceneTree,map_index:int,character:String) -> Error:
 var result:=start_practice(tree,map_index,character)
 tree.set_meta("game_mode","smash")
 return result
static func disconnect_game(tree:SceneTree) -> void:
 var api:=tree.get_multiplayer()
 if api.has_multiplayer_peer():
  api.multiplayer_peer.close()
  api.multiplayer_peer=OfflineMultiplayerPeer.new()
 if tree.has_meta("descent_peer"):
  tree.get_meta("descent_peer").close()
  tree.remove_meta("descent_peer")
static func start_practice(tree:SceneTree,map_index:int,character:String) -> Error:
 disconnect_game(tree)
 tree.set_meta("practice_character",character)
 tree.set_meta("game_mode","practice")
 tree.paused=false
 return tree.change_scene_to_file(MAPS[clampi(map_index,0,MAPS.size()-1)].scene)
static func main_menu(tree:SceneTree) -> Error:
 disconnect_game(tree)
 tree.paused=false
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 return tree.change_scene_to_file("res://game/menu/main_menu.tscn")

