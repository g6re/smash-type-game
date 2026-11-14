extends Node3D
var arena:Node3D
var ember_cd:=0.0
var upper_cd:=0.0
var parry_cd:=0.0
var parry_left:=0.0
var parry_pose_left:=0.0
var recovery:=0.0
var ember:MeshInstance3D
var ember_life:=0.0
var ember_target:=Vector3.ZERO
var ember_flying:=false
var ember_dash:=false
var ember_hits:Array[int]=[]
var ember_trail_timer:=0.0
var ult_left:=0.0
var ult_center:=Vector3.ZERO
var ult_marker:Node3D
var parry_marker:Node3D
var sparring:=true
var enemy_timers:Array[float]=[]
var enemy_marks:Array[MeshInstance3D]=[]

func _ready() -> void:
 for enemy in arena.enemies:
  enemy_timers.append(1.8)
  enemy_marks.append(null)

func ring(point:Vector3,radius:float,color:Color,life:float) -> MeshInstance3D:
 var mesh:=MeshInstance3D.new()
 var shape:=TorusMesh.new()
 shape.inner_radius=radius*0.92
 shape.outer_radius=radius
 mesh.mesh=shape
 mesh.material_override=arena.slash_effects.glow(color)
 arena.slash_effects.add_child(mesh)
 mesh.position=point
 if life>0:arena.slash_effects.pieces.append({"node":mesh,"life":life,"total":life,"material":mesh.material_override,"expand":true})
 return mesh

func ready_to_cast() -> bool:
 if arena.fast_falling:return false
 return arena.selected_character=="samurai" and not arena.charging and arena.slash_left<=0 and arena.mantle_left<=0 and recovery<=0 and parry_left<=0 and ult_left<=0 and not ember_dash

func detach_rope() -> void:
 var ropes:Node=arena.get_node_or_null("AbilityRopes")
 if ropes!=null and ropes.active>=0:ropes.detach()

func spawn_skill_effect(kind:String,point:Vector3,parent:Node3D=null) -> Node3D:
 var effect:=Node3D.new()
 effect.set_script(preload("res://game/ability_fx.gd"))
 effect.arena=arena
 effect.kind=kind
 effect.position=point
 (parent if parent!=null else arena).add_child(effect)
 return effect

func cast_ember() -> bool:
 if not ready_to_cast():return false
 if is_instance_valid(ember):
  if ember_flying:return false
  detach_rope()
  arena.parkour.reset()
  arena.dash_time=0
  arena.slide_time=0
  ember_dash=true
  ember_hits.clear()
  ember_trail_timer=0
  return true
 if ember_cd>0:return false
 var origin:Vector3=arena.player.position+Vector3.UP
 var aim:Vector3=-arena.camera.global_basis.z
 var hit:Dictionary=arena.ray(origin,origin+aim*16)
 ember_target=hit.position+hit.normal*0.5 if not hit.is_empty() else origin+aim*16
 ember=MeshInstance3D.new()
 var shape:=SphereMesh.new()
 shape.radius=0.18
 shape.height=0.36
 ember.mesh=shape
 ember.material_override=arena.slash_effects.glow(Color("ff8c32"))
 add_child(ember)
 ember.global_position=origin
 spawn_skill_effect("ember",Vector3.ZERO,ember)
 ember_life=5
 ember_flying=true
 ember_cd=8
 arena.status="ASCUA · E PARA IMPULSARTE"
 return true

func uppercut() -> bool:
 if not ready_to_cast() or upper_cd>0:return false
 detach_rope()
 upper_cd=6
 arena.slide_time=0
 arena.dash_time=0
 arena.parkour.reset()
 arena.player.velocity.y=12
 # Does not restore consumed jumps.
 arena.jumps=maxi(1,arena.jumps)
 var origin:Vector3=arena.player.position+Vector3.UP
 var rising:=spawn_skill_effect("uppercut",arena.player.position)
 rising.rotation.y=arena.model.rotation.y
 var forward:Vector3=-arena.model.global_basis.z
 for i in range(arena.enemies.size()):
  var delta:Vector3=arena.enemies[i].body.position-origin
  if delta.length()<3.2 and (delta.length()<0.1 or delta.normalized().dot(forward)>-0.2) and visible_target(origin,arena.enemies[i].body):
   arena.apply_hit(i,18,forward*0.25,13)
 arena.status="FILO ASCENDENTE"
 return true

