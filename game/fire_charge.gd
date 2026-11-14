extends Node3D
var arena:Node3D
var arcs:Array[MeshInstance3D]=[]
var time:=0.0
func _ready() -> void:
 for i in range(3):
  var arc:=MeshInstance3D.new()
  var mesh:=ImmediateMesh.new()
  mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
  for step in range(54):
   var a:float=float(step)/54*TAU*0.82
   var b:float=float(step+1)/54*TAU*0.82
   var r0:=Vector3(cos(a),0,sin(a))
   var r1:=Vector3(cos(b),0,sin(b))
   var verts:=[r0*0.84,r0*1.05,r1*0.84,r1*0.84,r0*1.05,r1*1.05]
   var uvs:=[Vector2(a,0),Vector2(a,1),Vector2(b,0),Vector2(b,0),Vector2(a,1),Vector2(b,1)]
   for v in range(6):
    mesh.surface_set_uv(uvs[v])
    mesh.surface_add_vertex(verts[v])
  mesh.surface_end()
  arc.mesh=mesh
  arc.material_override=arena.slash_effects.fire_material()
  arc.rotation=Vector3(i*0.85,0,i*0.65)
  add_child(arc)
  arcs.append(arc)
 hide()
func _process(dt:float) -> void:
 visible=arena.charging and arena.selected_character=="samurai"
 if not visible:return
 time+=dt
 position=arena.player.position+Vector3.UP*0.95
 var amount:float=arena.charge_time/arena.CHARGE_SECONDS
 scale=Vector3.ONE*(0.45+amount*0.65)
 for i in range(arcs.size()):
  arcs[i].rotation.y=time*(3.5+i)+i*2.1
  arcs[i].rotation.z=sin(time*1.8+i)*0.7+i*0.6
