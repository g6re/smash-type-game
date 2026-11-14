shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float fade=1.0;
uniform vec4 edge_color : source_color = vec4(0.03,0.22,0.65,1.0);
uniform vec4 energy_color : source_color = vec4(0.08,0.8,1.0,1.0);
void fragment() {
 float t=floor(TIME*24.0)/24.0;
 float across=abs(UV.y*2.0-1.0);
 float teeth=sin(UV.x*21.0-t*15.0)*0.09+sin(UV.x*47.0+t*11.0)*0.06;
 float mask=1.0-step(0.96+teeth,across);
 mask*=1.0-step(0.93,sin(UV.x*12.0-t*9.0))*step(0.6,across);
 vec3 color=mix(vec3(1.0,0.96,0.73),energy_color.rgb,step(0.22,across));
 color=mix(color,edge_color.rgb,step(0.73+teeth,across));
 ALBEDO=color;
 EMISSION=color*0.9;
 ALPHA=mask*fade;
}
