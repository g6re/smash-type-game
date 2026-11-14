extends Node3D

var player: CharacterBody3D
var pivot: Node3D
var camera: Camera3D
var model: Node3D
var visual: Node3D
var collider: CollisionShape3D
var crouching := false
var climbing := false
var mantle_left := 0.0
var mantle_duration:=0.3
var mantle_velocity:=Vector3.ZERO
var mantle_start := Vector3.ZERO
var mantle_end := Vector3.ZERO
var hud: Label
var options_menu:Control
var parkour:Node3D
var motion_fx:Node3D
var feel:Node3D
var coyote_left:=0.0
var jump_buffer:=0.0
var abilities:Node3D
var mouse_sensitivity := 0.003
var movement_multiplier:=1.0
@export var use_y2k_character:=false
@export var enable_grind_rail:=true
@export var grind_extent:=18.5
@export_enum("samurai","box") var selected_character:="samurai"
const STAMINA_MAX := 3.0
const CHARGE_SECONDS := 1.5
var stamina := STAMINA_MAX
var unlimited_stamina:=false
var charging := false
var charge_time := 0.0
var skill_cooldown := 0.0
var ultimate_charge := 0.0
var ability_slots := [{"name":"Corte de energia","implemented":true},{"name":"Habilidad 2","implemented":false},{"name":"Habilidad 3","implemented":false}]
var parry_available := false
var projectiles: Array[Dictionary] = []
var combat_hud: Control
var charge_sword: Node3D
var charge_orb: MeshInstance3D
var hover_position := Vector3.ZERO
var slash_left := 0.0
var slash_direction := Vector3.ZERO
var slash_speed := 0.0
var slash_power := 0.0
var slash_hits: Array[int]=[]
var slash_effects: Node3D
var ghost_timer := 0.0
var charge_from_ground := false
var camera_offset := Vector3(0,0.6,6)
var stamina_delay := 0.0
var damage := 0.0
var yaw := PI / 4
var pitch := -0.61548
var jumps := 0
var dash_time := 0.0
var slide_time := 0.0
var crouch_tap_window:=0.0
var fast_falling:=false
var attack_time := 0.0
var combo := 0
var combo_limit:=2
var tactical_combat:=false
var combo_queued:=false
var combo_window:=0.0
var attack_cooldown := 0.0
var blades: Array[Node3D] = []
var enemies: Array[Dictionary] = []
var hit_targets: Array[int] = []
var status := "ENTRENAMIENTO"
var spawn := Vector3(0, 2, 6)

