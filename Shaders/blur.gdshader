shader_type canvas_item;

uniform float blur_amount = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 texel_size = SCREEN_PIXEL_SIZE;
	vec4 sum = vec4(0.0);

	sum += texture(SCREEN_TEXTURE, uv + texel_size * vec2(-1.0, -1.0)) * 0.0625;
	sum += texture(SCREEN_TEXTURE, uv + texel_size * vec2( 0.0, -1.0)) * 0.125;
	sum += texture(SCREEN_TEXTURE, uv + texel_size * vec2( 1.0, -1.0)) * 0.0625;
	sum += texture(SCREEN_TEXTURE, uv + texel_size * vec2(-1.0, 0.0)) * 0.125;
	sum += texture(SCREEN_TEXTURE, uv + texel_size * vec2( 0.0, 0.0)) * 0.25;
	sum += texture(SCREEN_TEXTURE, uv + texel_size * vec2( 1.0, 0.0)) * 0.125;
	sum += texture(SCREEN_TEXTURE, uv + texel_size * vec2(-1.0, 1.0)) * 0.0625;
	sum += texture(SCREEN_TEXTURE, uv + texel_size * vec2( 0.0, 1.0)) * 0.125;
	sum += texture(SCREEN_TEXTURE, uv + texel_size * vec2( 1.0, 1.0)) * 0.0625;

	COLOR = mix(texture(SCREEN_TEXTURE, uv), sum, blur_amount);
}