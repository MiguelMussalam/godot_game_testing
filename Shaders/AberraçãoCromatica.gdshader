shader_type canvas_item;

uniform sampler2D distance_curve;
uniform float aberration_strength : hint_range(0.0, 1.0) = 0.05;

uniform sampler2D screen_texture : source_color, hint_screen_texture;

void fragment() {
	vec2 direction_from_center = SCREEN_UV - vec2(0.5);

	float distance_to_center = distance(vec2(0.5), SCREEN_UV);
	float curve_distance_intensity = texture(distance_curve, vec2(distance_to_center)).r;

	vec2 offset = direction_from_center * aberration_strength * curve_distance_intensity;

	float red = texture(screen_texture, SCREEN_UV - (offset / 2.0)).r;
	float green = texture(screen_texture, SCREEN_UV).g;
	float blue = texture(screen_texture, SCREEN_UV - offset).b;

	COLOR = vec4(red, green, blue, 1.0);
}
