shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 blended = mix(tex.rgb, flash_color.rgb, flash_strength);
	COLOR = vec4(blended, tex.a);
}
