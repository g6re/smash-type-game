shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() {
 vec3 color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
 vec2 center = SCREEN_UV - 0.5;
 float vignette = smoothstep(0.18, 0.66, length(center * vec2(0.88, 1.0)));
 color *= 1.0 - vignette * 0.19;
 COLOR = vec4(color, 1.0);
}
