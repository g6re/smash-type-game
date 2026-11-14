shader_type spatial;
render_mode cull_disabled,diffuse_burley;
uniform sampler2D wall_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 world;
varying vec3 surface_normal;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;surface_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 w=pow(abs(surface_normal),vec3(5.0));w/=max(dot(w,vec3(1.0)),0.001);
 vec3 c=texture(wall_color,world.zy/4.0).rgb*w.x+texture(wall_color,world.xz/4.0).rgb*w.y+texture(wall_color,world.xy/4.0).rgb*w.z;
 ALBEDO=c*vec3(0.86,0.94,0.9);
 ROUGHNESS=0.95;
}
