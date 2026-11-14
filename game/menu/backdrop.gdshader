shader_type canvas_item;
void fragment(){
 float darkness=mix(0.97,0.12,smoothstep(0.22,0.9,UV.x));
 float grain=sin(UV.y*1100.0)*0.008;
 COLOR=vec4(vec3(0.025,0.03,0.065)+grain,darkness);
}
