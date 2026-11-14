shader_type spatial;
render_mode cull_disabled,diffuse_lambert_wrap;
uniform bool waterfall=false;
varying vec3 world;
void vertex(){
 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 if(!waterfall){VERTEX.y+=sin(world.x*0.65+TIME*1.1)*0.045+cos(world.z*0.8-TIME)*0.035;}
}
void fragment(){
 float t=TIME;
 float edge=min(UV.x,1.0-UV.x);
 float foam=1.0-smoothstep(0.025,0.09,edge);
 float wave=sin(UV.y*5.0-t*2.0+sin(UV.x*18.0))*0.5+0.5;
 float streak=step(0.95,wave)*0.35;
 vec3 deep=vec3(0.025,0.22,0.29);
 vec3 shallow=vec3(0.10,0.47,0.46);
 vec3 water=mix(deep,shallow,smoothstep(0.3,0.0,edge)*0.65+wave*0.15);
 if(waterfall){
  wave=sin(UV.x*36.0+sin(UV.y*12.0+t*3.0))*0.5+0.5;
  streak=step(0.75,wave)*0.5+step(0.94,sin(UV.y*55.0+t*8.0))*0.15;
  water=vec3(0.12,0.48,0.55);
 }
 ALBEDO=mix(water,vec3(0.62,0.86,0.81),clamp(foam*0.8+streak,0.0,0.95));
 ROUGHNESS=0.28;
 METALLIC=0.08;
 EMISSION=water*0.1;
}
