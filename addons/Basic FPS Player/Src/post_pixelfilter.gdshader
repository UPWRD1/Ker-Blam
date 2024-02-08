shader_type canvas_item;

uniform float pixel = 1.0;
uniform sampler2D pallete;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

const float bit = 6.0;
const mat4 bayer = mat4(
	vec4(1.0,  9.0,  3.0, 11.0),
    vec4(13.0,  5.0, 15.0,  7.0),
    vec4(4.0, 12.0,  2.0, 10.0),
    vec4(16.0,  8.0, 14.0,  6.0));

float getbayer(int x, int y) {
	if (x == 0) {
		if (y == 0) return bayer[0][0];
		if (y == 1) return bayer[0][1];
		if (y == 2) return bayer[0][2];
		if (y == 3) return bayer[0][3];
	}
	else if (x == 1) {
		if (y == 0) return bayer[1][0];
		if (y == 1) return bayer[1][1];
		if (y == 2) return bayer[1][2];
		if (y == 3) return bayer[1][3];
	}
	else if (x == 2) {
		if (y == 0) return bayer[2][0];
		if (y == 1) return bayer[2][1];
		if (y == 2) return bayer[2][2];
		if (y == 3) return bayer[2][3];
	}
	else if (x == 3) {
		if (y == 0) return bayer[3][0];
		if (y == 1) return bayer[3][1];
		if (y == 2) return bayer[3][2];
		if (y == 3) return bayer[3][3];
	}
}


void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec4 _color = texture(SCREEN_TEXTURE, floor(FRAGCOORD.xy / pixel) / floor((1.0 / SCREEN_PIXEL_SIZE) / pixel));
	vec4 color = _color * texture(pallete, vec2(_color.r, 1.0));
	
	
	float b = getbayer(int(FRAGCOORD.x) % 4, int(FRAGCOORD.y) % 4);// * 1.0) / 1.0;
	vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;
	vec4 col_noise = color;
	vec3 noise = vec3(fract(sin(dot(FRAGCOORD.xy / SCREEN_PIXEL_SIZE, vec2(12.9898, 78.233))) * 43758.5453));
	noise *= 0.1;
	noise.xy *= (b / 16.0) * 1.5;
	col_noise.rgb += noise; //noise effect
	
	vec4 post = col_noise * floor(col_noise * 4.0) / 4.0; //noise + post-effect
	
	
	
	COLOR *= post;
	
	
}