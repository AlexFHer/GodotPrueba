shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 line_color : source_color = vec4(0.25, 0.65, 1.0, 1.0);
uniform float amplitude : hint_range(0.0, 0.4) = 0.27;
uniform float erraticity : hint_range(0.0, 1.0) = 0.85;
uniform float jitter_speed : hint_range(0.0, 40.0) = 22.0;
uniform float thickness : hint_range(0.01, 0.2) = 0.045;
uniform float emission_energy : hint_range(0.0, 8.0) = 3.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float effect_time = 0.0;
uniform float seed = 0.0;
uniform bool reverse_direction = false;
uniform float surface_offset : hint_range(0.0, 0.05) = 0.008;

void vertex() {
	VERTEX += NORMAL * surface_offset;
}

float random_point(float point) {
	return fract(sin(point * 127.1 + seed * 311.7) * 43758.5453);
}

float bolt_noise(float position, float tick) {
	float fraction = fract(position);
	// Smooth bends at zero; straight segments with sharp corners at one.
	float weight = mix(smoothstep(0.0, 1.0, fraction), fraction, erraticity);
	return mix(random_point(floor(position) + tick),
		random_point(floor(position) + 1.0 + tick), weight) * 2.0 - 1.0;
}

void fragment() {
	float along = reverse_direction ? 1.0 - UV.x : UV.x;
	float tick = floor(effect_time * jitter_speed);
	float segment = along * mix(8.0, 24.0, erraticity);
	float detail = erraticity * 0.45;
	float bend = (bolt_noise(segment, tick * 19.0)
		+ detail * bolt_noise(segment * 2.7, tick * 31.0 + 73.0)) / (1.0 + detail);
	float center = 0.5 + bend * amplitude;
	float distance_to_bolt = abs(UV.y - center);
	float antialias = max(fwidth(distance_to_bolt), 0.003);
	float core = 1.0 - smoothstep(thickness, thickness + antialias, distance_to_bolt);
	float glow = 1.0 - smoothstep(thickness, thickness + 0.16, distance_to_bolt);
	// A short illuminated section travels from the ribbon's start to its end.
	float head = mix(-0.08, 1.55, progress);
	float front = 1.0 - smoothstep(head - 0.04, head, along);
	float tail = smoothstep(head - 0.55, head - 0.25, along);
	float ends = smoothstep(0.0, 0.025, along) * smoothstep(0.0, 0.025, 1.0 - along);
	float flicker = 0.75 + 0.25 * sin(effect_time * 65.0 + seed);
	ALBEDO = mix(line_color.rgb, vec3(0.85, 0.96, 1.0), core) * emission_energy;
	ALPHA = clamp(core + glow * 0.3, 0.0, 1.0) * front * tail * ends * flicker * line_color.a;
}
