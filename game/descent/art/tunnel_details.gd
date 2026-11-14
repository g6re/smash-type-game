extends RefCounted
static func build(art:Node3D) -> void:
 var root:=Node3D.new()
 root.name="TunnelDetails"
 art.add_child(root)
 for side in [-1,1]:
  for x in [-25.8,-12.8,12.8,25.8]:
   # Voussoirs follow a shallow arch above the capsule clearance.
   for i in range(9):
    var angle:float=PI*i/8.0
    var point:=Vector3(x+cos(angle)*1.85,1.9+sin(angle)*0.6,side*15.87)
    var piece:MeshInstance3D=art.block(root,Vector3(0.52,0.32,0.28),point,art.stone)
    piece.rotation.z=atan2(0.6*cos(angle),-1.85*sin(angle))
   for dx in [-1.85,1.85]:
    art.block(root,Vector3(0.28,1.85,0.3),Vector3(x+dx,0.925,side*15.87),art.stone)
   lamp(art,root,Vector3(x,2.32,side*17.8),side)
  # Repeated load-bearing ribs and wall lamps make the route readable inside.
  for x in [-20,-7,7,20]:
   art.block(root,Vector3(0.22,0.15,3.8),Vector3(x,2.5,side*20),art.wood)
   lamp(art,root,Vector3(x,1.8,side*21.78),side)

static func lamp(art:Node3D,parent:Node3D,point:Vector3,side:int) -> void:
 art.block(parent,Vector3(0.3,0.45,0.17),point,art.wood)
 var glow:StandardMaterial3D=art.color_material(Color("ffd58a"))
 glow.emission_enabled=true
 glow.emission=Color("ffb750")
 glow.emission_energy_multiplier=1.5
 art.block(parent,Vector3(0.2,0.3,0.19),point-Vector3(0,0,side*0.08),glow)
 var light:=OmniLight3D.new()
 parent.add_child(light)
 light.position=point-Vector3(0,0,side*0.35)
 light.light_color=Color("ffd398")
 light.light_energy=1.1
 light.omni_range=6.0
