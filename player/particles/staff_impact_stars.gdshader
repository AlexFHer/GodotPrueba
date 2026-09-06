shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

varying float spin;

void vertex() {
	spin = INSTANCE_CUSTOM.x;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
		INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
		INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz),
		MODEL_MATRIX[3]);
}

void fragment() {
	vec2 point = (UV - vec2(0.5)) * 2.0;
	float angle = atan(point.x, -point.y) + spin;
	float sector = abs(mod(angle + 0.62831853, 1.25663706) - 0.62831853);
	float boundary = 0.169282 / (0.211603 * cos(sector) + 0.508754 * sin(sector));
	float star = 1.0 - smoothstep(boundary - 0.035, boundary + 0.035, length(point));
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * 1.8;
	ALPHA = star * COLOR.a;
}