func material(color: Color, glow := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.65
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 2.0
	return m

func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func platform(size: Vector3, pos: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = pos
	box(body, size, Vector3.ZERO, color)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)

func build_map() -> void:
	preload("res://maps/original/layout.gd").build(self)

func _ready() -> void:
	if get_tree().current_scene==self and get_tree().has_meta("practice_character"):
		selected_character=get_tree().get_meta("practice_character")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("192230")
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.fog_enabled = true
	env.environment.fog_light_color = Color("283a50")
	env.environment.fog_density = 0.008
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("b6d4ff")
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 1.5
	light.shadow_enabled = true
	add_child(light)
	build_map()
	player = CharacterBody3D.new()
	add_child(player)
	player.position = spawn
	var collision := CollisionShape3D.new()
	collider = collision
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)
	model = Node3D.new()
	player.add_child(model)
	set_character_mode(use_y2k_character)
	pivot = Node3D.new()
	add_child(pivot)
	camera = Camera3D.new()
	pivot.add_child(camera)
	camera.position = Vector3(0, 0.6, 6)
	camera.current = true
	camera.fov = 62
	for pos in [Vector3(-3, 1, 0), Vector3(3, 1, -2), Vector3(0, 1, -4)]:
		var target := CharacterBody3D.new()
		add_child(target)
		target.position = pos
		var col := CollisionShape3D.new()
		col.shape = CapsuleShape3D.new()
		target.add_child(col)
		var dummy := Node3D.new()
		dummy.set_script(preload("res://game/iso_visual.gd"))
		target.add_child(dummy)
		dummy.position.y = -0.9
		var label := Label3D.new()
		label.position.y = 1.5
		label.font_size = 48
		target.add_child(label)
		enemies.append({"body": target, "damage": 0.0, "spawn": pos, "label": label, "visual": dummy})
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	canvas.add_child(hud)
	hud.hide()
	combat_hud=Control.new()
	combat_hud.set_script(preload("res://game/combat_hud.gd"))
	canvas.add_child(combat_hud)
	combat_hud.skill_name="ORBE" if selected_character=="box" else "CORTE"
	options_menu=Control.new()
	options_menu.set_script(preload("res://game/options_menu.gd"))
	options_menu.arena=self
	build_charge_sword()
	slash_effects=Node3D.new()
	slash_effects.set_script(preload("res://game/slash_fx.gd"))
	add_child(slash_effects)
	var charge_flames:=Node3D.new()
	charge_flames.set_script(preload("res://game/fire_charge.gd"))
	charge_flames.arena=self
	add_child(charge_flames)
	parkour=Node3D.new()
	parkour.set_script(preload("res://game/parkour.gd"))
	parkour.arena=self
	add_child(parkour)
	motion_fx=Node3D.new()
	motion_fx.set_script(preload("res://game/movement_fx.gd"))
	motion_fx.arena=self
	add_child(motion_fx)
	abilities=Node3D.new()
	abilities.set_script(preload("res://game/samurai_abilities.gd"))
	abilities.arena=self
	add_child(abilities)
	ability_slots[1]={"name":"Ascua fugaz","implemented":true}
	ability_slots[2]={"name":"Filo ascendente","implemented":true}
	parry_available=true
	feel=Node3D.new()
	feel.set_script(preload("res://game/game_feel.gd"))
	feel.arena=self
	add_child(feel)
	canvas.add_child(options_menu)
	hud.position = Vector2(32, 28)
	hud.add_theme_font_size_override("font_size", 17)
	hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)

func _input(event: InputEvent) -> void:
	if combo==3 and attack_cooldown>0 and not event is InputEventMouseMotion:return
	if event is InputEventKey and event.keycode==KEY_ESCAPE:return
	if get_tree().paused:return
	if event is InputEventKey and event.keycode==KEY_Q and not event.echo:
		if event.pressed and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED: begin_charge()
		elif charging: release_charge()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity,-1.35,1.15)
	# Read the physical crouch keys too: some input paths do not fill keycode.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_C,KEY_CTRL] or event.physical_keycode in [KEY_C,KEY_CTRL]:air_crouch_tap()
	if is_instance_valid(abilities) and (abilities.recovery>0 or abilities.parry_left>0 or abilities.ember_dash):return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_E:abilities.cast_ember()
		if event.keycode==KEY_F:abilities.uppercut()
		if event.keycode==KEY_X:abilities.ultimate()
		if event.keycode==KEY_V:abilities.parry()
		if event.keycode == KEY_R:
			reset_player()
		if event.keycode == KEY_SPACE:
			jump()
		if event.keycode == KEY_SHIFT: try_dash()
		if event.keycode == KEY_CTRL and not charging and player.is_on_floor() and Vector2(player.velocity.x, player.velocity.z).length()>3:
			slide_time=1.4
			status="SLIDE"
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.button_index == MOUSE_BUTTON_LEFT and not charging and slash_left<=0:
			if selected_character=="box":
				if attack_cooldown>0:return
				attack_time=0.5
				attack_cooldown=0.55
				cast_arcane_bolt(0.0)
				return
			request_melee()

func start_melee(stage:int) -> void:
	combo=stage
	combo_queued=false
	combo_window=0
	attack_time=1.05 if stage==3 else 0.82
	attack_cooldown=1.23 if stage==3 else 0.88
	hit_targets.clear()
	status="CORTE" if stage==1 else "CORTE · CONTINUACIÓN"

