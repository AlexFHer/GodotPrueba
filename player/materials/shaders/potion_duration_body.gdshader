shader_type spatial;
render_mode cull_disabled,
	diffuse_burley,
	specular_schlick_ggx;

uniform sampler2D albedo : source_color, filter_linear_mipmap;
uniform sampler2D potion_mask : filter_nearest, repeat_disable;
uniform vec4 potion_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool combined_potion = false;
uniform float effect_time = 0.0;
uniform float lava_scale : hint_range(2.0, 20.0) = 9.0;
uniform float lava_speed : hint_range(0.0, 2.0) = 0.3;
uniform float potion_progress : hint_range(0.0, 1.0) = 0.0;
uniform float potion_strength : hint_range(0.0, 1.0) = 0.0;
uniform float effect_edge_size : hint_range(0.001, 0.25) = 0.04;

varying float rest_height;

void vertex()
{
	rest_height = clamp(UV2.x, 0.0, 1.0);
}

float lava_mask(vec2 uv)
{
	vec2 position = uv * lava_scale + vec2(0.0, effect_time * lava_speed);
	vec2 cell = floor(position);
	float field = 0.0;
	// Nearby round blobs merge where their soft fields overlap.
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 id = cell + vec2(float(x), float(y));
			float seed = fract(sin(dot(id, vec2(127.1, 311.7))) * 43758.5453);
			float phase = seed * 6.283185;
			vec2 center = id + 0.5 + 0.24 * vec2(
				sin(effect_time * 0.55 + phase),
				cos(effect_time * 0.4 + phase * 1.7));
			vec2 offset = position - center;
			float radius = mix(0.23, 0.4, seed);
			field += exp(-dot(offset, offset) / (radius * radius));
		}
	}
	return smoothstep(0.48, 0.58, field);
}

void fragment()
{
	vec4 color_base = COLOR;
	vec4 texture_color = texture(albedo, UV);
	vec3 base_albedo = (color_base * texture_color).rgb;

	float remaining_mask = 1.0 - smoothstep(potion_progress, potion_progress + effect_edge_size, rest_height);
	float selected_area = texture(potion_mask, UV).r;
	float color_amount = remaining_mask * potion_strength * selected_area;

	vec3 effect_color = potion_color.rgb;
	if (combined_potion) {
		effect_color = mix(effect_color, secondary_color.rgb, lava_mask(UV));
	}
	ALBEDO = mix(base_albedo, effect_color, color_amount);
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
	SPECULAR = 0.5;
}
