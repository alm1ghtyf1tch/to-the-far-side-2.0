shader_type canvas_item;

uniform sampler2D surface : repeat_enable, filter_linear_mipmap_anisotropic;
uniform float rise = 1.0;
uniform float exposure = 1.0;

const float ASPECT = 1.7778;
const float ALTITUDE = 0.12;
const float CAMERA_LAT = 0.045;
const float PITCH = 0.54;
const float ROLL = -0.09;
const float LENS = 0.45;
const float LON_SPAN = 0.5235988;
const float LAT_MIN = -0.0174533;
const float LAT_MAX = 0.6632251;
const float FLOW = 0.0055;
const float STAR_TURN = 0.0009;
const float EARTH_SIZE = 0.058;
const vec2 EARTH_FROM = vec2(0.30, -0.02);
const vec2 EARTH_TO = vec2(0.345, 0.20);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float hash31(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash31(i), hash31(i + vec3(1.0, 0.0, 0.0)), f.x), mix(hash31(i + vec3(0.0, 1.0, 0.0)), hash31(i + vec3(1.0, 1.0, 0.0)), f.x), f.y);
	float b = mix(mix(hash31(i + vec3(0.0, 0.0, 1.0)), hash31(i + vec3(1.0, 0.0, 1.0)), f.x), mix(hash31(i + vec3(0.0, 1.0, 1.0)), hash31(i + vec3(1.0, 1.0, 1.0)), f.x), f.y);
	return mix(a, b, f.z);
}

float fbm3(vec3 p) {
	float amount = 0.5;
	float sum = 0.0;
	for (int i = 0; i < 4; i++) {
		sum += amount * noise3(p);
		p = p * 2.03 + 11.7;
		amount *= 0.5;
	}
	return sum;
}

vec3 star_layer(vec3 dir, float cells, float share, float size, float shift) {
	float lat = asin(clamp(dir.y, -1.0, 1.0));
	vec2 grid = vec2(atan(dir.z, dir.x), lat) * cells + shift;
	vec2 id = floor(grid);
	float pick = hash21(id);
	if (pick > share) {
		return vec3(0.0);
	}
	vec2 spot = vec2(hash21(id + 17.1), hash21(id + 71.7)) * 0.7 + 0.15;
	vec2 away = fract(grid) - spot;
	away.x *= cos(lat);
	float dist = length(away) / cells;
	float bright = 0.3 + 0.7 * hash21(id + 3.3);
	bright *= bright;
	float flicker = 0.93 + 0.07 * sin(TIME * (0.8 + 2.4 * hash21(id + 9.1)) + pick * 90.0);
	float warm = hash21(id + 5.7);
	vec3 tint = mix(vec3(0.78, 0.86, 1.0), vec3(1.0, 0.93, 0.82), warm);
	return tint * bright * flicker * smoothstep(size, 0.0, dist);
}

vec3 earth_colour(vec2 at, float r2) {
	float z = sqrt(max(1.0 - r2, 0.0));
	vec3 n = vec3(at.x, at.y, z);
	vec3 sun = normalize(vec3(0.78, 0.22, 0.42));
	float light = dot(n, sun);
	float day = smoothstep(-0.1, 0.22, light);
	float tilt = 0.41;
	vec3 m = vec3(n.x * cos(tilt) - n.y * sin(tilt), n.x * sin(tilt) + n.y * cos(tilt), n.z);
	float spin = TIME * 0.012 + 1.3;
	m = vec3(m.x * cos(spin) + m.z * sin(spin), m.y, -m.x * sin(spin) + m.z * cos(spin));
	float land = fbm3(m * vec3(1.9, 2.3, 1.9) + 4.0);
	float cloud = fbm3(m * vec3(3.2, 6.5, 3.2) + vec3(TIME * 0.006, 9.0, 2.0));
	vec3 sea = mix(vec3(0.03, 0.12, 0.36), vec3(0.06, 0.27, 0.58), z);
	vec3 soil = mix(vec3(0.13, 0.33, 0.15), vec3(0.50, 0.42, 0.26), smoothstep(0.56, 0.68, land));
	vec3 face = mix(sea, soil, smoothstep(0.50, 0.54, land));
	face = mix(face, vec3(0.93, 0.95, 0.97), smoothstep(0.80, 0.93, abs(m.y)));
	face = mix(face, vec3(0.96), smoothstep(0.47, 0.70, cloud) * 0.92);
	float edge = pow(1.0 - z, 2.2);
	vec3 lit = face * (0.12 + 1.0 * max(light, 0.0)) + vec3(0.30, 0.55, 1.0) * edge * 0.75;
	return lit * day + vec3(0.0, 0.012, 0.035) * (1.0 - day);
}

