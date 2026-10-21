#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float effectStyle;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec2 uv = qt_TexCoord0;
    float p = clamp(progress, 0.0, 1.0);
    float mask = 1.0 - p;
    if (effectStyle > 0.5 && effectStyle < 2.5) {
        float edge = uv.x * 0.78 + uv.y * 0.22;
        if (effectStyle > 1.5) edge += 0.035 * sin(uv.y * 22.0 + p * 12.0);
        mask = smoothstep(p - 0.035, p + 0.035, edge);
    } else if (effectStyle > 2.5) {
        float distanceFromCentre = length((uv - 0.5) * 1.41421356);
        if (effectStyle < 3.5)
            mask = smoothstep(p - 0.035, p + 0.035, distanceFromCentre);
        else
            mask = 1.0 - smoothstep(1.0-p-0.035, 1.0-p+0.035, distanceFromCentre);
    }
    if (p <= 0.0) mask = 1.0;
    if (p >= 1.0) mask = 0.0;
    fragColor = texture(source, uv) * qt_Opacity * mask;
}
