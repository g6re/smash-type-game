extends "res://game/arena.gd"
func _ready() -> void:
 super._ready()
 set_physics_process(false)
 abilities.sparring=false
 player.position=Vector3(0,4,6)
 player.collision_mask=0
 player.velocity=Vector3.ZERO
 await get_tree().physics_frame
 player.move_and_slide()
 stamina=0
 jumps=1
 jump()
 assert(stamina==0 and jumps==2 and player.velocity.y==10,"Double jump is free at zero stamina")
 player.velocity.y=-2
 jump()
 assert(player.velocity.y==-2,"No third air jump")
 model.rotation.y=0
 assert(abilities.parry())
 assert(abilities.receive_hit(10,player.position+Vector3(0,1,-2),Vector3.BACK*8))
 assert(damage==0 and stamina==1,"Frontal parry blocks damage and restores stamina")
 abilities.reset()
 abilities.parry_cd=0
 assert(abilities.parry())
 assert(not abilities.receive_hit(10,player.position+Vector3(0,1,2),Vector3.FORWARD*8))
 assert(damage==10,"Parry cannot block from behind")
 abilities.reset()
 abilities.parry_cd=0
 assert(abilities.parry())
 abilities.tick(0.23)
 assert(abilities.recovery>0 and not abilities.uppercut(),"Missed parry has recovery")
 abilities.reset()
 enemies[0].body.position=player.position+Vector3(0,1,-2)
 enemies[0].damage=0
 enemies[0].body.collision_mask=0
 assert(abilities.uppercut())
 assert(enemies[0].damage==18 and enemies[0].body.velocity.y>10 and jumps==2)
 assert(not abilities.uppercut(),"Uppercut cooldown")
 assert(not abilities.ultimate(),"Ultimate requires full charge")
 ultimate_charge=100
 assert(abilities.ultimate())
 assert(ultimate_charge==0)
 abilities.tick(1.2)
 assert(enemies[0].damage==58 and enemies[0].body.velocity.y>=18,"Ultimate detonates inside marked circle")
 abilities.reset()
 camera.global_position=player.position+Vector3.UP
 camera.rotation=Vector3.ZERO
 assert(abilities.cast_ember())
 for i in range(60):abilities.tick(1.0/60)
 assert(not abilities.ember_flying and is_instance_valid(abilities.ember))
 var start:=player.position
 assert(abilities.cast_ember() and abilities.ember_dash)
 for i in range(40):
  if abilities.ember_dash:abilities.drive(1.0/60)
 assert(player.position.distance_to(start)>10 and not abilities.ember_dash)
 abilities.reset()
 await get_tree().process_frame
 assert(not is_instance_valid(abilities.ember))
 # Practice enemy swing uses the same damage/parry entry point.
 player.position=Vector3(0,4,6)
 model.rotation.y=0
 enemies[0].body.position=player.position+Vector3(0,1,-2)
 abilities.sparring=true
 abilities.enemy_timers[0]=0.1
 enemies[0]["stun"]=0.0
 abilities.parry_cd=0
 assert(abilities.parry())
 var previous:=damage
 abilities.tick_enemies(0.11)
 assert(damage==previous and abilities.parry_left==0,"Training attack can be parried")
 print("PASS: free double jump, no third jump, frontal parry, recovery, ember travel, uppercut, ultimate and training hits")
 get_tree().quit()
