shader_type spatial;
render_mode cull_disabled;

uniform vec4 water_color : source_color = vec4(0.08, 0.65, 0.72, 1.0);
uniform float noise_scale : hint_range(0.5, 12.0) = 3.5;
uniform float flow_speed : hint_range(0.0, 2.0) = 0.18;
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.55;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.12;
uniform float impact_progress : hint_range(0.0, 1.0) = 1.0;

varying vec2 water_position;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 blend = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), blend.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), blend.x), blend.y);
}

void vertex() {
	// Local projection keeps the pattern independent of imported UVs.
	water_position = VERTEX.xz;
}

void fragment() {
	vec2 p = water_position * noise_scale;
	float t = TIME * flow_speed;
	float slow_noise = noise(p + vec2(t, -t * 0.6));
	float fine_noise = noise(p * 1.8 + vec2(-t * 0.7, t));
	float water_noise = slow_noise * 0.65 + fine_noise * 0.35;
	float bands = smoothstep(0.35, 0.42, water_noise);
	float ripple = abs(sin(water_noise * 15.0 + p.x * 0.65 + t));
	float lines = 1.0 - smoothstep(0.04, 0.15, ripple);
	vec3 base = water_color.rgb * mix(0.65, 1.05, bands);
	vec3 highlight = mix(water_color.rgb, vec3(1.0), 0.65);
	vec3 color = mix(base, highlight, lines * highlight_strength);
	float radius = length(water_position);
	float impact_ring = 1.0 - smoothstep(0.025, 0.095, abs(radius - impact_progress * 1.5));
	float trailing_ring = 1.0 - smoothstep(0.02, 0.06, abs(radius - impact_progress * 1.05));
	float impact = max(impact_ring, trailing_ring * 0.6) * (1.0 - impact_progress);
	color = mix(color, highlight, impact * 0.9);
	ALBEDO = color;
	ROUGHNESS = 0.32;
	SPECULAR = 0.55;
	EMISSION = color * glow_strength;
}
