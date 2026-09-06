shader_type particles;
render_mode disable_force, disable_velocity;

uniform float seed_offset = 0.0;

float hash(float value) {
	return fract(sin(value * 127.1 + 311.7) * 43758.5453);
}

void process() {
	float seed = float(INDEX) + 1.0 + seed_offset;
	float phase = hash(seed) * 6.2831853;
	float angle = TIME * mix(0.25, 0.65, hash(seed + 2.0)) + phase;
	float height = (hash(seed + 5.0) - 0.5) * 0.55;
	float orbit = mix(0.08, 0.28, hash(seed + 8.0));
	// Bounded orbits keep every mote inside the half-metre water sphere.
	TRANSFORM = mat4(1.0);
	float size = mix(0.45, 1.2, hash(seed + 12.0));
	size *= 0.85 + sin(TIME * 2.0 + phase) * 0.15;
	TRANSFORM[0].x = size;
	TRANSFORM[1].y = size;
	TRANSFORM[2].z = size;
	TRANSFORM[3].xyz = vec3(cos(angle) * orbit,
		height + sin(angle * 1.7 + phase) * 0.045, sin(angle) * orbit);
	COLOR = mix(vec4(0.25, 0.7, 1.0, 1.0), vec4(0.85, 1.0, 1.0, 1.0), hash(seed + 16.0));
}
