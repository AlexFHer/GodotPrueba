shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 water_color : source_color = vec4(0.14, 0.65, 0.9, 1.0);
uniform float ripple_strength : hint_range(0.0, 0.03) = 0.012;
uniform vec4 rim_color : source_color = vec4(0.35, 0.85, 1.0, 1.0);
uniform float rim_energy : hint_range(0.0, 12.0) = 4.5;
uniform float rim_power : hint_range(0.5, 5.0) = 1.8;

void vertex() {
	float ripple = sin(VERTEX.y * 15.0 + TIME * 1.6)
		* sin(VERTEX.x * 12.0 - TIME * 1.2 + VERTEX.z * 8.0);
	VERTEX += NORMAL * ripple * ripple_strength;
}

void fragment() {
	vec3 normal = normalize(NORMAL);
	float fresnel = 1.0 - clamp(dot(normal, normalize(VIEW)), 0.0, 1.0);
	// Broaden the silhouette at distance so it survives shrinking on screen.
	float distance_boost = smoothstep(4.0, 18.0, length(VERTEX));
	float rim = pow(fresnel, max(0.5, rim_power - distance_boost * 0.6));
	// Broad and small highlights remain legible even without an environment map.
	float highlight = pow(max(dot(normal, normalize(vec3(-0.45, 0.65, 0.6))), 0.0), 32.0);
	float glint = pow(max(dot(normal, normalize(vec3(0.5, -0.4, 0.75))), 0.0), 64.0);
	ALBEDO = mix(water_color.rgb, vec3(0.8, 0.96, 1.0), rim * 0.65);
	METALLIC = 0.0;
	ROUGHNESS = 0.08;
	SPECULAR = 0.9;
	EMISSION = rim_color.rgb * rim * rim_energy * (1.0 + distance_boost * 0.35)
		+ vec3(0.8, 0.95, 1.0) * (highlight * 1.6 + glint * 0.8);
	ALPHA = clamp(0.09 + rim * 0.9 + highlight * 0.65 + glint * 0.35, 0.0, 0.98);
}
