shader_type canvas_item;

// 把这里的 max 改大到 20.0，方便你在编辑器里调更粗
uniform float line_thickness : hint_range(0, 20) = 0.0; 
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
    float outline = 0.0;
    
    // 增加到 16 个方向采样，确保线条够粗且圆润
    for (float i = -1.0; i <= 1.0; i += 0.5) {
        for (float j = -1.0; j <= 1.0; j += 0.5) {
            if (i == 0.0 && j == 0.0) continue;
            outline += texture(TEXTURE, UV + vec2(i, j) * size).a;
        }
    }
    
    outline = clamp(outline, 0.0, 1.0);
    vec4 color = texture(TEXTURE, UV);
    
    // 混合颜色，5.0 依然是为了触发 Glow 辉光
    COLOR = mix(vec4(line_color.rgb * 5.0, outline), color, color.a);
}