func request_melee() -> void:
	if fast_falling:return
	if attack_time>0:
		if combo>0 and combo<combo_limit and attack_time<=0.55:combo_queued=true
		return
	if combo>0 and combo<combo_limit and combo_window>0:
		start_melee(combo+1)
	elif attack_cooldown<=0:
		start_melee(1)

func reset_player() -> void:
	jump_buffer=0
	coyote_left=0
	combo_queued=false
	combo_window=0
	combo=0
	attack_time=0
	if is_instance_valid(abilities):abilities.reset()
	damage=0
	cancel_charge()
	if slash_left>0:finish_slash()
	player.position=spawn
	player.velocity=Vector3.ZERO
	mantle_left=0
	visual.mantle=0
	visual.mantle_active=false
	if is_instance_valid(parkour):parkour.reset()
	dash_time=0
	slide_time=0
	fast_falling=false
	crouch_tap_window=0

func set_character_mode(use_3d:bool) -> void:
	use_y2k_character=selected_character=="box" and use_3d
	if is_instance_valid(visual):
		model.remove_child(visual)
		visual.queue_free()
	var scene:PackedScene=preload("res://box/character.tscn") if selected_character=="box" else preload("res://samurai/samurai_base.tscn")
	visual=scene.instantiate()
	model.add_child(visual)
	ability_slots[0].name="Orbe arcano" if selected_character=="box" else "Espiral de fuego"

func select_character(name:String,use_3d:bool=true) -> void:
	get_tree().set_meta("practice_character",name)
	combo_queued=false
	combo_window=0
	combo=0
	if is_instance_valid(abilities):abilities.reset()
	cancel_charge()
	if slash_left>0:finish_slash()
	selected_character=name
	set_character_mode(use_3d)
	skill_cooldown=0
	attack_time=0
	ultimate_charge=0

func spend_stamina() -> bool:
	if unlimited_stamina:
		stamina=STAMINA_MAX
		return true
	if stamina<1: return false
	stamina-=1
	stamina_delay=1.0
	return true

func try_dash() -> bool:
	if combo==3 and attack_cooldown>0:return false
	if fast_falling:return false
	if is_instance_valid(abilities) and (abilities.recovery>0 or abilities.parry_left>0 or abilities.ember_dash):return false
	if charging or slash_left>0 or mantle_left>0 or dash_time>0 or not spend_stamina(): return false
	if parkour.grinding:
		parkour.grinding=false
		parkour.rail_lock=0.5
	var direction:Vector3=parkour.movement_direction()
	parkour.begin_dash(direction,clampf(player.velocity.y,0,4))
	status="DASH"
	return true

func jump() -> void:
	jump_buffer=0.12
	if fast_falling:return
	if charging or slash_left>0 or mantle_left>0: return
	if crouching and not can_stand(): return
	slide_time=0
	if parkour.jump():
		jump_buffer=0
		coyote_left=0
		return
	if player.is_on_wall() and not player.is_on_floor():
		parkour.wall_jump()
		jump_buffer=0
	elif player.is_on_floor() or (coyote_left>0 and jumps==0):
		player.velocity.y=10
		jumps=1
		coyote_left=0
		jump_buffer=0
		status="SALTO"
	elif jumps<2:
		player.velocity.y=10
		jumps=2
		jump_buffer=0
		status="SALTO AEREO"

