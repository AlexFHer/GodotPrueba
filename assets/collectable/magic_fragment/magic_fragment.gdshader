shader_type spatial;

uniform sampler2D noise_texture;
uniform float smoothness : hint_range(0.0, 1.0, 0.05) = 0.5;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	float height = texture(
		noise_texture,
		VERTEX.xz + vec2(TIME * 0.1)
	).r;

	VERTEX += NORMAL * height;
}

void fragment() {
	vec3 view_direction = normalize(CAMERA_POSITION_WORLD - world_position);

	vec3 normal_world = normalize(
		MODEL_NORMAL_MATRIX * NORMAL
	);

	float fresnel = dot(view_direction, normal_world);
	fresnel = clamp(abs(fresnel), 0.0, 1.0);

	fresnel = pow(fresnel, smoothness * 10.0 + 0.1);

	ALBEDO = vec3(1.0 - fresnel);
}
