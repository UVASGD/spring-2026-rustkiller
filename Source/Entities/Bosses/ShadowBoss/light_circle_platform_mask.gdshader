shader_type canvas_item;

uniform sampler2D platform_mask : filter_nearest, repeat_disable;
uniform vec2 platform_global_position = vec2(0.0);
uniform vec2 platform_scale = vec2(1.0);
uniform float platform_rotation = 0.0;
uniform vec2 platform_texture_size = vec2(1.0);
uniform float alpha_cutoff = 0.05;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 light_color = texture(TEXTURE, UV);

	float cos_rotation = cos(-platform_rotation);
	float sin_rotation = sin(-platform_rotation);
	vec2 relative_position = world_position - platform_global_position;
	vec2 platform_local_position = vec2(
		cos_rotation * relative_position.x - sin_rotation * relative_position.y,
		sin_rotation * relative_position.x + cos_rotation * relative_position.y
	);
	platform_local_position /= max(abs(platform_scale), vec2(0.001));

	vec2 platform_uv = platform_local_position / platform_texture_size + vec2(0.5);
	if (platform_uv.x < 0.0 || platform_uv.x > 1.0 || platform_uv.y < 0.0 || platform_uv.y > 1.0) {
		discard;
	}

	vec4 mask_color = texture(platform_mask, platform_uv);
	if (mask_color.a < alpha_cutoff) {
		discard;
	}

	COLOR = vec4(light_color.rgb, light_color.a * COLOR.a);
}
