#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 screen_size;
    float aberration_strength; // força do efeito
} params;

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.screen_size);
    vec2 direction_from_center = uv - vec2(0.5);

	// Prevent reading/writing out of bounds.
	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

    // Aberração: deslocamento baseado na distância do centro
    float dist = length(direction_from_center);
    
    vec2 offset = direction_from_center * params.aberration_strength * dist;

    vec4 r_sample = texture(color_image, uv - offset * 0.5);
    vec4 g_sample = texture(color_image, uv);
    vec4 b_sample = texture(color_image, uv + offset * 0.5);

    vec4 color = vec4(r_sample.r, g_sample.g, b_sample.b, 1.0);

	// Write back to our color buffer.
	imageStore(color_image, uv, color);
}