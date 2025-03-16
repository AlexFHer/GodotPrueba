shader_type spatial;

uniform sampler2D albedo_texture;
uniform sampler2D opacity_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 albedo_tex = texture(albedo_texture, UV);
	ALBEDO = albedo_tex.rgb;
	// ALPHA = final_color.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
