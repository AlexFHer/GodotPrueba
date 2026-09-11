shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
		INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
		INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz), MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float angle = atan(p.y, p.x);
	float radius = 0.7 + 0.07 * sin(angle * 7.0) + 0.04 * cos(angle * 5.0);
	float cloud = 1.0 - smoothstep(radius - 0.2, radius, length(p));
	ALBEDO = mix(vec3(0.48, 0.4, 0.42), vec3(0.78, 0.72, 0.7), clamp(0.5 - p.y * 0.4, 0.0, 1.0));
	ALPHA = cloud * COLOR.a;
}
