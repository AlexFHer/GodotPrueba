shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform float radius = 0.0;
uniform float extent = 11.0;
uniform float wave_width = 1.0;
uniform float age = 0.0;
uniform float fade = 1.0;
uniform vec4 electric_color : source_color = vec4(0.12, 0.5, 1.0, 1.0);

// Quantized angular waves give the discharge sharp, flickering bends.
float jagged(float angle, float frequency, float seed) {
	return abs(fract(angle * frequency / 6.2831853 + seed) * 2.0 - 1.0) * 2.0 - 1.0;
}

void fragment() {
	vec2 point = (UV - vec2(0.5)) * extent * 2.0;
	float distance_from_center = length(point);
	float angle = atan(point.y, point.x);
	float tick = floor(age * 18.0);
	float bend = jagged(angle, 37.0, tick * 0.137) * 0.15
		+ jagged(angle, 71.0, tick * 0.231) * 0.06;
	float front = distance_from_center - radius;
	float bolt_distance = abs(front - bend * wave_width);
	float core = 1.0 - smoothstep(0.018, 0.055, bolt_distance);
	float halo = 1.0 - smoothstep(0.02, wave_width * 0.42, bolt_distance);
	float branch_offset = jagged(angle, 19.0, tick * 0.097) * wave_width * 0.36;
	float branch = 1.0 - smoothstep(0.015, 0.045, abs(front - bend - branch_offset));
	branch *= smoothstep(0.15, 0.65, sin(angle * 13.0 + tick * 2.0));
	float visibility = fade * smoothstep(0.0, 0.25, radius);
	ALBEDO = electric_color.rgb;
	EMISSION = (electric_color.rgb * (halo * 2.6 + branch * 3.5)
		+ vec3(0.8, 0.94, 1.0) * core * 4.0) * visibility;
	ALPHA = clamp(halo * 0.5 + core + branch * 0.7, 0.0, 1.0) * visibility;
}
