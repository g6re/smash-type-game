extends "res://game/arena.gd"
const MODES=preload("res://game/game_modes.gd")
const RULES=preload("res://game/descent/rules.gd")
const LORE=preload("res://game/descent/lore.gd")
var modal:PanelContainer
var contents:VBoxContainer
var prompt:Label
var map_picker:OptionButton
var character_picker:OptionButton
var practice_button:Button
var format_picker:OptionButton
var address:LineEdit
var port:SpinBox
var bots:CheckBox
var status_label:Label
var network_mode:="descent"
var stations=[{"point":Vector3(-8,0,-5),"name":"SMASH","hint":"Porcentajes · empujes · vacío","color":Color("72dacb"),"action":"smash"},{"point":Vector3(0,0,-11),"name":"EL DESCENSO","hint":"1v1 · 2v2 · 3v3 por red","color":Color("ffc278"),"action":"network"},{"point":Vector3(8,0,-5),"name":"ARCHIVO","hint":"La última brasa","color":Color("ba9bff"),"action":"lore"},{"point":Vector3(0,0,-3),"name":"CONVERGENCIA","hint":"Tres vidas · objetivos · red","color":Color("77cfff"),"action":"convergence"}]

func build_map() -> void:
 enable_grind_rail=false
 spawn=Vector3(0,0.1,7)
 platform(Vector3(34,1,34),Vector3(0,-0.5,0),Color("252b3d"))
 for x in [-16,16]:platform(Vector3(0.6,4,34),Vector3(x,2,0),Color("39364f"))
 platform(Vector3(34,4,0.6),Vector3(0,2,-16),Color("39364f"))
 for station in stations:
  var p:Vector3=station.point
  box(self,Vector3(4,0.06,3),p+Vector3(0,0.03,0),station.color)
  for x in [-2.3,2.3]:
   box(self,Vector3(0.3,4,0.3),p+Vector3(x,2,-1),Color("454353"))
   box(self,Vector3(0.12,2.5,0.12),p+Vector3(x,2,-0.8),station.color)
  var label:=Label3D.new()
  label.text=station.name+"\n"+station.hint
  label.position=p+Vector3(0,3.5,0)
  label.font_size=40
  label.pixel_size=0.008
  label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
  label.modulate=station.color
  add_child(label)
  var light:=OmniLight3D.new()
  light.position=p+Vector3.UP*2
  light.light_color=station.color
  light.light_energy=2
  light.omni_range=7
  add_child(light)
 for x in [-12,12]:
  for z in [-12,3,12]:box(self,Vector3(0.7,5,0.7),Vector3(x,2.5,z),Color("504557"))

func _ready() -> void:
 super._ready()
 select_character("samurai",false)
 for enemy in enemies:enemy.body.queue_free()
 enemies.clear()
 abilities.sparring=false
 options_menu.queue_free()
 options_menu=null
 combat_hud.hide()
 yaw=0
 pitch=-0.35
 var layer:=CanvasLayer.new()
 layer.layer=5
 add_child(layer)
 var root:=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 layer.add_child(root)
 var title:=Label.new()
 title.text="EL CRISOL\nVestíbulo de los Portadores de Brasa"
 title.position=Vector2(28,20)
 title.add_theme_font_size_override("font_size",24)
 root.add_child(title)
 prompt=Label.new()
 prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
 prompt.position=Vector2(28,-96)
 prompt.add_theme_font_size_override("font_size",19)
 root.add_child(prompt)
 var bar:=HBoxContainer.new()
 bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
 bar.position=Vector2(28,-48)
 root.add_child(bar)
 for item in [["Modo Smash","smash"],["Convergencia","convergence"],["Práctica","practice"],["Jugar por red","network"],["Lore","lore"],["Salir","quit"]]:
  var button:=Button.new()
  button.text=item[0]
  button.pressed.connect(func():open_station(item[1]))
  bar.add_child(button)
 modal=PanelContainer.new()
 modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 modal.position=Vector2(-310,-260)
 modal.custom_minimum_size=Vector2(620,0)
 var style:=StyleBoxFlat.new()
 style.bg_color=Color("171d30")
 style.border_color=Color("bb8b58")
 style.set_border_width_all(2)
 style.set_corner_radius_all(10)
 style.content_margin_left=24
 style.content_margin_right=24
 style.content_margin_top=20
 style.content_margin_bottom=20
 modal.add_theme_stylebox_override("panel",style)
 root.add_child(modal)
 contents=VBoxContainer.new()
 contents.add_theme_constant_override("separation",12)
 modal.add_child(contents)
 modal.hide()

func label(value:String,size_value:int=18) -> Label:
 var node:=Label.new()
 node.text=value
 node.add_theme_font_size_override("font_size",size_value)
 contents.add_child(node)
 return node