func ray(a: Vector3, b: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(a, b)
	query.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func _physics_process(dt: float) -> void:
	jump_buffer=maxf(0,jump_buffer-dt)
	coyote_left=0.10 if player.is_on_floor() and player.velocity.y<=0 else maxf(0,coyote_left-dt)
	crouch_tap_window=maxf(0,crouch_tap_window-dt)
	if player.is_on_floor():crouch_tap_window=0
	abilities.tick(dt)
	parkour.tick(dt)
	if unlimited_stamina:stamina=STAMINA_MAX
	stamina_delay = maxf(0, stamina_delay - dt)
	if stamina_delay<=0: stamina=minf(STAMINA_MAX,stamina+dt*0.25)
	skill_cooldown=maxf(0,skill_cooldown-dt)
	attack_cooldown -= dt
	combo_window=maxf(0,combo_window-dt)
	if attack_time<=0 and combo_window<=0 and attack_cooldown<=0:combo=0
	dash_time = maxf(0,dash_time-dt)
	slide_time -= dt
	if charging:
		charge_time=minf(CHARGE_SECONDS,charge_time+dt)
		player.velocity=Vector3.ZERO
		player.position=hover_position
		model.rotation.y=yaw
		charge_sword.visible=selected_character!="box"
		charge_orb.scale=Vector3.ONE*(0.3+charge_time/CHARGE_SECONDS*0.9)
		charge_orb.rotation.y+=dt*3
	elif slash_left>0:
		advance_slash(dt)
	elif not abilities.drive(dt):
		move_player(dt)
	if player.is_on_floor() and jump_buffer>0:jump()
	feel.tick(dt)
	var camera_target:=player.position+Vector3.UP*1.5
	pivot.position.x=lerpf(pivot.position.x,camera_target.x,1-exp(-dt*35))
	pivot.position.z=lerpf(pivot.position.z,camera_target.z,1-exp(-dt*35))
	pivot.position.y=lerpf(pivot.position.y,camera_target.y,1-exp(-dt*18))
	pivot.rotation = Vector3(pitch, yaw, 0)
	camera_offset=camera_offset.lerp(Vector3(0.9,0.6,4.8) if charging or slash_left>0 else Vector3(0,0.6,6),1-exp(-dt*10))
	var camera_hit := ray(pivot.position, pivot.to_global(camera_offset))
	camera.position = camera_offset
	camera.fov=lerpf(camera.fov,72.0 if dash_time>0 else (67.0 if parkour.wallrunning or parkour.grinding else 62.0),1-exp(-dt*9))
	var roll:float=parkour.wall_normal.dot(pivot.global_basis.x)*0.08 if parkour.wallrunning else 0.0
	camera.rotation.z=lerpf(camera.rotation.z,roll,1-exp(-dt*12))
	if not camera_hit.is_empty():
		camera.global_position = camera_hit.position + camera_hit.normal * 0.25
	camera.position+=feel.camera_offset()
	camera.position.z=maxf(0.1,camera.position.z-feel.kick*feel.intensity)
	if attack_time > 0:
		attack_time=maxf(0,attack_time-dt)
		for i in range(enemies.size()):
			var e: Dictionary = enemies[i]
			var offset: Vector3 = e.body.position - player.position
			if selected_character!="box" and attack_time < (0.60 if combo==3 else 0.56) and attack_time > (0.43 if combo==3 else 0.24) and offset.length() < (3.4 if combo==3 else 3.0) and offset.normalized().dot(-model.global_basis.z) > -0.25 and not hit_targets.has(i):
				hit_targets.append(i)
				apply_hit(i,([12,14,24][clampi(combo-1,0,2)] if tactical_combat else (12 if combo==1 else 20)),offset.normalized(),(7 if combo==3 else 1) if tactical_combat else (5 if combo==1 else 8),combo)
		if selected_character=="samurai":
			if combo>0 and combo<combo_limit and combo_queued and attack_time<=0.16:
				start_melee(combo+1)
			elif attack_time<=0:
				combo_window=0.3 if combo>0 and combo<combo_limit else 0.0
				combo_queued=false
	visual.climbing = climbing
	visual.crouching = crouching
	visual.wall_sliding = player.is_on_wall() and not player.is_on_floor() and player.velocity.y < 0
	if selected_character=="samurai":
		visual.wall_running=parkour.wallrunning
		visual.wall_normal=parkour.wall_normal
		visual.protecting=abilities.parry_pose_left>0
	visual.animate(dt, player.velocity, player.is_on_floor(), slide_time > 0, dash_time > 0, attack_time, combo)
	if visual.has_method("set_casting"):visual.set_casting(charging,charge_time/CHARGE_SECONDS)
	if visual.has_method("set_parkour_pose"):visual.set_parkour_pose(parkour.wallrunning,parkour.grinding)
	motion_fx.update_effects(dt)
	update_enemies(dt)

	combat_hud.stamina=stamina
	combat_hud.damage=damage
	combat_hud.unlimited_stamina=unlimited_stamina
	combat_hud.ultimate=ultimate_charge
	combat_hud.charging=charging
	combat_hud.charge=charge_time/CHARGE_SECONDS
	combat_hud.cooldown=skill_cooldown
	combat_hud.skill_name="ORBE" if selected_character=="box" else "CORTE"
	combat_hud.boost_window=parkour.bonus_window
	combat_hud.grind_fire=parkour.grind_fire if parkour.grinding else 0.0
	combat_hud.ember_cd=abilities.ember_cd
	combat_hud.upper_cd=abilities.upper_cd
	combat_hud.parry_cd=abilities.parry_cd
	combat_hud.parry_active=abilities.parry_left>0
	combat_hud.ember_ready=is_instance_valid(abilities.ember)
	combat_hud.samurai=selected_character=="samurai"
	combat_hud.queue_redraw()

func update_enemies(dt:float) -> void:
	for e in enemies:
		e["stun"]=maxf(0,float(e.get("stun",0))-dt)
		e.body.velocity.y -= 25 * dt
		e.body.velocity.x = move_toward(e.body.velocity.x, 0, dt * 3)
		e.body.velocity.z = move_toward(e.body.velocity.z, 0, dt * 3)
		e.body.move_and_slide()
		e.visual.animate(dt,e.body.velocity,e.body.is_on_floor(),false,false,0,1)
		if e.body.position.y < -10:
			e.body.position = e.spawn
			e.body.velocity = Vector3.ZERO
			e.damage = 0.0
			status = "RING OUT!"
		e.label.text = str(int(e.damage)) + "%"



func can_stand() -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.37
	shape.height = 1.78
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, player.position + Vector3.UP * 0.92)
	query.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func mantle_space_clear(feet:Vector3) -> bool:
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=collider.shape
	query.transform=Transform3D(Basis.IDENTITY,feet+Vector3.UP*(collider.shape as CapsuleShape3D).height*0.5)
	query.exclude=[player.get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func start_mantle(front:Vector3) -> bool:
	if mantle_left>0 or charging or slash_left>0 or crouching:return false
	front=Vector3(front.x,0,front.z).normalized()
	if front.length()<0.5:return false
	var low:=ray(player.position+Vector3.UP*0.65,player.position+Vector3.UP*0.65+front*0.9)
	if low.is_empty() or absf(low.normal.y)>0.2 or front.dot(-low.normal)<0.6:return false
	var probe:Vector3=low.position+front*0.5
	probe.y=player.position.y+1.75
	var top:=ray(probe,probe-Vector3.UP*1.5)
	if top.is_empty() or top.normal.y<0.75:return false
	var height:float=top.position.y-player.position.y
	if height<0.25 or height>1.65:return false
	var destination:Vector3=top.position+Vector3.UP*0.05
	var raised:=Vector3(player.position.x,destination.y+0.05,player.position.z)
	for i in range(1,7):
		if not mantle_space_clear(player.position.lerp(raised,float(i)/6)):return false
		if not mantle_space_clear(raised.lerp(destination,float(i)/6)):return false
	mantle_start=player.position
	mantle_end=destination
	mantle_duration=clampf(0.18+height*0.09,0.22,0.34)
	mantle_left=mantle_duration
	var speed:=Vector2(player.velocity.x,player.velocity.z).length()
	mantle_velocity=front*clampf(speed,3.0,8.0)
	visual.mantle=mantle_left
	visual.mantle_active=true
	visual.mantle_progress=0.0
	var right:=Vector3.UP.cross(front).normalized()
	if visual.has_method("set_mantle_hands"):
		visual.set_mantle_hands(top.position-front*0.25+Vector3.UP*0.05,right)
	player.velocity=Vector3.ZERO
	climbing=false
	status="MANTLE"
	return true

func move_player(dt: float) -> void:
	if combo==3 and attack_cooldown>0:
		player.velocity.x=move_toward(player.velocity.x,0,dt*20)
		player.velocity.z=move_toward(player.velocity.z,0,dt*20)
		player.velocity.y-=25*dt
		player.move_and_slide()
		return
	if fast_falling:
		move_fast_fall(dt)
		return
	if mantle_left>0:
		mantle_left=maxf(0,mantle_left-dt)
		var progress:=1-mantle_left/mantle_duration
		var raised:=Vector3(mantle_start.x,mantle_end.y+0.05,mantle_start.z)
		var target:=mantle_start.lerp(raised,smoothstep(0,0.55,progress)) if progress<0.55 else raised.lerp(mantle_end,smoothstep(0.55,1,progress))
		var collision:=player.move_and_collide(target-player.position)
		visual.mantle_progress=progress
		visual.mantle=mantle_left
		visual.mantle_active=mantle_left>0
		if collision!=null:
			mantle_left=0
			visual.mantle=0
			visual.mantle_active=false
			player.velocity=Vector3.ZERO
		elif mantle_left<=0:player.velocity=mantle_velocity
		return
	if parkour.drive(dt):return
	var input := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	var direction := input.rotated(Vector3.UP,yaw).normalized()
	var front := Vector3(0,0,-1).rotated(Vector3.UP,yaw)
	if dash_time>0:
		model.rotation.y=lerp_angle(model.rotation.y,atan2(-parkour.dash_direction.x,-parkour.dash_direction.z),1-exp(-dt*18))
	elif slide_time>0:
		var slide_heading:=atan2(-player.velocity.x,-player.velocity.z)
		model.rotation.y=lerp_angle(model.rotation.y,slide_heading,1-exp(-dt*12))
	elif input.length() > 0.01:
		var target_yaw := yaw if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else atan2(-direction.x,-direction.z)
		model.rotation.y = lerp_angle(model.rotation.y,target_yaw,1-exp(-dt*18))
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		model.rotation.y = lerp_angle(model.rotation.y,yaw,1-exp(-dt*18))
	var wants_crouch := Input.is_physical_key_pressed(KEY_C) or (Input.is_physical_key_pressed(KEY_CTRL) and slide_time <= 0)
	crouching = wants_crouch or slide_time > 0 or (crouching and not can_stand())
	var capsule := collider.shape as CapsuleShape3D
	capsule.height = 1.0 if crouching else 1.8
	collider.position.y = capsule.height * 0.5
	climbing=false
	var wallrun:bool=parkour.update_wallrun(direction,dt)
	if dash_time>0:
		player.velocity=parkour.dash_direction*parkour.dash_speed+Vector3.UP*parkour.dash_vertical
		player.move_and_slide()
		return
	if wallrun:
		player.move_and_slide()
		return
	if player.is_on_floor():
		jumps=0
	else:
		player.velocity.y -=25*dt
		if player.is_on_wall() and player.velocity.y < -3 and input.length()>0:
			player.velocity.y=-3
	var speed := (2.7 if crouching else (3.0 if Input.is_physical_key_pressed(KEY_ALT) else 8.0))*movement_multiplier
	if slide_time>0:
		var momentum:=Vector3(player.velocity.x,0,player.velocity.z)
		momentum=slide_momentum(momentum,direction,dt,player.is_on_floor())
		player.velocity.x=momentum.x
		player.velocity.z=momentum.z
		player.move_and_slide()
		if Vector2(player.velocity.x,player.velocity.z).length()<2.8:slide_time=0
		if player.position.y < -12:reset_player()
		return
	var horizontal:=steer_velocity(Vector3(player.velocity.x,0,player.velocity.z),direction,speed,dt,player.is_on_floor())
	player.velocity.x=horizontal.x
	player.velocity.z=horizontal.z
	player.move_and_slide()
	if not player.is_on_floor() and not crouching and input.length()>0 and player.velocity.y<=3 and direction.dot(front)>0.6:
		start_mantle(front)
	if player.position.y < -12:
		reset_player()
	if crouching and slide_time<=0: status="AGACHADO"

func steer_velocity(current:Vector3,direction:Vector3,speed:float,dt:float,grounded:bool) -> Vector3:
	if grounded:
		return current.move_toward(direction*speed,dt*(90.0 if direction.length()>0 else 100.0))
	# Releasing movement in the air preserves traversal momentum.
	if direction.length()<0.01:return current
	# Steer without erasing the speed earned from a dash jump.
	var target_speed:=maxf(speed,current.dot(direction))
	return current.move_toward(direction*target_speed,dt*22.0)

func slide_momentum(momentum:Vector3,steering:Vector3,dt:float,grounded:bool) -> Vector3:
	var speed:=momentum.length()
	if speed<0.01:return Vector3.ZERO
	if steering.length()>0.1:
		var angle:=momentum.signed_angle_to(steering,Vector3.UP)
		momentum=momentum.rotated(Vector3.UP,clampf(angle,-1.6*dt,1.6*dt))
	# Steering preserves momentum; only friction reduces speed.
	return momentum.normalized()*maxf(0,speed-(5.0 if grounded else 0.6)*dt)

func air_crouch_tap() -> void:
	if player.is_on_floor() or charging or slash_left>0 or mantle_left>0 or fast_falling:
		crouch_tap_window=0
		return
	if crouch_tap_window<=0:
		crouch_tap_window=0.4
		return
	crouch_tap_window=0
	fast_falling=true
	var ropes:=get_node_or_null("AbilityRopes")
	if ropes!=null:ropes.release()
	parkour.reset()
	dash_time=0
	slide_time=0
	player.velocity.y=-32
	status="CAÍDA RÁPIDA"

func move_fast_fall(dt:float) -> void:
	var steering:Vector3=parkour.input_direction()
	player.velocity.x=move_toward(player.velocity.x,steering.x*5,dt*12)
	player.velocity.z=move_toward(player.velocity.z,steering.z*5,dt*12)
	player.velocity.y=maxf(-45,minf(player.velocity.y,-32)-45*dt)
	player.move_and_slide()
	if player.is_on_floor():
		fast_falling=false
		jumps=0
		motion_fx.pulse(player.position+Vector3.UP*0.1,Vector3.UP,0.7)
		status="ATERRIZAJE"
	if player.position.y < -12:reset_player()








func build_charge_sword() -> void:
	charge_sword=Node3D.new()
	model.add_child(charge_sword)
	charge_sword.position=Vector3(0.4,1.05,-0.2)
	var blade:=Sprite3D.new()
	blade.set_script(preload("res://game/charge_katana.gd"))
	charge_sword.add_child(blade)
	charge_orb=MeshInstance3D.new()
	var sphere:=SphereMesh.new()
	sphere.radius=0.16
	sphere.height=0.32
	charge_orb.mesh=sphere
	charge_orb.material_override=material(Color("ffbc65"),true)
	charge_sword.add_child(charge_orb)
	charge_orb.position=Vector3(0.403,1.054,0)
	charge_sword.visible=false

func begin_charge() -> bool:
	if combo==3 and attack_cooldown>0:return false
	if fast_falling:return false
	if is_instance_valid(abilities) and (abilities.recovery>0 or abilities.parry_left>0 or abilities.ember_dash):return false
	if charging or slash_left>0 or skill_cooldown>0 or mantle_left>0 or crouching or parkour.grinding: return false
	parkour.wallrunning=false
	charging=true
	charge_time=0
	attack_time=0
	dash_time=0
	slide_time=0
	climbing=false
	charge_from_ground=player.is_on_floor()
	hover_position=player.position
	if player.is_on_floor() and not player.test_move(player.global_transform,Vector3.UP*0.4): hover_position.y+=0.4
	player.velocity=Vector3.ZERO
	status="CARGANDO CORTE"
	return true

func cancel_charge() -> void:
	charging=false
	charge_time=0
	if charge_sword!=null: charge_sword.visible=false
	if is_instance_valid(visual) and visual.has_method("set_casting"):visual.set_casting(false,0)

func cast_arcane_bolt(power:float) -> void:
	var center:=get_viewport().get_visible_rect().size/2
	var origin:=camera.project_ray_origin(center)
	var aim:=camera.project_ray_normal(center)
	var target:=origin+aim*80
	var hit:=ray(origin,target)
	if not hit.is_empty():target=hit.position
	var muzzle:=player.position+Vector3.UP*1.15
	var bolt:=Node3D.new()
	bolt.set_script(preload("res://game/arcane_bolt.gd"))
	bolt.arena=self
	bolt.direction=(target-muzzle).normalized()
	bolt.power=power
	bolt.position=muzzle+bolt.direction*0.5
	add_child(bolt)

func release_charge() -> void:
	if not charging: return
	var power:=clampf(charge_time/CHARGE_SECONDS,0,1)
	var center:=get_viewport().get_visible_rect().size/2
	var origin:=camera.project_ray_origin(center)
	var aim:=camera.project_ray_normal(center)
	var target:=origin+aim*80
	var hit:=ray(origin,target)
	if not hit.is_empty(): target=hit.position
	var muzzle:=player.position+Vector3.UP*1.15
	var direction:=(target-muzzle).normalized()
	if direction.length()<0.1: direction=aim
	if selected_character=="box":
		cast_arcane_bolt(power)
		skill_cooldown=2.5
		cancel_charge()
		status="ORBE ARCANO"
		return
	if charge_from_ground:
		direction.y=0
		direction=direction.normalized()
	slash_direction=direction
	slash_power=power
	slash_left=0.24
	slash_speed=(6+power*8)/0.24
	slash_hits.clear()
	ghost_timer=0
	for e in enemies:player.add_collision_exception_with(e.body)
	skill_cooldown=2.5
	cancel_charge()
	charge_sword.visible=true
	slash_effects.begin(direction,power)
	slash_effects.append_point(player.position+Vector3.UP)
	slash_effects.burst(player.position+Vector3.UP*0.8)
	status="ESPIRAL DE FUEGO"

func advance_slash(dt: float) -> void:
	var start:=player.position
	var step:=minf(dt,slash_left)
	var collision:=player.move_and_collide(slash_direction*slash_speed*step)
	var end:=player.position
	for i in range(enemies.size()):
		if slash_hits.has(i):continue
		var center: Vector3=enemies[i].body.position
		var closest:=Geometry3D.get_closest_point_to_segment(center,start+Vector3.UP,end+Vector3.UP)
		if closest.distance_to(center)<1.2:
			slash_hits.append(i)
			apply_hit(i,12+slash_power*28,slash_direction,4+slash_power*4)
			slash_effects.burst(center)
	slash_effects.append_point(end+Vector3.UP)
	ghost_timer-=dt
	if ghost_timer<=0:
		ghost_timer=0.035
		if visual.has_method("emit_ghost"):visual.emit_ghost(slash_effects,end)
		else:slash_effects.ghost(visual.sprite,end+Vector3(0,0.02,0))
	slash_left=maxf(0,slash_left-step)
	if collision!=null or slash_left<=0:finish_slash()

func finish_slash() -> void:
	slash_left=0
	player.velocity=Vector3.ZERO
	charge_sword.visible=false
	for e in enemies:player.remove_collision_exception_with(e.body)
	if slash_effects!=null:slash_effects.finish()

func apply_hit(index: int, amount: float, direction: Vector3, lift:=5.0,melee_stage:int=0) -> void:
	var e: Dictionary=enemies[index]
	feel.impact(e.body.position+Vector3.UP,melee_stage==3)
	e.damage+=amount
	e.body.velocity=direction*(1.8 if tactical_combat and melee_stage in [1,2] else (5+e.damage*0.13))+Vector3.UP*(1 if tactical_combat and melee_stage in [1,2] else lift)
	e["stun"]=(0.72 if melee_stage==1 else (0.28 if melee_stage==2 else 0.45)) if tactical_combat else 0.0
	if e.visual.has_method("react_to_hit"):e.visual.react_to_hit(e.stun)
	ultimate_charge=minf(100,ultimate_charge+amount*0.75)

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and charging: cancel_charge()








