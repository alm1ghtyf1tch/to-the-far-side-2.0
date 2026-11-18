shader_type spatial;
render_mode specular_disabled;
uniform sampler2D continents : source_color, filter_nearest, repeat_enable;
varying vec3 direction;
void vertex() { direction = normalize(VERTEX); }
void fragment() {
	vec3 n = normalize(direction);
	vec2 uv = vec2(0.5 + atan(n.x, n.z) / TAU, 0.5 - asin(n.y) / PI);
	ALBEDO = texture(continents, uv).rgb * 0.68;
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0);
	EMISSION = vec3(0.018, 0.08, 0.14) * rim;
}
