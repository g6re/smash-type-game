extends Control

var arena:Node3D
var continue_button:Button

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade:=ColorRect.new()
	shade.color=Color(0.015,0.025,0.04,0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center:=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel:=PanelContainer.new()
	panel.custom_minimum_size=Vector2(520,0)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172431")
	style.set_corner_radius_all(12)
	style.content_margin_left=28
	style.content_margin_right=28
	style.content_margin_top=22
	style.content_margin_bottom=22
	panel.add_theme_stylebox_override("panel",style)
	center.add_child(panel)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	var options_scroll:=ScrollContainer.new()
	options_scroll.custom_minimum_size=Vector2(520,560)
	options_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(options_scroll)
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	options_scroll.add_child(column)
	label(column,"OPCIONES · PAUSA",26)
	var home:=Button.new()
	home.name="ReturnMainMenu"
	home.text="Volver al menú principal"
	column.add_child(home)
	home.pressed.connect(func():preload("res://game/game_modes.gd").main_menu(get_tree()))
	var maps:=OptionButton.new()
	maps.add_item("Mapa · Arena original")
	maps.add_item("Mapa · Islas de parkour")
	maps.add_item("Mapa · Hollow Bastion")
	maps.select(2 if arena.get_script().resource_path.ends_with("hollow_bastion.gd") else (1 if arena.get_script().resource_path.ends_with("parkour_arena.gd") else 0))
	column.add_child(maps)
	maps.item_selected.connect(func(index:int):
		get_tree().paused=false
		if get_tree().get_meta("game_mode","practice")=="smash":preload("res://game/game_modes.gd").start_smash(get_tree(),index,arena.selected_character)
		else:preload("res://game/game_modes.gd").start_practice(get_tree(),index,arena.selected_character))
	var sensitivity:=label(column,"Sensibilidad del ratón: 1.0×",16)
	var slider:=HSlider.new()
	slider.min_value=0.5
	slider.max_value=2.0
	slider.step=0.1
	slider.value=arena.mouse_sensitivity/0.003
	column.add_child(slider)
	slider.value_changed.connect(func(value:float):
		arena.mouse_sensitivity=0.003*value
		sensitivity.text="Sensibilidad del ratón: %.1f×" % value)
	label(column,"CONTROLES",18)
	label(column,"Movimiento de cámara e impactos",16)
	var feedback:=HSlider.new()
	feedback.min_value=0
	feedback.max_value=1
	feedback.step=0.05
	feedback.value=arena.feel.intensity
	column.add_child(feedback)
	feedback.value_changed.connect(func(value:float):
		arena.feel.intensity=value
		arena.feel.save_settings())
	label(column,"Volumen de efectos y ambiente",16)
	var effects_volume:=HSlider.new()
	effects_volume.min_value=0
	effects_volume.max_value=1
	effects_volume.step=0.05
	effects_volume.value=arena.feel.volume
	column.add_child(effects_volume)
	effects_volume.value_changed.connect(func(value:float):
		arena.feel.volume=value
		arena.feel.save_settings())
	var unlimited:=CheckButton.new()
	unlimited.name="UnlimitedStamina"
	unlimited.text="Stamina ilimitada · entrenamiento"
	unlimited.button_pressed=arena.unlimited_stamina
	column.add_child(unlimited)
	unlimited.toggled.connect(func(enabled:bool):
		arena.unlimited_stamina=enabled
		if enabled:arena.stamina=arena.STAMINA_MAX)
	var character_button:=OptionButton.new()
	var sparring:=CheckButton.new()
	sparring.text="Muñecos atacan · practicar parry"
	sparring.button_pressed=arena.abilities.sparring
	column.add_child(sparring)
	sparring.toggled.connect(func(enabled:bool):arena.abilities.sparring=enabled)
	character_button.add_item("Box · magia")
	character_button.add_item("Samurái · pixel art")
	character_button.select(0 if arena.selected_character=="box" else 1)
	column.add_child(character_button)
	character_button.item_selected.connect(func(index:int):
		arena.select_character("box" if index==0 else "samurai",index==0))
	var grid:=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",30)
	grid.add_theme_constant_override("v_separation",4)
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size.y=140
	column.add_child(scroll)
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for pair in [["E junto a una cuerda","Engancharse / soltarse"],["Espacio en cuerda","Saltar con impulso"],["WASD","Moverse"],["Alt + WASD","Caminar despacio"],["Ratón","Mover la cámara"],["Espacio","Saltar / salto en el aire"],["Shift","Dash controlado (1 stamina)"],["Espacio durante dash","Corta el dash y salta gratis"],["C","Agacharse"],["C o Ctrl dos veces en el aire","Caída rápida sin stamina"],["Ctrl","Deslizarse"],["Avanzar contra un borde","Mantle automático en el aire"],["Avanzar junto a una pared","Wallrun en el aire (máx. 1,25 s)"],["Espacio tras walljump","Impulso gratis durante 0,4 s"],["Aterrizar en el rail flotante","Grind y cargar fuego en los pies"],["Espacio desde el rail","Salto con dash gratis"],["Clic izquierdo","Autoataque"],["Botón derecho","Strafe"],["Q (mantener / soltar)","Cargar / lanzar habilidad"],["E fuera de cuerdas","Ascua / impulso hacia la brasa"],["F","Filo ascendente"],["X","Eclipse carmesí (100 % ult)"],["V","Parry frontal · 0,22 s"],["R","Reiniciar personaje"],["Escape","Abrir / cerrar este menú"]]:
		label(grid,pair[0],15)
		label(grid,pair[1],15)
	var buttons:=HBoxContainer.new()
	buttons.add_theme_constant_override("separation",12)
	column.add_child(buttons)
	continue_button=Button.new()
	continue_button.text="Continuar"
	continue_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	continue_button.custom_minimum_size.y=40
	buttons.add_child(continue_button)
	continue_button.pressed.connect(resume)
	var restart:=Button.new()
	restart.text="Reiniciar personaje"
	restart.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	buttons.add_child(restart)
	restart.pressed.connect(func():
		arena.reset_player()
		resume())
	hide()

func label(parent:Node,text:String,size:int) -> Label:
	var entry:=Label.new()
	entry.text=text
	entry.add_theme_font_size_override("font_size",size)
	parent.add_child(entry)
	return entry

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		if visible:resume()
		else:open()
		get_viewport().set_input_as_handled()

func open() -> void:
	arena.cancel_charge()
	if arena.slash_left>0:arena.finish_slash()
	show()
	get_tree().paused=true
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	continue_button.grab_focus()

func resume() -> void:
	hide()
	get_tree().paused=false
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED





