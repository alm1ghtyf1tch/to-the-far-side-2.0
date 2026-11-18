shader_type canvas_item;
render_mode unshaded;

uniform bool crt_enabled = true;
uniform float curvature : hint_range(0.0, 1.0) = 0.35;
uniform float scanlines : hint_range(0.0, 1.0) = 0.18;
uniform float chromatic_aberration : hint_range(0.0, 1.0) = 0.15;
uniform float glow : hint_range(0.0, 1.0) = 0.12;
uniform vec2 output_size = vec2(1280.0, 720.0);
uniform float visible_fraction = 1.0;
uniform vec2 image_offset = vec2(0.0);

vec2 source_uv(vec2 uv) {
	vec2 p = uv * 2.0 - 1.0;
	p *= 1.0 + curvature * 0.08 * p.yx * p.yx;
	return p * 0.5 + 0.5;
}

void fragment() {
	// Move the image under stable CRT glass. Negative sampling offset moves content
	// in the same direction as the pointer. One pass, one matching CPU input map.
	vec2 glass_uv = crt_enabled ? source_uv(UV) : UV;
	vec2 uv = (glass_uv - 0.5 - image_offset) * visible_fraction + 0.5;
	if (!crt_enabled) {
		COLOR = texture(TEXTURE, uv);
	} else {
		vec2 px = 1.0 / max(output_size, vec2(1.0));
		vec2 edge = abs(UV * 2.0 - 1.0);
		vec2 split = vec2(px.x * chromatic_aberration * dot(edge, edge) * 1.8, 0.0);
		vec3 color = texture(TEXTURE, uv).rgb;
		if (chromatic_aberration > 0.0) {
			color.r = texture(TEXTURE, uv + split).r;
			color.b = texture(TEXTURE, uv - split).b;
		}
		if (glow > 0.0) {
			vec3 halo = texture(TEXTURE, uv + vec2(px.x, 0.0)).rgb;
			halo += texture(TEXTURE, uv - vec2(px.x, 0.0)).rgb;
			halo += texture(TEXTURE, uv + vec2(0.0, px.y)).rgb;
			halo += texture(TEXTURE, uv - vec2(0.0, px.y)).rgb;
			color += max(halo * 0.25 - vec3(0.48), vec3(0.0)) * glow * 0.22;
		}
		// At least two output pixels per scanline: no subpixel moire or time flicker.
		float line = 0.5 + 0.5 * cos(UV.y * output_size.y * 3.14159265);
		color *= 1.0 - line * scanlines * 0.22;
		float vignette = smoothstep(0.35, 1.8, dot(edge, edge));
		color *= 1.0 - vignette * 0.13;
		float grain = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
		color += (grain - 0.5) * 0.003;
		float mask = step(0.0, glass_uv.x) * step(glass_uv.x, 1.0) * step(0.0, glass_uv.y) * step(glass_uv.y, 1.0);
		COLOR = vec4(color * mask, 1.0);
	}
}
