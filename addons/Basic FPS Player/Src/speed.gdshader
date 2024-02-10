//shader_type canvas_item;
//
//uniform vec2 center = vec2(0.5, 0.5);
//uniform sampler2D noise;
//uniform float sample_radius: hint_range(0.0, 1.0) = 0.5;
//uniform vec4 line_color: source_color = vec4(1.0);
//uniform float center_radius: hint_range(0.0, 1.0) = 0.5;
//
//const float pi = 3.14159265359;
shader_type canvas_item;

uniform sampler2D smoke;
uniform float speed = 0.3;
uniform float size = 0.08;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment(){
	
	vec2 smoke_uv = UV + TIME * speed;
	vec4 smoke_color = texture(smoke, fract(smoke_uv));
	smoke_color = clamp(smoke_color * size, 0.0, 1.0);
	
	vec4 img_color = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(smoke_color.g - size/2.0,0.0));
	
	COLOR = vec4(img_color);
}

//
//void fragment() {
	//vec2 dist = UV - center;
	//float angle = atan(dist.y / dist.x);
	//vec2 sample = vec2(sample_radius * cos(angle), sample_radius * sin(angle));
	//float noise_value = texture(noise, sample).r;
	//vec4 color = mix(line_color, vec4(0.0), noise_value);
	//color = mix(color, vec4(0.0), 1.0 - length(dist) - (center_radius * 2.0));
	//COLOR = color;
//}