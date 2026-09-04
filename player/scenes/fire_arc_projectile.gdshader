shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 core_color : source_color = vec4(1.0, 0.96, 0.62, 1.0);
uniform vec4 body_color : source_color = vec4(1.0, 0.38, 0.035, 1.0);
uniform vec4 edge_color : source_color = vec4(0.9, 0.025, 0.002, 1.0);
uniform float emission_energy : hint_range(0.0, 8.0, 0.1) = 5.5;
uniform float life_progress : hint_range(0.0, 1.0) = 0.0;
uniform float sweep_direction : hint_range(-1.0, 1.0) = 1.0;

float random_value(vec2 position) {
	return fract(sin(dot(position, vec2(12.9898, 78.233))) * 43758.5453);
}

float value_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 fraction = fract(position);
	fraction = fraction * fraction * (3.0 - 2.0 * fraction);

	float bottom_left = random_value(cell);
	float bottom_right = random_value(cell + vec2(1.0, 0.0));
	float top_left = random_value(cell + vec2(0.0, 1.0));
	float top_right = random_value(cell + vec2(1.0, 1.0));
	return mix(
		mix(bottom_left, bottom_right, fraction.x),
		mix(top_left, top_right, fraction.x),
		fraction.y
	);
}

void fragment() {
	vec2 point = (UV - vec2(0.5)) * 2.0;
	float longitudinal_noise = value_noise(vec2(point.x * 9.0 - TIME * 7.0, TIME * 2.5));
	float fine_noise = value_noise(point * vec2(15.0, 8.0) + vec2(TIME * 8.0, -TIME * 4.0));
	float tip_distance = abs(point.x);
	float taper = pow(max(1.0 - tip_distance, 0.0), 0.42);
	float end_mask = 1.0 - smoothstep(0.82, 1.0, tip_distance);

	float curve_height = 0.16 * (1.0 - point.x * point.x) - 0.06;
	curve_height += (longitudinal_noise - 0.5) * 0.055;
	float distance_to_curve = abs(point.y - curve_height);
	float body_width = 0.065 + 0.23 * taper;
	float flame_width = body_width + 0.12 + fine_noise * 0.11 * taper;

	float aura = 1.0 - smoothstep(flame_width, flame_width + 0.14, distance_to_curve);
	float body = 1.0 - smoothstep(body_width, body_width + 0.065, distance_to_curve);
	float core = 1.0 - smoothstep(
		body_width * 0.26,
		body_width * 0.64,
		distance_to_curve
	);
	float broken_edge = smoothstep(0.12, 0.88, fine_noise + taper * 0.32);
	aura *= mix(0.55, 1.0, broken_edge);

	float leading_heat = 0.5 + 0.5 * point.x * sweep_direction;
	vec3 color = mix(edge_color.rgb, body_color.rgb, body);
	color = mix(color, core_color.rgb, core * mix(0.75, 1.0, leading_heat));

	float fade_in = smoothstep(0.0, 0.055, life_progress);
	float fade_out = 1.0 - smoothstep(0.58, 1.0, life_progress);
	float energy_pulse = 0.92 + sin(TIME * 18.0 + point.x * 8.0) * 0.12;
	float arc_alpha = max(body, aura * 0.58) * end_mask * fade_in * fade_out;

	ALBEDO = color;
	EMISSION = color * emission_energy * energy_pulse;
	ALPHA = arc_alpha;
}
