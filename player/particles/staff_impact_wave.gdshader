shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
		INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
		INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz),
		MODEL_MATRIX[3]);
}

void fragment() {
	float radius = length((UV - vec2(0.5)) * 2.0);
	float front = mix(0.08, 0.9, 1.0 - pow(1.0 - progress, 2.0));
	float ring = 1.0 - smoothstep(0.018, 0.08, abs(radius - front));
	float flash = (1.0 - smoothstep(0.0, 0.22, radius)) * pow(1.0 - progress, 6.0);
	ALBEDO = vec3(0.65, 0.85, 1.0);
	EMISSION = vec3(0.45, 0.75, 1.0) * 3.5;
	ALPHA = max(ring, flash) * sqrt(max(1.0 - progress, 0.0));
}
