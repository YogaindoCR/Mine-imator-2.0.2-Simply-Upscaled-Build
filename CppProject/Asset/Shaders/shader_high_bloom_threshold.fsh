uniform float uThreshold;

varying vec2 vTexCoord;

void main()
{
    vec4 baseColor = texture2D(gm_BaseTexture, vTexCoord);

    float brightness = max(max(baseColor.r, baseColor.g), baseColor.b);

    float softness = 0.1;

    float mask = smoothstep(
        uThreshold - softness,
        uThreshold + softness,
        brightness
    );

    gl_FragColor = vec4(baseColor.rgb * mask, 1.0);
}