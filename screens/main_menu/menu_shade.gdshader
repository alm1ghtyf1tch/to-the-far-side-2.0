shader_type canvas_item;
render_mode unshaded;

void fragment() {
	float left = 1.0 - smoothstep(0.18, 0.7, UV.x);
	float ends = pow(abs(UV.y * 2.0 - 1.0), 3.0);
	COLOR = vec4(vec3(0.018, 0.038, 0.07), left * 0.58 + ends * 0.12);
}
