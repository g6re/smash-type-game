extends Node3D
## Presentation only: never pauses the scene tree or changes network clocks.
var arena:Node3D
var intensity:=0.65
var volume:=0.65
var hit_pause:=0.0
var kick:=0.0
var clock:=0.0
var step_distance:=0.0
var previous:=Vector3.ZERO
var grounded:=false
var last_velocity:=Vector3.ZERO
var last_dash:=false
var last_attack:=0.0
var last_stamina:=3.0
var dust_left:=0.0
var sounds:Dictionary={}
var voices:Array[AudioStreamPlayer3D]=[]
var ambience:AudioStreamPlayer3D
var voice_index:=0

func _ready() -> void:
	var settings:=ConfigFile.new()
	if settings.load("user://game_feel.cfg")==OK:
		intensity=clampf(float(settings.get_value("feel","intensity",0.65)),0,1)
		volume=clampf(float(settings.get_value("feel","volume",0.65)),0,1)
	previous=arena.player.position
	for kind in ["step","jump","dash","land","swing","hit","heavy","ready","slide"]:
		sounds[kind]=synthesize(kind)
	for i in range(8):
		var voice:=AudioStreamPlayer3D.new()
		voice.max_distance=35
		voice.unit_size=5
		add_child(voice)
		voices.append(voice)
	if arena.has_node("SanctuaryArt/RiverGardens") or arena.has_node("SanctuaryArt/Waterways"):
		ambience=AudioStreamPlayer3D.new()
		ambience.stream=synthesize("river")
		ambience.unit_size=14
		ambience.max_distance=65
		add_child(ambience)
		ambience.play()

func synthesize(kind:String) -> AudioStreamWAV:
	var duration:float={"step":0.09,"jump":0.17,"dash":0.23,"land":0.22,"swing":0.18,"hit":0.16,"heavy":0.26,"ready":0.32,"slide":0.25,"river":2.0}[kind]
	var rate:=22050
	var bytes:=PackedByteArray()
	bytes.resize(int(duration*rate)*2)
	var rng:=RandomNumberGenerator.new()
	rng.seed=kind.hash()
	var filtered:=0.0
	for i in range(bytes.size()/2):
		var t:=float(i)/rate
		var p:=t/duration
		var noise:=rng.randf_range(-1,1)
		filtered=lerpf(filtered,noise,0.22)
		var envelope:=sin(minf(1,p*25)*PI*0.5)*pow(1-p,2)
		var sample:=filtered
		match kind:
			"step","land":sample=filtered*0.65+sin(TAU*(95-45*p)*t)*0.35
			"jump","dash","swing","slide":sample=noise*0.2+filtered*0.8
			"hit","heavy":sample=noise*exp(-p*20)*0.6+sin(TAU*(160-90*p)*t)*0.45+filtered*0.3
			"ready":sample=sin(TAU*660*t)*0.22+sin(TAU*990*t)*0.16
			"river":
				envelope=1.0
				sample=filtered*0.65+noise*0.08
		bytes.encode_s16(i*2,int(clampf(sample*envelope*0.65,-1,1)*32767))
	var wave:=AudioStreamWAV.new()
	wave.format=AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate=rate
	wave.data=bytes
	if kind=="river":
		wave.loop_mode=AudioStreamWAV.LOOP_FORWARD
		wave.loop_end=bytes.size()/2
	return wave

func sound(kind:String,point:Vector3,strength:float=1.0) -> void:
	if volume<=0:return
	var voice:=voices[voice_index%voices.size()]
	voice_index+=1
	voice.global_position=point
	voice.stream=sounds[kind]
	voice.volume_db=linear_to_db(maxf(0.001,volume*strength))-10
	voice.pitch_scale=randf_range(0.94,1.06)
	voice.play()

func impact(point:Vector3,heavy:bool=false,involved:bool=true) -> void:
	sound("heavy" if heavy else "hit",point)
	if involved:
		hit_pause=maxf(hit_pause,0.065 if heavy else 0.035)
		kick=maxf(kick,0.14 if heavy else 0.055)
	preload("res://game/pixel_sparks.gd").burst(arena,point,Color("ffe1a3"),14 if heavy else 7,2.5)

func tick(dt:float) -> void:
	clock+=dt
	hit_pause=maxf(0,hit_pause-dt)
	kick=move_toward(kick,0,dt*0.8)
	dust_left=maxf(0,dust_left-dt)
	var body:CharacterBody3D=arena.player
	var floor_now:=body.is_on_floor()
	var distance:=Vector2(body.position.x-previous.x,body.position.z-previous.z).length()
	if distance<2 and floor_now and arena.dash_time<=0 and arena.slide_time<=0:
		step_distance+=distance
		if step_distance>1.55:
			step_distance=0
			var surface:=0.65 if arena.crouching else 1.0
			sound("step",body.position,surface)
			contact(body.position,3)
	if floor_now and not grounded and last_velocity.y< -3:
		var strength:=clampf(-last_velocity.y/18,0.2,1)
		sound("land",body.position,strength)
		kick=maxf(kick,strength*0.09)
		contact(body.position,8)
	if not floor_now and grounded and body.velocity.y>5:sound("jump",body.position,0.7)
	if arena.dash_time>0 and not last_dash:sound("dash",body.position)
	if arena.attack_time>last_attack+0.1:sound("swing",body.position,0.8)
	if int(arena.stamina)>int(last_stamina):sound("ready",body.position,0.5)
	if arena.slide_time>0 and floor_now and dust_left<=0:
		dust_left=0.18
		sound("slide",body.position,0.35)
		contact(body.position,4)
	if is_instance_valid(ambience):
		var p:Vector3=body.position
		var side:=1 if p.z>=0 else -1
		var river_z:float=side*(40.5+sin(p.x*0.065)*2.2+cos(p.x*0.13)*0.8)
		ambience.global_position=Vector3(clampf(p.x,-70,70),-3.55,river_z)
		if arena.has_node("SanctuaryArt/Waterways"):
			ambience.global_position=Vector3(clampf(p.x,-18,18),3.23,side*25.2)
		ambience.volume_db=linear_to_db(maxf(0.001,volume))-15
	previous=body.position
	grounded=floor_now
	last_velocity=body.velocity
	last_dash=arena.dash_time>0
	last_attack=arena.attack_time
	last_stamina=arena.stamina

func contact(point:Vector3,count:int) -> void:
	var leafy:=arena.has_node("SanctuaryArt") and absf(point.z)>24 and absf(point.z)<30
	preload("res://game/pixel_sparks.gd").burst(arena,point+Vector3.UP*0.08,Color("dba551") if leafy else Color("a5967b"),count,0.65)

func save_settings() -> void:
	var settings:=ConfigFile.new()
	settings.set_value("feel","intensity",intensity)
	settings.set_value("feel","volume",volume)
	settings.save("user://game_feel.cfg")

func camera_offset() -> Vector3:
	return Vector3(sin(clock*71),cos(clock*83),0)*kick*intensity
