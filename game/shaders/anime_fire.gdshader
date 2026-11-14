shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float fade = 1.0;
uniform float heat = 1.0;
void fragment() {
 float clock = floor(TIME * 18.0) / 18.0;
 float tooth = sin(UV.x * 18.0 - clock * 13.0) * 0.12 + sin(UV.x * 37.0 - clock * 21.0) * 0.07;
 float across = abs(UV.y * 2.0 - 1.0);
 float contour = 0.91 + tooth;
 float mask = 1.0 - step(contour, across);
 float cut = sin(UV.x * 9.0 - clock * 11.0 + UV.y * 7.0);
 mask *= 1.0 - step(0.87, cut) * step(0.53, across);
 vec3 red = vec3(0.8, 0.025, 0.008);
 vec3 orange = vec3(1.0, 0.23, 0.012);
 vec3 yellow = vec3(1.0, 0.78, 0.13);
 vec3 color = mix(yellow, orange, step(0.32 + tooth * 0.6, across));
 color = mix(color, red, step(0.72 + tooth, across));
 ALBEDO = color;
 EMISSION = color * (0.35 + heat * 0.25);
 ALPHA = mask * fade;
}
