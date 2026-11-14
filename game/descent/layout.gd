extends RefCounted
# Rotational symmetry keeps equivalent cover and traversal routes for both teams.
static func build(arena:Node3D) -> void:
 var outline:PackedVector2Array=PackedVector2Array([Vector2(-32,-19),Vector2(-23,-28),Vector2(23,-28),Vector2(32,-19),Vector2(32,19),Vector2(23,28),Vector2(-23,28),Vector2(-32,19)])
 var body:=StaticBody3D.new()
 body.name="OctagonalArena"
 arena.add_child(body)
 var hull:=ConvexPolygonShape3D.new()
 var points:=PackedVector3Array()
 for p in outline:
  points.append(Vector3(p.x,0,p.y))
  points.append(Vector3(p.x,-1,p.y))
 hull.points=points
 var collision:=CollisionShape3D.new()
 collision.shape=hull
 body.add_child(collision)
 var surface:=SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for index in range(outline.size()):
  var a:Vector2=outline[index]
  var b:Vector2=outline[(index+1)%outline.size()]
  var top_a:=Vector3(a.x,0,a.y)
  var top_b:=Vector3(b.x,0,b.y)
  for vertex in [Vector3.ZERO,top_b,top_a,Vector3(0,-1,0),top_a-Vector3.UP,top_b-Vector3.UP,top_a,top_b,top_b-Vector3.UP,top_a,top_b-Vector3.UP,top_a-Vector3.UP]:surface.add_vertex(vertex)
  var length_value:=a.distance_to(b)
  var trim:MeshInstance3D=arena.box(arena,Vector3(length_value,0.07,0.14),Vector3((a.x+b.x)/2,0.04,(a.y+b.y)/2),Color("aa976b"))
  trim.rotation.y=-atan2(b.y-a.y,b.x-a.x)
 surface.generate_normals()
 var floor_mesh:=MeshInstance3D.new()
 floor_mesh.mesh=surface.commit()
 floor_mesh.material_override=arena.material(Color("465960"))
 body.add_child(floor_mesh)
 # The courtyard is the lowest level. Both upper gardens have three approaches.
 for side in [-1,1]:
  # Split the terrace into walls and a structural roof: the void below is real.
  var polygon:=PackedVector2Array([Vector2(-26.3,side*22),Vector2(26.3,side*22),Vector2(23,side*28),Vector2(-23,side*28)])
  if side<0:polygon.reverse()
  solid(arena,"UpperGardenNorth" if side<0 else "UpperGardenSouth",polygon,3.2)
  for interval in [Vector2(-23.8,-14.8),Vector2(-10.8,10.8),Vector2(14.8,23.8)]:
   var width:float=interval.y-interval.x
   tunnel_block(arena,"TunnelFront",Vector3(width,4,2),Vector3((interval.x+interval.y)/2,1.2,side*17))
  tunnel_block(arena,"TunnelRoof",Vector3(52.6,0.6,4),Vector3(0,2.9,side*20),true)
  for x in [-25.8,-12.8,12.8,25.8]:
   tunnel_block(arena,"PortalRoof",Vector3(4,0.6,2),Vector3(x,2.9,side*17),true)
   for i in range(10):
    var dx:float=-1.8+i*0.4
    var underside:float=1.9+0.6*sqrt(maxf(0,1-pow((absf(dx)+0.2)/2.0,2)))
    tunnel_block(arena,"ArchSpandrel",Vector3(0.4,2.6-underside,0.6),Vector3(x+dx,(2.6+underside)/2,side*16.3))
  for x in [-26.5,26.5]:
   tunnel_block(arena,"TunnelEnd",Vector3(0.6,3.2,4),Vector3(x,1.6,side*20))
  for x in [-20,0,20]:
   ramp(arena,"GardenRamp",x-4,x+4,side*8,side*16,3.2)
  # Courtyard wings grow out of the terrace, leaving three readable openings.
  for x in [-10,10]:
   obstacle(arena,Vector3(1.0,2.2,7),Vector3(x,1.1,side*12.5),0,Color("59655a"))
  # Entry galleries frame each team landing, without blocking its corridor.
  var entry_x:float=side*27
  var entry_z:float=-side*12
  for offset in [-6.5,6.5]:
   if offset*side<0:continue # Gallery opens into the outer tunnel entrance.
   obstacle(arena,Vector3(9,2.8,0.8),Vector3(entry_x,1.4,entry_z+offset),0,Color("59655a"))
  # Low cover is anchored to the wings, not scattered in the middle.
  obstacle(arena,Vector3(5,1.0,1.1),Vector3(side*12,0.5,side*8.5),0,Color("59655a"))
  # A continuous back wall and two raised garden pavilions.
  obstacle(arena,Vector3(40,1.0,0.8),Vector3(0,3.7,side*26.5),0,Color("59655a"))
  for x in [-18,18]:
   for dx in [-2.6,2.6]:
    obstacle(arena,Vector3(0.7,3.8,0.7),Vector3(x+dx,5.1,side*23.2),0,Color("59655a"))
 var ring:=MeshInstance3D.new()
 var mesh:=TorusMesh.new()
 mesh.inner_radius=3.8
 mesh.outer_radius=3.9
 ring.mesh=mesh
 ring.scale.y=0.12
 ring.position.y=0.05
 ring.material_override=arena.material(Color("d9b77a"))
 arena.add_child(ring)

