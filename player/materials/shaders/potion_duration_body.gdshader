shader_type spatial;
render_mode cull_disabled,
	diffuse_burley,
	specular_schlick_ggx;

uniform sampler2D albedo : source_color, filter_linear_mipmap;
uniform sampler2D potion_mask : filter_nearest, repeat_disable;
uniform vec4 potion_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float potion_progress : hint_range(0.0, 1.0) = 0.0;
uniform float potion_strength : hint_range(0.0, 1.0) = 0.0;
uniform float effect_edge_size : hint_range(0.001, 0.25) = 0.04;

varying float rest_height;

void vertex()
{
	rest_height = clamp(UV2.x, 0.0, 1.0);
}

void fragment()
{
	vec4 color_base = COLOR;
	vec4 texture_color = texture(albedo, UV);
	vec3 base_albedo = (color_base * texture_color).rgb;

	float remaining_mask = 1.0 - smoothstep(potion_progress, potion_progress + effect_edge_size, rest_height);
	float selected_area = texture(potion_mask, UV).r;
	float color_amount = remaining_mask * potion_strength * selected_area;

	ALBEDO = mix(base_albedo, potion_color.rgb, color_amount);
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
	SPECULAR = 0.5;
}
