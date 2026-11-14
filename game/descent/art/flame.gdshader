shader_type spatial;
render_mode unshaded,cull_disabled;
void vertex(){
 float rise=max(0.0,VERTEX.y+0.5);
 VERTEX.x+=sin(TIME*5.0+VERTEX.y*4.0)*0.075*rise;
 VERTEX.z+=cos(TIME*4.0+VERTEX.y*6.0)*0.06*rise;
}
void fragment(){
 vec3 color=mix(vec3(1.0,0.25,0.025),vec3(1.0,0.84,0.3),step(0.35,UV.y));
 ALBEDO=color;
 EMISSION=color*1.4;
}
