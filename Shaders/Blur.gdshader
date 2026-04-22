shader_type canvas_item;


uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;

uniform vec4 mix_color : source_color = vec4(0.0, 0.0, 0.0, 0.1);

void fragment() {

    vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_amount);
    
    COLOR = mix(blurred, mix_color, mix_color.a);
}