shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 star_color : source_color = vec4(0.65, 0.9, 1.0, 1.0);
uniform float energy : hint_range(0.0, 16.0) = 7.0;

void vertex() {
	// Face the camera while retaining each particle's position and size.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
		INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
		INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz),
		MODEL_MATRIX[3]);
}

void fragment() {
	vec2 point = (UV - vec2(0.5)) * 2.0;
	float angle = atan(point.x, -point.y) + TIME * 0.3;
	float sector = abs(mod(angle + 0.62831853, 1.25663706) - 0.62831853);
	// Intersection with the straight edge from an outer tip to an inner notch.
	float boundary = 0.169282 / (0.211603 * cos(sector) + 0.508754 * sin(sector));
	float distance_from_center = length(point);
	float star = 1.0 - smoothstep(boundary - 0.025, boundary + 0.025, distance_from_center);
	float halo = exp(-distance_from_center * distance_from_center * 7.0) * 0.3;
	float core = 1.0 - smoothstep(0.0, 0.25, distance_from_center);
	float pulse = 0.8 + sin(TIME * 3.0 + COLOR.r * 15.0) * 0.2;
	ALBEDO = star_color.rgb;
	EMISSION = mix(star_color.rgb, vec3(1.0), core) * energy * pulse;
	ALPHA = clamp(star + halo, 0.0, 1.0);
}
