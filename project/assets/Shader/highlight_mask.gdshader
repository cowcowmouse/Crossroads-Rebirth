shader_type canvas_item;

uniform vec2 highlight_center = vec2(0.5, 0.5);
uniform float highlight_radius = 0.1;
uniform float smoothness = 0.02;
uniform float outside_alpha = 0.7;  // 圈外透明度 (0.0-1.0)，越小越透明
uniform vec3 outside_color = vec3(0.3, 0.3, 0.3);  // 圈外颜色（灰色）

void fragment() {
    vec2 uv = UV;

    // 计算到高亮中心的距离
    float dist = distance(uv, highlight_center);

    // 获取原始颜色
    vec4 color = texture(TEXTURE, uv);

    // 圈内：完全透明
    if (dist < highlight_radius - smoothness) {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);  // 完全透明，露出下面的按钮
    }
    // 边缘：平滑过渡
    else if (dist < highlight_radius + smoothness) {
        float t = (dist - (highlight_radius - smoothness)) / (smoothness * 2.0);
        float alpha = mix(0.0, outside_alpha, t);
        COLOR = vec4(outside_color, alpha);
    }
    // 圈外：半透明灰色
    else {
        COLOR = vec4(outside_color, outside_alpha);
    }
}