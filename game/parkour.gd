extends Node3D
var arena:Node3D
var wallrunning:=false
var wall_normal:=Vector3.ZERO
var wall_contact:=Vector3.ZERO
var wall_tangent:=Vector3.FORWARD
var wall_budget:=1.25
var wall_lock:=0.0
var bonus_window:=0.0
var bonus_direction:=Vector3.FORWARD
var dash_direction:=Vector3.FORWARD
var dash_vertical:=0.0
var dash_speed:=18.0
var dash_jump_available:=false
var grinding:=false
var rail_s:=0.0
var rail_sign:=1.0
var rail_speed:=10.0
var rail_lock:=0.0
var grind_fire:=0.0
var fire_afterglow:=0.0
var EDGE:=18.5
const RAIL_Y:=1.35
var SIDE:=EDGE*2

func _ready() -> void:
	EDGE=arena.grind_extent
	SIDE=EDGE*2
	if arena.enable_grind_rail:build_rail()

func tick(dt:float) -> void:
	wall_lock=maxf(0,wall_lock-dt)
	rail_lock=maxf(0,rail_lock-dt)
	bonus_window=maxf(0,bonus_window-dt)
	if arena.player.is_on_floor() and arena.dash_time<=0:dash_jump_available=false
	fire_afterglow=maxf(0,fire_afterglow-dt)
	if arena.player.is_on_floor() and not grinding:wall_budget=1.25
	if not grinding:grind_fire=maxf(0,grind_fire-dt*0.5)

func input_direction() -> Vector3:
	var v:=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	return v.rotated(Vector3.UP,arena.yaw).normalized()

func movement_direction() -> Vector3:
	var direction:=input_direction()
	return direction if direction.length()>0.1 else -arena.model.global_basis.z

func begin_dash(direction:Vector3,vertical:float=0.0,strength:float=1.0) -> void:
	arena.slide_time=0
	dash_direction=Vector3(direction.x,0,direction.z).normalized()
	if dash_direction.length()<0.1:dash_direction=Vector3.FORWARD.rotated(Vector3.UP,arena.yaw)
	dash_vertical=vertical
	dash_speed=18*strength
	arena.dash_time=0.22
	dash_jump_available=true
	arena.player.velocity=dash_direction*dash_speed+Vector3.UP*vertical
	wallrunning=false
	wall_lock=0.18
	arena.motion_fx.pulse(arena.player.position+Vector3.UP*0.6,dash_direction,strength)

func wall_jump() -> void:
	var normal:Vector3=wall_normal if wallrunning else arena.player.get_wall_normal()
	var tangent:=Vector3(arena.player.velocity.x,0,arena.player.velocity.z)
	tangent-=normal*tangent.dot(normal)
	arena.player.velocity=normal*10+tangent.limit_length(6)+Vector3.UP*10
	wallrunning=false
	wall_lock=0.25
	bonus_window=0.40
	bonus_direction=Vector3(arena.player.velocity.x,0,arena.player.velocity.z).normalized()
	arena.jumps=1
	arena.status="WALL JUMP · ESPACIO PARA IMPULSO"

func jump() -> bool:
	if grinding:
		var tangent:=movement_direction()
		grinding=false
		rail_lock=0.65
		var strength:=1.0+grind_fire*0.15
		fire_afterglow=1.0
		begin_dash(tangent,10,strength)
		grind_fire=0
		arena.status="SALTO DE RAIL · IMPULSO"
		return true
	if arena.dash_time>0 and dash_jump_available:
		dash_jump()
		return true
	if bonus_window>0:
		bonus_window=0
		begin_dash(movement_direction(),clampf(arena.player.velocity.y,1,5),1.08)
		arena.status="IMPULSO DE PARED"
		return true
	if wallrunning:
		wall_jump()
		return true
	if dash_jump_available and not arena.player.is_on_wall():
		dash_jump()
		return true
	return false

func dash_jump() -> void:
	dash_jump_available=false
	arena.dash_time=0
	var direction:=movement_direction()
	arena.player.velocity=direction*12.5+Vector3.UP*10.5
	wall_lock=0.15
	arena.status="DASH · SALTO"

