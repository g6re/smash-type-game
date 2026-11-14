extends Control
var arena:Node3D
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(_dt:float) -> void:queue_redraw()
func _draw() -> void:
 if not is_instance_valid(arena.camera):return
 var font:=ThemeDB.fallback_font
 for actor in arena.actors.values():
  if actor.id==arena.local_id or not actor.alive:continue
  var point:Vector3=actor.body.global_position+Vector3.UP*2.35
  if arena.camera.is_position_behind(point):continue
  var cover:Dictionary=arena.ray(arena.camera.global_position,point)
  if not cover.is_empty() and cover.collider is StaticBody3D:continue
  var screen:Vector2=arena.camera.unproject_position(point)
  if not Rect2(Vector2.ZERO,size).has_point(screen):continue
  var color:=Color("66caff") if actor.team==0 else Color("ff8879")
  var bar:=Rect2(screen-Vector2(54,0),Vector2(108,12))
  if arena.stock_mode:
   draw_style_box(background(),Rect2(bar.position-Vector2(8,24),Vector2(150,64)))
   draw_string(font,bar.position+Vector2(0,-7),actor.name,HORIZONTAL_ALIGNMENT_LEFT,140,14,color)
   draw_string(font,bar.position+Vector2(0,12),"%d%% · %d vidas" % [int(actor.get("percent",0)),actor.get("stocks",3)],HORIZONTAL_ALIGNMENT_LEFT,140,17,Color.WHITE)
   for life in range(3):draw_rect(Rect2(bar.position+Vector2(life*32,21),Vector2(26,6)),color if life<int(actor.get("stocks",3)) else Color("302c37"))
   if float(actor.get("protection",0))>0:draw_string(font,bar.position+Vector2(0,38),"PROTEGIDO",HORIZONTAL_ALIGNMENT_LEFT,140,11,Color("fff0b4"))
   continue
  draw_style_box(background(),Rect2(bar.position-Vector2(8,24),Vector2(124,57)))
  draw_rect(bar,Color("302c37"))
  draw_rect(Rect2(bar.position,Vector2(bar.size.x*clampf(actor.hp/actor.maxhp,0,1),bar.size.y)),color)
  draw_rect(bar,Color("dde7f2"),false,1)
  var caption:String="OBJETIVO" if actor.bot and arena.phase=="preparation" else actor.name
  draw_string(font,bar.position+Vector2(0,-7),caption,HORIZONTAL_ALIGNMENT_LEFT,108,14,Color.WHITE)
  draw_string(font,bar.position+Vector2(0,27),"%d / %d" % [ceili(actor.hp),int(actor.maxhp)],HORIZONTAL_ALIGNMENT_LEFT,108,14,Color.WHITE)
func background() -> StyleBoxFlat:
 var style:=StyleBoxFlat.new()
 style.bg_color=Color(0.025,0.04,0.065,0.94)
 style.set_corner_radius_all(4)
 return style
