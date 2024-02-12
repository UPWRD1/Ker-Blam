
/*
	放射状ブラーエフェクト by あるる（きのもと　結衣） @arlez80
	Radial Blur Effect by Yui Kinomoto

	MIT License
*/
shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
// 発射中央部
uniform vec2 blur_center = vec2( 0.5, 0.5 );
// ブラー強度
uniform float blur_power : hint_range( 0.0, 1.0 ) = 0.01;
// サンプリング回数
uniform int sampling_count : hint_range( 1, 64 ) = 6;
uniform float alpha = 1;

void fragment( )
{
	vec2 direction = SCREEN_UV - blur_center;
	vec3 c = vec3( 0.0, 0.0, 0.0 );
	float f = 1.0 / float( sampling_count );
	for( int i=0; i < sampling_count; i++ ) {
		c += texture( SCREEN_TEXTURE, SCREEN_UV - blur_power * direction * float(i) ).rgb * f;
	}
	COLOR.rgb = c;
	COLOR.a = alpha;
}


//shader_type canvas_item;
//
//uniform float alpha : hint_range(0.0, 1.0);
//uniform float inner_radius : hint_range(0.0, 1.0);
//uniform float outer_radius : hint_range(0.0, 1.0);
//
//uniform sampler2D smoke;
//uniform float speed : hint_range(0.0, 1.0);
//uniform float size : hint_range(0.0, 1.0);
//uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
//
//
//void fragment() {
    //// Calculate the distance from the center to the current UV coordinate
    //float distance_from_center = distance(UV, vec2(0.5, 0.5));
//
    //// Calculate the percentage of how far the current pixel is from the center
    //float q = clamp((distance_from_center - inner_radius) / (outer_radius - inner_radius), 0.0, 1.0);
	//
	//vec2 smoke_uv = UV * TIME - speed;
	//vec4 smoke_color = texture(smoke, fract(smoke_uv));
	//smoke_color = clamp(smoke_color * size, 0.0, 1.0);
	//vec4 img_color = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(smoke_color.g - size / 2.0, 0.0));
	//
	//// Apply the distortion effect with the modified q value
	//COLOR = vec4(img_color.rgb, img_color.a * q * alpha);
//}
//
////shader_type canvas_item;
////
////uniform float alpha = 1.0;
////uniform float inner_radius = 0.0;
////uniform float outer_radius = 1.0;
////
////uniform sampler2D smoke;
////uniform float speed = 0.3;
////uniform float size = 0.08;
////uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
////
////
////void fragment() {
	////float x = abs(UV.r-.5)*2.0;
	////float y = abs(UV.g-.5)*2.0;
	////float q = 1.0-(1.0-sqrt(x*x+y*y)/outer_radius)/(1.0-inner_radius);
	////
	////vec2 smoke_uv = UV * TIME - speed;
	////vec4 smoke_color = texture(smoke, fract(smoke_uv));
	////smoke_color = clamp(smoke_color * size, 0.0, 1.0);
	////vec4 img_color = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(smoke_color.g - size/2.0,0.0));
	////
	//////COLOR = vec4(img_color, q*alpha);
	////COLOR = vec4(img_color.r, img_color.g, img_color.b, img_color.a * q * alpha);
////}