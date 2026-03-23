#define DEPTH_SENSITIVITY 40.0

varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;
uniform sampler2D uMaterialBuffer;

uniform float uNormalBufferScale;
uniform int uIndirect;

uniform vec2 uScreenSize;
uniform float uSampleIndex;

float unpackDepth(vec4 enc)
{
    return dot(enc, vec4(
        1.0,
        1.0/255.0,
        1.0/65025.0,
        1.0/16581375.0
    ));
}

vec3 unpackNormal(vec4 c)
{
    return (c.rgb / uNormalBufferScale) * 2.0 - 1.0;
}

vec4 sampleNeighbor(vec2 samplePos, vec3 originNormal, float originDepth, vec3 originMat)
{
    // Bound check for out-of-bounds texels
    if (samplePos.x < 0.0 || samplePos.x > 1.0 || samplePos.y < 0.0 || samplePos.y > 1.0)
        return vec4(0.0);

    vec3 sampleNormal = unpackNormal(texture2D(uNormalBuffer, samplePos));
    float sampleDepth = unpackDepth(texture2D(uDepthBuffer, samplePos));
    vec3 sampleMat = (uIndirect > 0 ? vec3(0.0) : texture2D(uMaterialBuffer, samplePos).rgb);

    // Adjust weight calculation to be more dependent on normal and depth similarity
    float sampleWeight = clamp(dot(originNormal, sampleNormal) - abs(sampleMat.b - originMat.b) - abs(sampleDepth - originDepth) * DEPTH_SENSITIVITY, 0.0, 1.0);
    return vec4(texture2D(gm_BaseTexture, samplePos).rgb * sampleWeight, sampleWeight);
}

void main()
{
    // Fetch base texture and material info
    vec4 color = texture2D(gm_BaseTexture, vTexCoord);
    vec3 originMat = (uIndirect > 0 ? vec3(0.0) : texture2D(uMaterialBuffer, vTexCoord).rgb);

    // Determine if the pixel should process based on resolution and material
    float pixelIndex = (floor(vTexCoord.x * uScreenSize.x) + floor(vTexCoord.y * uScreenSize.y)) + uSampleIndex;
    
    if (originMat.b > 0.001 || uIndirect > 0)
    {
		
        vec4 sampleColor = vec4(0.0);
        vec3 originNormal = unpackNormal(texture2D(uNormalBuffer, vTexCoord));
        float originDepth = unpackDepth(texture2D(uDepthBuffer, vTexCoord));
		
		sampleColor += sampleNeighbor(vTexCoord, originNormal, originDepth, originMat);
        color.rgb = (sampleColor.rgb) / sampleColor.a;
    }

    gl_FragColor = color;
}