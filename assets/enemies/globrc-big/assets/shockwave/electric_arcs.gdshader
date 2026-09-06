shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform float radius = 0.0;
uniform float age = 0.0;
uniform float fade = 1.0;
uniform float phase = 0.0;

float zigzag(float value) {
	return abs(fract(value) * 2.0 - 1.0) * 2.0 - 1.0;
}

void vertex() {
	vec2 direction = normalize(VERTEX.xz);
	float angle = atan(direction.y, direction.x);
	float tick = floor(age * 16.0);
	float bend = zigzag(angle * 31.0 / 6.2831853 + tick * 0.173 + phase);
	float offset = length(VERTEX.xz) - 1.0;
	VERTEX.xz = direction * (max(radius, 0.05) + offset + bend * 0.18);
	// Actual raised geometry keeps the lightning readable from low cameras.
	float arch = pow(abs(sin(angle * 7.0 + phase * 4.0)), 3.0);
	VERTEX.y += (0.12 + arch * 0.52 + bend * 0.07) * smoothstep(0.0, 0.7, radius);
}

void fragment() {
	float pulse = 0.8 + sin(age * 35.0 + phase * 8.0) * 0.2;
	ALBEDO = vec3(0.45, 0.8, 1.0);
	EMISSION = vec3(0.4, 0.75, 1.0) * 4.0 * pulse;
	ALPHA = fade * smoothstep(0.0, 0.3, radius);
}