static func obstacle(arena:Node3D,size:Vector3,point:Vector3,yaw:float,color:Color) -> void:
 var body:=StaticBody3D.new()
 arena.add_child(body)
 body.position=point
 body.rotation.y=yaw
 arena.box(body,size,Vector3.ZERO,color)
 var collision:=CollisionShape3D.new()
 var shape:=BoxShape3D.new()
 shape.size=size
 collision.shape=shape
 body.add_child(collision)

static func tunnel_block(arena:Node3D,label:String,size:Vector3,point:Vector3,top:bool=false) -> void:
 var body:=StaticBody3D.new()
 body.name=label
 body.set_meta("tunnel",true)
 body.set_meta("roof",top)
 arena.add_child(body)
 body.position=point
 arena.box(body,size,Vector3.ZERO,Color("59655a"))
 var collision:=CollisionShape3D.new()
 var shape:=BoxShape3D.new()
 shape.size=size
 collision.shape=shape
 body.add_child(collision)

static func solid(arena:Node3D,label:String,polygon:PackedVector2Array,top:float) -> void:
 var vertices:=PackedVector3Array()
 for p in polygon:
  vertices.append(Vector3(p.x,-0.8,p.y))
  vertices.append(Vector3(p.x,top,p.y))
 convex(arena,label,vertices,polygon.size())

static func ramp(arena:Node3D,label:String,x0:float,x1:float,z0:float,z1:float,height:float) -> void:
 var vertices:=PackedVector3Array([
  Vector3(x0,-0.8,z0),Vector3(x0,0.015,z0),
  Vector3(x1,-0.8,z0),Vector3(x1,0.015,z0),
  Vector3(x1,-0.8,z1),Vector3(x1,height,z1),
  Vector3(x0,-0.8,z1),Vector3(x0,height,z1)])
 convex(arena,label,vertices,4)

static func convex(arena:Node3D,label:String,vertices:PackedVector3Array,count:int) -> void:
 var body:=StaticBody3D.new()
 body.name=label
 body.set_meta("terrain",true)
 arena.add_child(body)
 var shape:=ConvexPolygonShape3D.new()
 shape.points=vertices
 var collision:=CollisionShape3D.new()
 collision.shape=shape
 body.add_child(collision)
 var tool:=SurfaceTool.new()
 tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(1,count-1):
  var a:=vertices[1]
  var b:=vertices[i*2+1]
  var c:=vertices[(i+1)*2+1]
  for v in ([a,c,b] if (b-a).cross(c-a).y<0 else [a,b,c]):tool.add_vertex(v)
 for i in range(count):
  var j:=(i+1)%count
  for v in [vertices[i*2],vertices[j*2],vertices[j*2+1],vertices[i*2],vertices[j*2+1],vertices[i*2+1]]:tool.add_vertex(v)
 tool.generate_normals()
 var mesh:=MeshInstance3D.new()
 mesh.mesh=tool.commit()
 body.add_child(mesh)