func update_wallrun(direction:Vector3,dt:float) -> bool:
	wallrunning=false
	if arena.player.is_on_floor() or wall_lock>0 or wall_budget<=0 or arena.dash_time>0 or arena.crouching or direction.length()<0.1:return false
	var origin:Vector3=arena.player.position+Vector3.UP*1.0
	var side:=Vector3.UP.cross(direction).normalized()
	for probe in [side,-side]:
		var hit:Dictionary=arena.ray(origin,origin+probe*0.95)
		if hit.is_empty() or absf(hit.normal.y)>0.2:continue
		var normal:Vector3=hit.normal
		var tangent:Vector3=(direction-normal*direction.dot(normal)).normalized()
		if tangent.length()<0.5 or absf(direction.dot(normal))>0.65:continue
		wallrunning=true
		wall_normal=normal
		wall_contact=hit.position
		wall_tangent=tangent
		# Wallrun poses face along the wall, independently of camera/strafe facing.
		arena.model.rotation.y=atan2(-tangent.x,-tangent.z)
		wall_budget=maxf(0,wall_budget-dt)
		var gap:float=(origin-hit.position).dot(normal)
		var separation:float=clampf((0.52-gap)*20,-3,4)
		arena.player.velocity=tangent*10.5+normal*separation+Vector3.UP*clampf(arena.player.velocity.y-dt*3.0,-2,2.5)
		arena.status="WALLRUN"
		return true
	return false

func drive(dt:float) -> bool:
	if not grinding:try_grind()
	if not grinding:return false
	rail_s=fposmod(rail_s+rail_speed*rail_sign*dt,SIDE*4)
	var point:=rail_point(rail_s)
	var collision:KinematicCollision3D=arena.player.move_and_collide(point-arena.player.position)
	if collision!=null:
		grinding=false
		rail_lock=0.4
		return false
	var tangent:=rail_tangent(rail_s)*rail_sign
	arena.player.velocity=tangent*rail_speed
	arena.model.rotation.y=lerp_angle(arena.model.rotation.y,atan2(-tangent.x,-tangent.z),1-exp(-dt*22))
	grind_fire=minf(1,grind_fire+dt*0.5)
	arena.status="GRIND · ESPACIO PARA SALTAR"
	return true

func try_grind() -> bool:
	if not arena.enable_grind_rail:return false
	if rail_lock>0 or arena.charging or arena.slash_left>0 or arena.mantle_left>0 or arena.player.velocity.y>3:return false
	var p:Vector3=arena.player.position
	if absf(p.y-RAIL_Y)>0.42:return false
	var nearest:=Vector3.ZERO
	var best:=INF
	var best_s:=0.0
	for edge in range(4):
		var a:=rail_point(edge*SIDE)
		var b:=rail_point((edge+1)*SIDE if edge<3 else 0)
		var candidate:=Geometry3D.get_closest_point_to_segment(p,a,b)
		var distance:=Vector2(candidate.x-p.x,candidate.z-p.z).length()
		if distance<best:best=distance;nearest=candidate;best_s=edge*SIDE+a.distance_to(candidate)
	if best>0.48:return false
	if not arena.mantle_space_clear(nearest):return false
	var velocity:Vector3=Vector3(arena.player.velocity.x,0,arena.player.velocity.z)
	if velocity.length()<2:return false
	rail_s=best_s
	rail_sign=1 if velocity.dot(rail_tangent(rail_s))>=0 else -1
	rail_speed=clampf(velocity.length()+1,9,12)
	grinding=true
	wallrunning=false
	arena.player.position=nearest
	arena.dash_time=0
	return true

func rail_point(s:float) -> Vector3:
	s=fposmod(s,SIDE*4)
	if s<SIDE:return Vector3(-EDGE+s,RAIL_Y,-EDGE)
	if s<SIDE*2:return Vector3(EDGE,RAIL_Y,-EDGE+s-SIDE)
	if s<SIDE*3:return Vector3(EDGE-(s-SIDE*2),RAIL_Y,EDGE)
	return Vector3(-EDGE,RAIL_Y,EDGE-(s-SIDE*3))

func rail_tangent(s:float) -> Vector3:
	return [Vector3.RIGHT,Vector3.BACK,Vector3.LEFT,Vector3.FORWARD][mini(3,int(fposmod(s,SIDE*4)/SIDE))]

func reset() -> void:
	grinding=false
	wallrunning=false
	bonus_window=0
	dash_jump_available=false
	grind_fire=0
	fire_afterglow=0
	wall_budget=1.25
	rail_lock=0.3

func build_rail() -> void:
	for edge in range(4):
		var a:=rail_point(edge*SIDE)
		var b:=rail_point((edge+1)*SIDE)
		var center:Vector3=(a+b)/2-Vector3.UP*0.1
		arena.platform(Vector3(SIDE,0.12,0.12) if edge%2==0 else Vector3(0.12,0.12,SIDE),center,Color("d5b77d"))
		# Floating guide lights replace fence posts: the rail sits over the void.
		for mark in range(12):
			var p:=a.lerp(b,float(mark)/11)-Vector3.UP*0.10
			var light:MeshInstance3D=arena.box(self,Vector3(0.12,0.025,0.12),p,Color("ffba63"))
			light.material_override=arena.material(Color("ffba63"),true)
