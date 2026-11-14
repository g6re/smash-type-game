shader_type spatial;
render_mode cull_disabled,diffuse_burley;
uniform sampler2D stone_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D wall_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 world;
varying vec3 surface_normal;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;surface_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec2 p=world.xz;
 float irregular=sin(p.x*0.43+sin(p.y*0.21)*2.0)*0.8+sin(p.y*0.7+p.x*0.3)*0.45;
 float edge=max(abs(p.x)*0.86,abs(p.y));
 float garden=smoothstep(21.0,25.5,edge+irregular);
 float grove=1.0-smoothstep(3.0,8.0,length(p-vec2(-24.0,-24.0))+irregular);
 garden=max(garden,grove);
 vec3 stone=texture(stone_color,p/7.0).rgb*vec3(1.04,1.08,1.03);
 vec3 grass=texture(grass_color,p/5.0).rgb;
 grass=mix(vec3(dot(grass,vec3(0.2126,0.7152,0.0722))),grass,0.5)*vec3(0.57,0.66,0.58);
 float radius=length(p);
 float ring=1.0-smoothstep(0.03,0.075,abs(radius-4.25));
 vec3 color=mix(stone,grass,garden);
 ALBEDO=mix(color,vec3(0.48,0.32,0.12),ring*0.85);
 if(abs(surface_normal.y)<0.5){
  vec3 weights=abs(surface_normal);weights/=max(weights.x+weights.z,0.001);
  ALBEDO=(texture(wall_color,world.zy/4.0).rgb*weights.x+texture(wall_color,world.xy/4.0).rgb*weights.z)*0.8;
 }
 ROUGHNESS=0.95;
}
