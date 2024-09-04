shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 ScaleMult = vec2(1.0);

uniform float AuraProgres : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float Tilling :hint_range(0.0, 60.0, 0.01) = 26.0;
uniform vec2 MovementDirSpeed = vec2(-0.6, 1.0);
uniform vec2 MovementDirSpeed2 = vec2(0.6, 1.0);
uniform sampler2D color_gradiant :repeat_enable, filter_linear_mipmap;
uniform vec2 Noise_Seed = vec2(1.0);

uniform float StarSize :hint_range(0.0, 1.0, 0.01) = 0.05;
uniform vec3 StarColor : source_color = vec3(1.0, 1.0, 0.5); // Light yellow

uniform sampler2D vertical_gradient; // used to set alpha values. So you can use this to make the effect dis-/re-appear at points
uniform sampler2D color_gradient; // sets the effect color, supports 2d gradients
uniform float size_effect: hint_range(-5.0, 5.0, 0.05) = 0.1; // size of the effect
uniform float speed = 1; // effect speed; Will reverse effect is set to negative
uniform float highlight_strength: hint_range(-4.0, 4.0, 0.05) = 0.5; // how strong the color overides the base color
uniform bool color_mode_toggle = false; // changes how the color gradient is applied. Default is on the entire texture, if set to true it is only applied to the effect
uniform bool is_horizontal = false; //changes direction from vertical to horizontal


vec2 random(vec2 uv){
	uv += Noise_Seed;
	uv = vec2( dot(uv, vec2(127.1,311.7) ),
		dot(uv, vec2(269.5,183.3) ) );
	return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
	}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);
    vec2 blur = smoothstep(0.0, 1.0, uv_fract);
    float bottom_left = dot(random(uv_index + vec2(0.0, 0.0)), uv_fract - vec2(0.0, 0.0));
    float bottom_right = dot(random(uv_index + vec2(1.0, 0.0)), uv_fract - vec2(1.0, 0.0));
    float top_left = dot(random(uv_index + vec2(0.0, 1.0)), uv_fract - vec2(0.0, 1.0));
    float top_right = dot(random(uv_index + vec2(1.0, 1.0)), uv_fract - vec2(1.0, 1.0));
    float bottom_mix = mix(bottom_left, bottom_right, blur.x);
    float top_mix = mix(top_left, top_right, blur.x);
    float final_value = mix(bottom_mix, top_mix, blur.y);
    // Ajustamos para que el resultado esté en el rango de 0.0 a 1.0
    return (final_value + 1.0) * 0.5;
}
vec4 AuraEffect(vec2 uv, vec4 CurrentColor, sampler2D OriginTexTure){
	vec2 TimeUV = MovementDirSpeed * TIME;//direction
	vec2 TimeUV2 = MovementDirSpeed2 * TIME;//direction
	vec2 ScaleMultFractment = (1.0 - ScaleMult)/2.0;//Scale the outline
	vec2 compos_uv = uv * ScaleMult + ScaleMultFractment; //Scale the outline
	//I don't know about shaders but I got this, this was the key.----> noise(uv * Tilling + TimeUV) * 8.0
	vec4 alpha = textureLod(OriginTexTure, compos_uv, noise(uv * Tilling + TimeUV) * 8.0);
	vec4 GradientColors = texture(color_gradiant, fract( vec2(-uv.y, uv.x) + (TimeUV * 0.4)) ) * 3.0;
	vec4 sil = GradientColors * noise(uv * Tilling - TimeUV);
	sil.a = alpha.a * noise(uv * Tilling + TimeUV) * noise(uv * Tilling + TimeUV2) * 5.0;
	//return sil;
	return mix(CurrentColor, sil * AuraProgres,  (1.0 - CurrentColor.a));
}

vec3 StarColorHighLightEffect(vec4 old_color, vec2 uv){
		// set up base parameters
	float time = TIME * speed;
	float current_time = fract(-time);
	// sets time to fit better with the effect. (Barely detectable change)
	current_time = mix(0. - size_effect, 1. + size_effect, current_time);
	float effect_lower_bound = current_time - size_effect;
	float effect_upper_bound = current_time + size_effect;
	float position_value = (is_horizontal) ? uv.x : uv.y;
	// smoothes out the lower/upper bounds with the UV values to calculate how far from the middle point(the effect) the pixel is away
	float effect_distance = smoothstep(effect_lower_bound, current_time, position_value) - smoothstep(current_time, effect_upper_bound, position_value);
	// gets the position of the pixel within the effect for the inner_gradient color mode
	float inner_effect_position = smoothstep(effect_lower_bound, effect_upper_bound, position_value);
	vec2 color_position = (color_mode_toggle) ? vec2(uv.x, inner_effect_position) : vec2(current_time);
	// gets the new color from the gradient
	vec4 new_color = vec4(texture(color_gradient, color_position));
	// this step calculates the vertical gradient and alpha_values
	new_color = mix(old_color, new_color, vec4(texture(vertical_gradient, vec2(current_time))));
	// apply the color to the texture
	return mix(old_color.rgb, new_color.rgb, vec3(effect_distance * highlight_strength));
}

void fragment() {
    // Start with the original color and apply the yellow tint
    vec4 base_color = vec4(COLOR.rgb * StarColor, COLOR.a);

	base_color = vec4(StarColorHighLightEffect(base_color, UV), COLOR.a);

    // Apply the aura effect
    vec4 aura_color = AuraEffect(UV, base_color, TEXTURE);


    COLOR = aura_color;
}
