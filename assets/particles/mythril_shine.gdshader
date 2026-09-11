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
	vec2 p = (UV - 0.5) * 2.0;
	p = mat2(vec2(cos(spin), -sin(spin)), vec2(sin(spin), cos(spin))) * p;
	// Concave four-point silhouette with long, tapered rays.
	vec2 q = abs(p);
	float shape = pow(q.x, 0.55) + pow(q.y, 0.55);
	float edge = max(fwidth(shape), 0.015);
	float star = 1.0 - smoothstep(0.96 - edge, 0.96 + edge, shape);
	float halo = exp(-dot(p, p) * 18.0) * 0.12;
	float core = exp(-dot(p, p) * 35.0);
	vec3 tint = mix(vec3(0.68, 0.88, 1.0), vec3(1.0, 0.98, 0.87), core);
	ALBEDO = tint * COLOR.rgb;
	EMISSION = tint * 0.35;
	ALPHA = max(star, halo) * COLOR.a;
}
