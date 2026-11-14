shader_type spatial;
render_mode diffuse_burley,cull_disabled;
uniform vec4 tint : source_color = vec4(0.65,0.6,0.48,1);
varying vec3 world;
varying vec3 local;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;local=VERTEX;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 p=abs(NORMAL.x)>0.5 ? world.zy : world.xy;
 vec2 uv=vec2(p.x+floor(p.y/0.65)*0.7,p.y)/vec2(1.6,0.65);
 vec2 f=fract(uv);
 float seam=1.0-smoothstep(0.012,0.045,min(min(f.x,1.0-f.x)*1.6,min(f.y,1.0-f.y)*0.65));
 float variation=hash(floor(uv));
 vec3 color=tint.rgb*(0.88+variation*0.18);
 color+=0.018*sin(p.x*5.0+p.y*3.0);
 ALBEDO=mix(color,color*0.64,seam*0.7);
 ROUGHNESS=0.9;
}
