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
 # Four L-shaped walls leave open approaches to the central objective.
 for side in [-1,1]:
  obstacle(arena,Vector3(8,2.8,0.55),Vector3(side*13,1.4,side*9),0,Color("59717a"))
  obstacle(arena,Vector3(0.55,2.8,4),Vector3(side*17,1.4,side*7),0,Color("59717a"))
  obstacle(arena,Vector3(0.55,2.8,7),Vector3(side*11,1.4,-side*11),0,Color("59717a"))
  obstacle(arena,Vector3(4,2.8,0.55),Vector3(side*12.7,1.4,-side*14.5),0,Color("59717a"))
  obstacle(arena,Vector3(3.2,1.2,1.2),Vector3(side*6,0.6,side*15),PI/4,Color("897661"))
  obstacle(arena,Vector3(4,3.4,4),Vector3(side*24,1.7,-side*18),PI/4,Color("4a5e66"))
  # Side terraces give height without closing off the central fight.
  arena.platform(Vector3(6,0.5,6),Vector3(side*24,2.95,0),Color("796c70"))
  for step in range(2):arena.platform(Vector3(2,1+step,3),Vector3(side*(18+step*2),0.5+step*0.5,0),Color("7a7569"))
  arena.platform(Vector3(5,1.6,4),Vector3(side*16,0.8,-side*20),Color("6b7580"))
  arena.box(arena,Vector3(6.5,0.08,0.04),Vector3(side*13,1.5,side*9-0.3),Color("77d3d1"))
  # Landing routes are connected to the side lifts at x = +/-37.
  for offset in [-4.5,4.5]:
   arena.box(arena,Vector3(12,0.035,0.10),Vector3(side*25,0.04,side*-12+offset),Color("8ba2a8"))
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

