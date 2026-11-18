shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec3 color = mix(vec3(0.025, 0.055, 0.095), vec3(0.012, 0.025, 0.052), UV.y);
	vec2 grid = abs(fract(UV * vec2(64.0, 36.0)) - 0.5);
	float line = smoothstep(0.49, 0.499, max(grid.x, grid.y));
	color += vec3(0.025, 0.045, 0.065) * line * 0.5;
	vec2 cell = floor(UV * vec2(110.0, 64.0));
	float seed = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	float dot_shape = smoothstep(0.06, 0.0, length(fract(UV * vec2(110.0, 64.0)) - 0.5));
	color += vec3(0.18, 0.25, 0.34) * dot_shape * step(0.98, seed);
	COLOR = vec4(color, 1.0);
}
