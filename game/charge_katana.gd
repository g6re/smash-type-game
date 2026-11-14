extends Sprite3D

func _ready() -> void:
	var canvas:=Image.create(24,48,false,Image.FORMAT_RGBA8)
	stroke(canvas,Vector2i(7,36),Vector2i(20,2),Color("281820"),1)
	stroke(canvas,Vector2i(8,33),Vector2i(20,2),Color("b9d9df"),0)
	stroke(canvas,Vector2i(9,33),Vector2i(21,3),Color("fff9df"),0)
	stroke(canvas,Vector2i(5,41),Vector2i(7,36),Color("281820"),1)
	stroke(canvas,Vector2i(5,41),Vector2i(7,36),Color("743c43"),0)
	stroke(canvas,Vector2i(4,34),Vector2i(11,37),Color("281820"),1)
	stroke(canvas,Vector2i(4,34),Vector2i(11,37),Color("d2a34d"),0)
	texture=ImageTexture.create_from_image(canvas)
	pixel_size=0.031
	offset=Vector2(5,12)
	billboard=BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	shaded=false
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func stroke(canvas:Image,start:Vector2i,end:Vector2i,color:Color,radius:int) -> void:
	var steps:=maxi(absi(end.x-start.x),absi(end.y-start.y))
	for step in range(steps+1):
		var point:=Vector2(start).lerp(Vector2(end),float(step)/maxi(1,steps)).round()
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				var px:=int(point.x)+x
				var py:=int(point.y)+y
				if px>=0 and px<24 and py>=0 and py<48:
					canvas.set_pixel(px,py,color)