void fragment() {
	vec2 screen = vec2((UV.x - 0.5) * ASPECT, 0.5 - UV.y);
	vec2 p = screen * 2.0 * LENS;
	p = vec2(p.x * cos(ROLL) - p.y * sin(ROLL), p.x * sin(ROLL) + p.y * cos(ROLL));
	vec3 up = vec3(0.0, sin(CAMERA_LAT), cos(CAMERA_LAT));
	vec3 eye = up * (1.0 + ALTITUDE);
	vec3 fwd = normalize(vec3(-1.0, 0.0, 0.0) * cos(PITCH) - up * sin(PITCH));
	vec3 right = normalize(cross(fwd, up));
	vec3 top = cross(right, fwd);
	vec3 ray = normalize(fwd + right * p.x + top * p.y);

	float turn = TIME * STAR_TURN;
	vec3 far = vec3(ray.x * cos(turn) + ray.z * sin(turn), ray.y, -ray.x * sin(turn) + ray.z * cos(turn));
	vec3 sky = star_layer(far, 72.0, 0.11, 0.0012, 0.0) * 0.75;
	sky += star_layer(far, 31.0, 0.10, 0.0019, 40.0) * 1.15;
	sky += star_layer(far, 13.0, 0.08, 0.0026, 80.0) * 1.3;

	vec2 centre = mix(EARTH_FROM, EARTH_TO, rise);
	vec2 at = (screen - centre) / EARTH_SIZE;
	float r2 = dot(at, at);
	float halo = exp(-max(sqrt(r2) - 1.0, 0.0) * 7.0);
	sky += vec3(0.22, 0.42, 0.95) * halo * 0.30;
	if (r2 < 1.0) {
		float rim = smoothstep(1.0, 0.96, r2);
		sky = mix(sky, earth_colour(at, r2), rim);
	}

	float b = dot(eye, ray);
	float c = dot(eye, eye) - 1.0;
	float disc = b * b - c;
	vec3 colour = sky;
	if (b < 0.0 && disc > 0.0) {
		vec3 n = eye + ray * (-b - sqrt(disc));
		float lat = asin(clamp(n.y, -1.0, 1.0));
		float lon = atan(n.x, n.z);
		float u = lon / LON_SPAN - mod(TIME * FLOW, LON_SPAN) / LON_SPAN;
		float span = LAT_MAX - LAT_MIN;
		float v_day = clamp(1.0 - (lat - LAT_MIN) / span, 0.002, 0.998);
		float v_night = clamp(1.0 - (0.05 - lat * 0.55 - LAT_MIN) / span, 0.002, 0.998);
		float day = texture(surface, vec2(u, v_day)).r * smoothstep(-0.03, 0.005, lat);
		float night = texture(surface, vec2(u + 0.37, v_night)).r;
		vec3 ground = vec3(1.0, 0.985, 0.955) * day * exposure;
		ground += vec3(0.42, 0.60, 1.0) * night * 0.075 * smoothstep(0.02, -0.06, lat);
		float cover = smoothstep(0.0, fwidth(disc) * 1.5, disc);
		colour = mix(sky, ground, cover);
	}

	float shade = mix(1.0, 0.62, smoothstep(0.84, 1.0, UV.y));
	shade *= mix(0.85, 1.0, smoothstep(0.0, 0.30, UV.x));
	COLOR = vec4(colour * shade, 1.0);
}
