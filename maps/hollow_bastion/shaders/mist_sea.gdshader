shader_type spatial;
render_mode unshaded, cull_disabled;
varying vec3 world_position;
void vertex() {
 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
 vec2 p = world_position.xz;
 float wave = sin(p.x * 0.18 + TIME * 0.18 + sin(p.y * 0.12)) * sin(p.y * 0.22 - TIME * 0.12);
 float wisps = pow(0.5 + 0.5 * sin(p.x * 0.1 + p.y * 0.21 + wave * 1.2 + TIME * 0.13), 9.0);
 float distance_fade = smoothstep(15.0, 110.0, length(p));
 vec3 color = mix(vec3(0.065, 0.055, 0.14), vec3(0.23, 0.12, 0.27), wave * 0.5 + 0.5);
 color += vec3(0.12, 0.08, 0.15) * wisps;
 ALBEDO = mix(color * 0.55, vec3(0.12, 0.07, 0.16), distance_fade);
 EMISSION = ALBEDO * 0.15;
}

