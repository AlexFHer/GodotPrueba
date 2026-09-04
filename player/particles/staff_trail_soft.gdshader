shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, particle_trails;

uniform vec4 trail_color : source_color = vec4(0.0, 0.642, 0.643, 0.48);
uniform float emission_energy : hint_range(0.0, 4.0, 0.1) = 0.0;
uniform float side_softness : hint_range(0.01, 0.49, 0.01) = 0.24;
uniform float tip_softness : hint_range(0.01, 0.49, 0.01) = 0.18;

void fragment() {
	float left_fade = smoothstep(0.0, side_softness, UV.x);
	float right_fade = 1.0 - smoothstep(1.0 - side_softness, 1.0, UV.x);
	float start_fade = smoothstep(0.0, tip_softness, UV.y);
	float end_fade = 1.0 - smoothstep(1.0 - tip_softness, 1.0, UV.y);
	float soft_mask = pow(max(left_fade * right_fade * start_fade * end_fade, 0.0), 0.72);

	ALBEDO = trail_color.rgb;
	EMISSION = trail_color.rgb * emission_energy * soft_mask;
	ALPHA = trail_color.a * soft_mask;
}
