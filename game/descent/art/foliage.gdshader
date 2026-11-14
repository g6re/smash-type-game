shader_type spatial;
render_mode diffuse_lambert_wrap;
uniform vec4 tint : source_color = vec4(0.7,0.15,0.08,1);
varying vec3 local;
void vertex(){local=VERTEX; VERTEX.x+=sin(TIME*1.3+MODEL_MATRIX[3].x*0.7+MODEL_MATRIX[3].z)*0.045*max(VERTEX.y,0.0);}
void fragment(){
 float brush=sin(local.x*4.0+sin(local.z*3.0))*sin(local.y*5.0-local.z*2.0);
 ALBEDO=tint.rgb*(0.9+floor((brush+1.0)*2.0)*0.045);
 ROUGHNESS=1.0;
}
