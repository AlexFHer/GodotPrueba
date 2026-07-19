shader_type spatial;
render_mode blend_mix,
	cull_disabled,
	unshaded,
	depth_prepass_alpha,
	shadows_disabled,
	specular_disabled,
	vertex_lighting;

uniform bool affine_mapping = true;
uniform sampler2D albedo : source_color, filter_nearest;
uniform vec4 potion_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float potion_progress : hint_range(0.0, 1.0) = 0.0;
uniform float potion_strength : hint_range(0.0, 1.0) = 0.0;
uniform float effect_bottom_y = -0.8;
uniform float effect_top_y = 1.2;
uniform float effect_edge_size : hint_range(0.001, 0.25) = 0.04;
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.27;
uniform float jitter : hint_range(0.0, 1.0) = 0.513;
uniform ivec2 resolution = ivec2(320, 240);

varying float local_height;

vec4 snap_to_position(vec4 base_position)
{
	vec4 snapped_position = base_position;
	snapped_position.xyz = base_position.xyz / base_position.w;

	vec2 snap_resolution = floor(vec2(resolution) * (1.0 - jitter));
	snapped_position.x = floor(snap_resolution.x * snapped_position.x) / snap_resolution.x;
	snapped_position.y = floor(snap_resolution.y * snapped_position.y) / snap_resolution.y;

	snapped_position.xyz *= base_position.w;
	return snapped_position;
}

void vertex()
{
	local_height = VERTEX.y;

	vec4 snapped_position = snap_to_position(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (affine_mapping)
	{
		POSITION = snapped_position;
		POSITION /= abs(POSITION.w);
	}
	else
	{
		POSITION = snapped_position;
	}
}

void fragment()
{
	vec4 color_base = COLOR;
	vec4 texture_color = texture(albedo, UV);
	vec3 base_albedo = (color_base * texture_color).rgb;

	float height_range = max(effect_top_y - effect_bottom_y, 0.001);
	float normalized_height = clamp((local_height - effect_bottom_y) / height_range, 0.0, 1.0);
	float remaining_mask = 1.0 - smoothstep(potion_progress, potion_progress + effect_edge_size, normalized_height);
	float color_amount = remaining_mask * potion_strength;

	ALBEDO = mix(base_albedo, potion_color.rgb, color_amount);
	ALPHA = texture_color.a * color_base.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
}
