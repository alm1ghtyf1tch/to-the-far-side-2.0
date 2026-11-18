shader_type spatial;
render_mode specular_disabled;

uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
// Lossless RG packing preserves all 16 bits of the numeric LOLA elevation.
uniform sampler2D elevation_map : filter_linear_mipmap, repeat_enable;
uniform float relief = 2.2;
varying vec3 sphere_direction;

vec2 lunar_uv(vec3 n) {
	return vec2(0.5 + atan(n.x, n.z) / TAU, 0.5 - asin(clamp(n.y, -1.0, 1.0)) / PI);
}
float height_value(vec2 uv) {
	vec2 rg = textureLod(elevation_map, uv, 0.0).rg;
	return (rg.r * 65280.0 + rg.g * 255.0) / 65535.0;
}
void vertex() {
	sphere_direction = normalize(VERTEX);
	float km = height_value(lunar_uv(sphere_direction)) * 32.7675 - 10.0;
	VERTEX *= 1.0 + km / 1737.4 * relief;
}
void fragment() {
	vec3 n = normalize(sphere_direction);
	vec2 uv = lunar_uv(n);
	vec3 east = normalize(vec3(n.z, 0.0, -n.x));
	vec3 north = cross(n, east);
	float du = 1.0 / 2048.0;
	float dv = 1.0 / 1024.0;
	float slope_e = (height_value(uv + vec2(du, 0)) - height_value(uv - vec2(du, 0)))
		* 32.7675 / 1737.4 * relief / (2.0 * du * TAU * max(length(n.xz), 0.05));
	float slope_n = (height_value(uv - vec2(0, dv)) - height_value(uv + vec2(0, dv)))
		* 32.7675 / 1737.4 * relief / (2.0 * dv * PI);
	vec3 terrain_normal = normalize(n - east * slope_e - north * slope_n);
	NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(terrain_normal, 0.0)).xyz);
	vec3 color = texture(albedo_map, uv).rgb;
	// Restrained warm highlands / slate maria. Geography is entirely real data.
	float value = dot(color, vec3(0.3333));
	ALBEDO = color * mix(vec3(0.68, 0.78, 0.89), vec3(1.08, 1.04, 0.95), smoothstep(0.10, 0.48, value)) * 1.15;
	ROUGHNESS = 0.96;
	float edge = pow(1.0 - max(dot(normalize(VIEW), NORMAL), 0.0), 4.0);
	// Artistic cool edge light, on the surface only. No atmosphere shell.
	EMISSION = vec3(0.028, 0.055, 0.075) * edge;
}
