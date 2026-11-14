extends Control
var stamina := 3.0
var ultimate := 0.0
var charge := 0.0
var charging := false
var cooldown := 0.0
var skill_name:="CORTE"
var boost_window:=0.0
var grind_fire:=0.0
var unlimited_stamina:=false
var ember_cd:=0.0
var upper_cd:=0.0
var parry_cd:=0.0
var parry_active:=false
var ember_ready:=false
var samurai:=true
var damage:=0.0
var health_mode:=false
var health:=100.0
var max_health:=100.0
var combo_hits:=0
var combo_finisher:=false
var energy_mode:=false
var shield:=0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _draw() -> void:
	var font:=ThemeDB.fallback_font
	var bottom:=size.y-64
	if health_mode:
		draw_rect(Rect2(20,bottom-95,286,127),Color(0.025,0.04,0.065,0.96))
	draw_string(font,Vector2(32,bottom-62),"VIDA %d / %d" % [ceili(health),int(max_health)] if health_mode else "DAÑO %d%%" % int(damage),HORIZONTAL_ALIGNMENT_LEFT,-1,22 if health_mode else 16,Color.WHITE if health_mode else Color("ffb68b"))
	if health_mode:
		draw_rect(Rect2(32,bottom-49,260,20),Color("28232f"))
		draw_rect(Rect2(32,bottom-49,260*clampf(health/maxf(1,max_health),0,1),20),Color("f27867"))
		draw_rect(Rect2(32,bottom-49,260,20),Color("f8c7bb"),false,1)
	draw_string(font,Vector2(32,bottom-16),"STAMINA ∞" if unlimited_stamina else "STAMINA",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("dde6ef"))
	for i in range(3):
		var r:=Rect2(32+i*60,bottom,52,13)
		draw_rect(r,Color("18222d"))
		draw_rect(Rect2(r.position,Vector2(r.size.x*clampf(stamina-i,0,1),r.size.y)),Color("55d8c4"))
		draw_rect(r,Color("96e9da"),false,1)
	var x:=size.x/2-168
	for i in range(3):
		var r:=Rect2(x+i*72,size.y-75,60,48)
		draw_rect(r,Color(0.05,0.08,0.12,0.9))
		draw_rect(r,Color("eead70") if i==0 else Color("47505d"),false,1)
		draw_string(font,r.position+Vector2(8,20),["Q","E","F"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,18)
		var cd:float=[cooldown,ember_cd,upper_cd][i]
		var caption:String=[skill_name,"VOLVER" if ember_ready else "ASCUA","FILO"][i]
		if not samurai and i>0:caption="—"
		draw_string(font,r.position+Vector2(6,39),"%.1fs" % cd if cd>0 and not (i==1 and ember_ready) else caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12)
	draw_string(font,Vector2(x+228,size.y-52),("X · ULT LISTA" if ultimate>=100 else "X · REQUIERE 100") if energy_mode else "X · ULT %d%%" % int(ultimate),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("e4b776"))
	draw_string(font,Vector2(x+228,size.y-30),"V · PARRY " + ("ACTIVO" if parry_active else ("%.1fs" % parry_cd if parry_cd>0 else "LISTO")),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("97dfe8"))
	var center:=size/2
	if energy_mode:
		var origin:=Vector2(size.x/2-168,size.y-112)
		draw_rect(Rect2(origin,Vector2(360,28)),Color(0.025,0.04,0.065,0.95))
		for segment in range(4):
			var cell:=Rect2(origin+Vector2(4+segment*88,4),Vector2(84,7))
			draw_rect(cell,Color("253749"))
			draw_rect(Rect2(cell.position,Vector2(84*clampf((ultimate-segment*25)/25,0,1),7)),Color("77dcff"))
		draw_string(font,origin+Vector2(4,25),"ENERGÍA %d · T:25  G:50  X:100" % int(ultimate),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
		if shield>0:draw_string(font,Vector2(32,bottom-102),"ESCUDO +%d" % ceili(shield),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("77dcff"))
	if combo_hits>0:
		draw_rect(Rect2(center+Vector2(72,-16),Vector2(170,54)),Color(0.025,0.04,0.065,0.9))
		draw_string(font,center+Vector2(82,6),("1 GOLPE" if combo_hits==1 else "%d GOLPES" % combo_hits),HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("ffd085"))
		draw_string(font,center+Vector2(82,27),"REMATE" if combo_finisher else "¡IMPACTO!",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
	var gap:=6.0+charge*3 if charging else 4.0
	for axis in [Vector2.RIGHT,Vector2.DOWN]:
		for sign in [-1,1]:
			var start:Vector2=center+axis*gap*sign
			var end:Vector2=center+axis*(gap+7)*sign
			draw_line(start,end,Color(0,0,0,0.8),4,true)
			draw_line(start,end,Color.WHITE,2,true)
	draw_circle(center,1.5,Color("fff0cf"))
	if boost_window>0 and not charging:
		draw_string(font,center+Vector2(-43,48),"IMPULSO",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ffc777"))
		draw_rect(Rect2(center+Vector2(-45,56),Vector2(90*clampf(boost_window/0.4,0,1),3)),Color("ffb854"))
	if grind_fire>0:
		draw_string(font,Vector2(32,bottom-36),"FUEGO %d%%" % int(grind_fire*100),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ffb854"))
	if charging:
		draw_rect(Rect2(center+Vector2(-60,34),Vector2(120,6)),Color("1b2735"))
		draw_rect(Rect2(center+Vector2(-60,34),Vector2(120*charge,6)),Color("f5bb6d"))
		draw_string(font,center+Vector2(-60,62),"CARGA %d%%" % int(charge*100),HORIZONTAL_ALIGNMENT_LEFT,-1,14)
