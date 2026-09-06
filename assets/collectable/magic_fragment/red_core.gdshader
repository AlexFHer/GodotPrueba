shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 glow_color : source_color = vec4(1.0, 0.025, 0.045, 1.0);
uniform float energy : hint_range(0.0, 16.0) = 6.0;
uniform float morph_speed : hint_range(0.1, 3.0) = 1.0;

float merge_mass(float first, float second, float softness) {
	float blend = clamp(0.5 + 0.5 * (second - first) / softness, 0.0, 1.0);
	return mix(second, first, blend) - softness * blend * (1.0 - blend);
}

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
		INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
		INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz),
		MODEL_MATRIX[3]);
}

void fragment() {
	vec2 point = (UV - vec2(0.5)) * 2.0;
	float radius = length(point);
	float time = TIME * morph_speed;
	float angle = atan(point.y, point.x);
	float pulse = 0.92 + sin(TIME * 2.5) * 0.08;
	// Overlapping lobes merge into one connected mass around a fixed core.
	float mass = radius - 0.27;
	for (int index = 0; index < 5; index++) {
		float seed = float(index);
		float direction = seed * 1.256637 + sin(time * 0.73 + seed * 2.1) * 0.7;
		float reach = 0.18 + 0.11 * sin(time * 1.17 + seed * 1.9);
		vec2 center = vec2(cos(direction), sin(direction)) * reach;
		float size = 0.2 + 0.055 * sin(time * 1.43 + seed * 2.7);
		mass = merge_mass(mass, length(point - center) - size, 0.14);
	}
	float warped_angle = angle + sin(angle * 3.0 + time * 0.8) * 0.25;
	float spikes = pow(max(cos(warped_angle * 7.0 - time * 0.6), 0.0), 8.0);
	float growth = 0.5 + 0.5 * sin(angle * 4.0 + time * 1.8);
	mass -= spikes * growth * 0.15 * smoothstep(0.2, 0.45, radius);
	float shape = 1.0 - smoothstep(-0.015, 0.025, mass);
	float halo = exp(-max(mass, 0.0) * 12.0) * (1.0 - smoothstep(0.75, 0.98, radius));
	float core = 1.0 - smoothstep(0.0, 0.42, radius);
	ALBEDO = glow_color.rgb;
	EMISSION = mix(glow_color.rgb, vec3(1.0, 0.22, 0.12), core * 0.5) * energy * pulse;
	ALPHA = clamp(shape * 0.95 + halo * 0.4, 0.0, 1.0);
}