func button(value:String,action:Callable) -> Button:
 var node:=Button.new()
 node.text=value
 node.custom_minimum_size.y=38
 node.pressed.connect(action)
 contents.add_child(node)
 return node
func close_modal() -> void:
 modal.hide()
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func open_station(kind:String) -> void:
 if kind=="quit":get_tree().quit();return
 for child in contents.get_children():contents.remove_child(child);child.queue_free()
 modal.show()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if kind in ["practice","smash"]:
  label("MODO SMASH" if kind=="smash" else "MODO PRÁCTICA",26)
  label("Porcentaje de daño, empuje creciente y caídas al vacío." if kind=="smash" else "Entrena libremente con los mapas y habilidades actuales.")
  map_picker=OptionButton.new()
  for item in MODES.MAPS:map_picker.add_item(item.name)
  contents.add_child(map_picker)
  character_picker=OptionButton.new()
  character_picker.add_item("Samurai de fuego")
  character_picker.add_item("Box")
  contents.add_child(character_picker)
  practice_button=button("ENTRAR A SMASH" if kind=="smash" else "ENTRAR A PRÁCTICA",func():
   var character:="samurai" if character_picker.selected==0 else "box"
   if kind=="smash":MODES.start_smash(get_tree(),map_picker.selected,character)
   else:MODES.start_practice(get_tree(),map_picker.selected,character))
 elif kind in ["network","convergence"]:
  network_mode="convergence" if kind=="convergence" else "descent"
  label("CONVERGENCIA · MULTIJUGADOR" if network_mode=="convergence" else "EL DESCENSO · MULTIJUGADOR",26)
  label("Porcentaje · tres vidas · objetivos rotativos de energía, curación y stamina." if network_mode=="convergence" else "Atributos, entrenamiento y ascensor compartidos.\nTres rondas ganadas para vencer. Samurai de fuego.")
  format_picker=OptionButton.new()
  for value in (["1 contra 1","2 contra 2"] if network_mode=="convergence" else ["1 contra 1","2 contra 2","3 contra 3"]):format_picker.add_item(value)
  contents.add_child(format_picker)
  address=LineEdit.new()
  address.placeholder_text="IP del anfitrión"
  address.text="127.0.0.1"
  contents.add_child(address)
  var row:=HBoxContainer.new()
  contents.add_child(row)
  var caption:=Label.new()
  caption.text="Puerto UDP"
  row.add_child(caption)
  port=SpinBox.new()
  port.min_value=1024
  port.max_value=65535
  port.value=RULES.PORT
  row.add_child(port)
  bots=CheckBox.new()
  bots.text="Completar huecos con bots (al crear partida)"
  bots.button_pressed=true
  contents.add_child(bots)
  button("CREAR PARTIDA",func():connect_game(true))
  button("UNIRSE POR IP",func():connect_game(false))
  status_label=label("En LAN: IP local del anfitrión. Internet: puerto UDP accesible.\nEl formato y los bots los decide el anfitrión.",15)
 elif kind=="lore":
  label("ARCHIVO DEL CRISOL",26)
  var scroll:=ScrollContainer.new()
  scroll.custom_minimum_size=Vector2(560,300)
  contents.add_child(scroll)
  var story:=Label.new()
  story.text=LORE.TEXT
  story.custom_minimum_size.x=540
  story.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  scroll.add_child(story)
 button("VOLVER AL VESTÍBULO · ESC",close_modal)

func connect_game(host:bool) -> void:
 var result:=RULES.connect_match(get_tree(),host,address.text.strip_edges(),format_picker.selected+1,int(port.value),bots.button_pressed,network_mode)
 if result!=OK:status_label.text="No se pudo abrir la conexión: "+error_string(result)

func _input(event:InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:
   if modal.visible:close_modal()
   else:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
   return
  if event.keycode==KEY_E and not modal.visible:
   for station in stations:
    if player.position.distance_to(station.point)<3.4:open_station(station.action);return
 if event is InputEventMouseButton and event.pressed and not modal.visible:
  if get_viewport().gui_get_hovered_control()==null:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not modal.visible:
  yaw-=event.relative.x*mouse_sensitivity
  pitch=clampf(pitch-event.relative.y*mouse_sensitivity,-1.35,1.15)

func move_player(dt:float) -> void:
 if modal!=null and modal.visible:return
 super.move_player(dt)
func _physics_process(dt:float) -> void:
 super._physics_process(dt)
 prompt.text="Acércate a un portal y pulsa E · WASD moverte · Esc libera el cursor"
 for station in stations:
  if player.position.distance_to(station.point)<3.4:prompt.text="E · "+station.name
func reset_player() -> void:
 player.position=spawn
 player.velocity=Vector3.ZERO


