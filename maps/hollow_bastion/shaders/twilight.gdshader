shader_type sky;

void sky() {
 float h = clamp(EYEDIR.y * 0.85 + 0.16, 0.0, 1.0);
 vec3 horizon = vec3(0.38, 0.22, 0.38);
 vec3 zenith = vec3(0.045, 0.055, 0.15);
 vec3 color = mix(horizon, zenith, smoothstep(0.0, 0.75, h));
 vec3 sun_dir = normalize(vec3(-0.6, 0.24, -0.72));
 float alignment = max(dot(EYEDIR, sun_dir), 0.0);
 color += vec3(0.85, 0.38, 0.12) * pow(alignment, 22.0) * 0.5;
 color += vec3(1.0, 0.78, 0.4) * smoothstep(0.9993, 0.9997, alignment) * 1.8;
 float haze = sin(EYEDIR.x * 15.0 + EYEDIR.z * 9.0) * sin(EYEDIR.z * 23.0 - EYEDIR.y * 20.0);
 color += vec3(0.1, 0.065, 0.13) * haze * exp(-abs(EYEDIR.y - 0.04) * 9.0);
 COLOR = color;
}
