shader_type canvas_item;

uniform float width = 640.0;
uniform vec4 shade : source_color = vec4(0.58, 0.60, 0.65, 1.0);
uniform vec4 light : source_color = vec4(0.97, 0.97, 0.95, 1.0);

varying float along;

void vertex() {
	along = VERTEX.x / width;
}

void fragment() {
	COLOR.rgb *= mix(shade.rgb, light.rgb, smoothstep(0.0, 1.0, along));
}
