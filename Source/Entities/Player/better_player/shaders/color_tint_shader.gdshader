shader_type canvas_item;
uniform vec4 color: source_color = vec4(1.0,1.0,1.0,1.0);
uniform float tint_factor: hint_range(0.0, 1.0) = 0.0;
uniform float fade: hint_range(0.0,1.0) = 0.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 main_texture = texture(TEXTURE, UV);
	vec4 final_output = main_texture;
	final_output.rgb = mix(main_texture.rgb, color.rgb, tint_factor);
	final_output.a = clamp(main_texture.a + fade, 0.0, 1.0);
	COLOR = final_output;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