func ultimate() -> bool:
 if not ready_to_cast() or arena.ultimate_charge<100:return false
 detach_rope()
 arena.ultimate_charge=0
 ult_left=1.15
 ult_center=arena.player.position
 ult_marker=spawn_skill_effect("ultimate",ult_center)
 arena.status="ECLIPSE CARMESÍ"
 return true

func parry() -> bool:
 if not ready_to_cast() or parry_cd>0:return false
 arena.attack_time=0
 arena.attack_cooldown=maxf(arena.attack_cooldown,0.45)
 parry_left=0.22
 parry_pose_left=0.22
 parry_cd=1.2
 parry_marker=spawn_parry_effect(false)
 arena.status="PARRY"
 return true

func spawn_parry_effect(perfect:bool) -> Node3D:
 var effect:=Node3D.new()
 effect.set_script(preload("res://game/parry_fx.gd"))
 effect.arena=arena
 effect.success=perfect
 effect.position=arena.player.position+Vector3.UP
 effect.rotation.y=arena.model.rotation.y
 arena.add_child(effect)
 return effect

func receive_hit(amount:float,source:Vector3,knockback:Vector3,enemy_index:int=-1) -> bool:
 var incoming:Vector3=source-(arena.player.position+Vector3.UP)
 incoming.y=0
 var forward:Vector3=-arena.model.global_basis.z
 if parry_left>0 and (incoming.length()<0.1 or incoming.normalized().dot(forward)>0.15):
  parry_left=0
  parry_pose_left=0.12
  recovery=0
  arena.stamina=minf(arena.STAMINA_MAX,arena.stamina+1)
  spawn_parry_effect(true)
  if is_instance_valid(parry_marker):parry_marker.queue_free()
  if enemy_index>=0:
   var target:Dictionary=arena.enemies[enemy_index]
   arena.apply_hit(enemy_index,5,(target.body.position-arena.player.position).normalized(),4)
   enemy_timers[enemy_index]=2.5
  arena.status="PARRY PERFECTO · +1 STAMINA"
  return true
 if arena.has_method("on_player_damage"):return arena.on_player_damage(amount,source,knockback,enemy_index)
 arena.damage+=amount
 arena.feel.impact(arena.player.position+Vector3.UP,false)
 arena.player.velocity=knockback*(1+arena.damage*0.008)+Vector3.UP*4
 arena.status="GOLPE · %d%%" % int(arena.damage)
 return false

func visible_target(origin:Vector3,body:Node3D) -> bool:
 var hit:Dictionary=arena.ray(origin,body.position)
 return hit.is_empty() or hit.get("collider")==body

func tick(dt:float) -> void:
 ember_cd=maxf(0,ember_cd-dt)
 upper_cd=maxf(0,upper_cd-dt)
 parry_cd=maxf(0,parry_cd-dt)
 recovery=maxf(0,recovery-dt)
 parry_pose_left=maxf(0,parry_pose_left-dt)
 if parry_left>0:
  parry_left=maxf(0,parry_left-dt)
  if parry_left<=0:recovery=0.25
 if is_instance_valid(parry_marker):
  parry_marker.position=arena.player.position+Vector3.UP
  parry_marker.rotation.y=arena.model.rotation.y
  if parry_left<=0:parry_marker.queue_free()
 if is_instance_valid(ember):
  ember_life-=dt
  if ember_flying:
   var start:Vector3=ember.global_position
   var target:Vector3=start.move_toward(ember_target,24*dt)
   var hit:Dictionary=arena.ray(start,target)
   if not hit.is_empty():
    target=hit.position+hit.normal*0.35
    ember_target=target
   ember.global_position=target
   ember_flying=target.distance_to(ember_target)>0.01
  if ember_life<=0 and not ember_dash:ember.queue_free()
 if ult_left>0:
  var before:=ult_left
  ult_left=maxf(0,ult_left-dt)
  for i in range(arena.enemies.size()):
   var body:CharacterBody3D=arena.enemies[i].body
   var delta:Vector3=ult_center+Vector3.UP-body.position
   if delta.length()>6 or not visible_target(ult_center+Vector3.UP,body):continue
   if ult_left>0:
    body.velocity+=Vector3(delta.x,0,delta.z).normalized()*dt*14
   elif before>0:
    arena.apply_hit(i,40,Vector3(delta.x,0,delta.z).normalized()*0.2,18)
  if ult_left<=0:
   if is_instance_valid(ult_marker):ult_marker.detonate()
 tick_enemies(dt)

