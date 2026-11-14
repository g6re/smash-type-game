extends Node3D

var shadow: MeshInstance3D
var sprite: AnimatedSprite3D
var mantle := 0.0
var climbing := false
var crouching := false
var wall_sliding := false
var face_left := false
var state := "idle"
var elapsed := 0.0

func add_clip(frames: SpriteFrames, label: String, cells: Array, fps: float, looped := true) -> void:
	frames.add_animation(label)
	frames.set_animation_speed(label, fps)
	frames.set_animation_loop(label, looped)
	var sheet := preload("res://archive/assets/pixel_ninja/ninja-black-32x32.png")
	for cell in cells:
		var tile := AtlasTexture.new()
		tile.atlas = sheet
		tile.region = Rect2(cell.x * 32, cell.y * 32, 32, 32)
		frames.add_frame(label, tile)

func _ready() -> void:
	sprite = AnimatedSprite3D.new()
	add_child(sprite)
	sprite.pixel_size = 0.105
	sprite.position.y = 0.84
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.5
	sprite.shaded = false
	sprite.no_depth_test = false
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	add_clip(frames,"idle",[Vector2i(0,4),Vector2i(0,5),Vector2i(0,6),Vector2i(0,7)],5)
	add_clip(frames,"run",[Vector2i(1,4),Vector2i(1,5),Vector2i(1,6),Vector2i(1,7)],12)
	add_clip(frames,"jump",[Vector2i(2,4),Vector2i(2,5),Vector2i(2,6)],9,false)
	add_clip(frames,"fall",[Vector2i(2,6)],1)
	add_clip(frames,"crouch",[Vector2i(0,4),Vector2i(5,5)],14,false)
	add_clip(frames,"crouch_walk",[Vector2i(5,5)],1)
	add_clip(frames,"slide",[Vector2i(5,7)],1)
	add_clip(frames,"dash",[Vector2i(1,5)],1)
	add_clip(frames,"climb",[Vector2i(6,4),Vector2i(6,5),Vector2i(6,6),Vector2i(6,7)],10)
	add_clip(frames,"wall_slide",[Vector2i(6,5)],1)
	add_clip(frames,"attack",[Vector2i(3,4),Vector2i(3,5),Vector2i(3,6),Vector2i(3,7)],6,false)
	sprite.sprite_frames = frames
	sprite.play("idle")
	# Ground marker makes the sprite's position legible while moving in depth.
	shadow = MeshInstance3D.new()
	var circle := CylinderMesh.new()
	circle.top_radius = 0.35
	circle.bottom_radius = 0.35
	circle.height = 0.008
	shadow.mesh = circle
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.02,0.025,0.04,0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = mat
	add_child(shadow)
	shadow.position.y = 0.012

func animate(dt: float, velocity: Vector3, grounded: bool, sliding: bool, dashing: bool, attack: float, _combo: int) -> void:
	elapsed += dt
	shadow.visible = grounded
	mantle = maxf(0, mantle - dt)
	var next := "idle"
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var horizontal := velocity.dot(camera.global_basis.x)
		if absf(horizontal) > 0.15: face_left = horizontal < 0
	sprite.flip_h = face_left
	var speed := Vector2(velocity.x,velocity.z).length()
	if speed > 0.3: next = "run"
	if not grounded: next = "jump" if velocity.y > 0 else "fall"
	if wall_sliding: next = "wall_slide"
	if dashing: next = "dash"
	if attack > 0: next = "attack"
	if crouching and grounded: next = "crouch_walk" if speed > 0.3 else "crouch"
	if sliding: next = "slide"
	if climbing or mantle > 0: next = "climb"
	if next != state:
		state = next
		sprite.play(state)
	# Synchronize the sword's authored frames with the actual hit window.
	if state == "attack":
		sprite.pause()
		sprite.frame = clampi(int((0.82 - attack) / 0.82 * 4),0,3)
	sprite.speed_scale = clampf(speed / 6,0.7,1.5) if state == "run" else 1.0
	sprite.position.y = 0.84
	if state == "crouch_walk": sprite.position.y += sin(elapsed*12)*0.015

