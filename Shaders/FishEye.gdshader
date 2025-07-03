shader_type canvas_item;

// Controles do efeito (ajuste no Inspector ou via script)
uniform float intensity : hint_range(-1.0, 1.0) = 0.3;  // Força da distorção
uniform float zoom : hint_range(0.5, 2.0) = 1.0;       // Zoom central
uniform float glitch_amount : hint_range(0.0, 0.5) = 0.02; // Glitch nas bordas
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Coordenadas centralizadas
    vec2 uv = (SCREEN_UV - 0.5) * zoom;
    float distance = length(uv);
    
    // Fórmula do Fish Eye (simplificada e otimizada)
    uv *= 1.0 + intensity * distance * distance;
    uv = (uv + 0.5); // Volta para o espaço [0,1]
    
    // Corrige distorção excessiva nas bordas
    uv = clamp(uv, 0.001, 0.999);
    
    // Efeito de glitch nas bordas
    if (distance > 0.7) {
        uv.x += sin(TIME * 30.0) * glitch_amount;
    }
    
    // Cor final
    COLOR = texture(SCREEN_TEXTURE, uv);
}