func tick_enemies(dt:float) -> void:
 for i in range(arena.enemies.size()):
  var enemy:Dictionary=arena.enemies[i]
  var distance:float=enemy.body.position.distance_to(arena.player.position+Vector3.UP)
  if not sparring or distance>3.2 or float(enemy.get("stun",0))>0:
   enemy_timers[i]=1.8
   if is_instance_valid(enemy_marks[i]):enemy_marks[i].queue_free()
   continue
  enemy_timers[i]-=dt
  if enemy_timers[i]<0.5 and not is_instance_valid(enemy_marks[i]):enemy_marks[i]=ring(enemy.body.position-Vector3.UP*0.75,1,Color("ff5555"),0)
  if is_instance_valid(enemy_marks[i]):enemy_marks[i].position=enemy.body.position-Vector3.UP*0.75
  if enemy_timers[i]<=0:
   enemy_timers[i]=2.1
   if is_instance_valid(enemy_marks[i]):enemy_marks[i].queue_free()
   if distance<2.8 and visible_target(arena.player.position+Vector3.UP,enemy.body):
    var delta:Vector3=(arena.player.position-enemy.body.position)
    delta.y=0
    receive_hit(10,enemy.body.position,delta.normalized()*8,i)

func drive(dt:float) -> bool:
 if not ember_dash:return false
 if not is_instance_valid(ember):ember_dash=false;return false
 var start:Vector3=arena.player.position
 var target:Vector3=ember.global_position-Vector3.UP
 var collision:KinematicCollision3D=arena.player.move_and_collide((target-start).limit_length(30*dt))
 var end:Vector3=arena.player.position
 var direction:Vector3=(target-start).normalized()
 arena.player.velocity=direction*12
 arena.model.rotation.y=atan2(-direction.x,-direction.z)
 ember_trail_timer-=dt
 if ember_trail_timer<=0:
  ember_trail_timer=0.06
  preload("res://game/pixel_sparks.gd").burst(arena.slash_effects,end+Vector3.UP,Color("ff9738"),5,2)
 for i in range(arena.enemies.size()):
  if ember_hits.has(i):continue
  var point:Vector3=arena.enemies[i].body.position
  if Geometry3D.get_closest_point_to_segment(point,start+Vector3.UP,end+Vector3.UP).distance_to(point)<1.4:
   ember_hits.append(i)
   arena.apply_hit(i,20,direction,6)
 if collision!=null or end.distance_to(target)<0.15:
  ember_dash=false
  arena.slash_effects.burst(end+Vector3.UP)
  ember.queue_free()
 return true

func reset() -> void:
 ember_dash=false
 ember_flying=false
 parry_left=0
 parry_pose_left=0
 recovery=0
 ult_left=0
 if is_instance_valid(ember):ember.queue_free()
 if is_instance_valid(ult_marker):ult_marker.queue_free()
 if is_instance_valid(parry_marker):parry_marker.queue_free()
 for mark in enemy_marks:
  if is_instance_valid(mark):mark.queue_free()
 for i in range(enemy_timers.size()):enemy_timers[i]=1.8


