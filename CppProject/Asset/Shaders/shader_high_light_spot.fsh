#define PI 3.14159265

uniform sampler2D uTexture; // static
uniform int uIsSky;
uniform int uIsWater;

uniform float uSampleIndex;
uniform int uAlphaHash;

uniform vec3 uLightPosition; // static
uniform vec4 uLightColor; // static
uniform float uLightStrength; // static
uniform float uLightNear; // static
uniform float uLightFar; // static
uniform float uLightFadeSize; // static
uniform float uLightSpotSharpness; // static
uniform vec3 uShadowPosition; // static
uniform float uLightSpecular;

uniform sampler2D uDepthBuffer; // static

uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static
uniform int uMaterialFormat;
uniform float uDefaultEmissive;
uniform float uDefaultSubsurface;
uniform float uRoughness;
uniform float uMetallic;
uniform float uEmissive;

uniform float uSSS;
uniform vec3 uSSSRadius;
uniform vec4 uSSSColor;
uniform float uSSSHighlight;
uniform float uSSSHighlightStrength;

uniform vec3 uCameraPosition; // static

varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vTangent;
varying mat3 vTBN;
varying vec2 vTexCoord;
varying vec4 vScreenCoord;
varying vec4 vShadowCoord;
varying vec4 vCustom;
varying vec4 vColor;

// Fresnel Schlick approximation
float fresnelSchlickRoughness(float cosTheta, float F0, float roughness)
{
    return F0 + (max(1.0 - roughness, F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

float distributionGGX(vec3 N, vec3 H, float roughness)
{
    float a2 = roughness * roughness;
    a2 *= a2;
    float NdotH = max(dot(N, H), 0.0);
    float denom = NdotH * NdotH * (a2 - 1.0) + 1.0;
    return a2 / (PI * denom * denom);
}

float geometrySchlickGGX(float NdotV, float roughness)
{
    float k = (roughness + 1.0);
    k = (k * k) * 0.125;
    return NdotV / (NdotV * (1.0 - k) + k);
}

float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    return geometrySchlickGGX(max(dot(N, V), 0.0), roughness) *
           geometrySchlickGGX(max(dot(N, L), 0.0), roughness);
}

uniform int uUseNormalMap; // static
vec3 getMappedNormal(vec2 uv)
{
    if (uUseNormalMap < 1)
        return vTBN[2];

    vec4 n = texture2D(uTextureNormal, uv);
    if (n.a < 0.01)
        return vTBN[2];

    n.xy = n.xy * 2.0 - 1.0;
    n.z = sqrt(max(0.0, 1.0 - dot(n.xy, n.xy)));
    n.y *= -1.0;
    return normalize(vTBN * n.xyz);
}

float unpackDepth(vec4 c)
{
    return dot(c.rgb, vec3(1.0, 0.003921569, 0.00001538));
}

float hash(vec2 p)
{
    return fract(10000.0 * sin(17.0 * p.x + 0.1 * p.y) *
                 (0.1 + abs(sin(13.0 * p.y + p.x))));
}

void getMaterial(out float roughness, out float metallic, out float emissive, out float F0, out float sss)
{
    vec4 matColor = texture2D(uTextureMaterial, vTexCoord);

    if (uMaterialFormat == 2) { //LabPBR
        metallic = (matColor.g > 0.898) ? 1.0 : 0.0;
        F0 = (metallic > 0.5) ? 1.0 : matColor.g;
        sss = (matColor.b > 0.255) ? ((matColor.b - 0.255) / 0.745) * max(uSSS, uDefaultSubsurface) : 0.0;
        roughness = pow(1.0 - matColor.r, 2.0);
        emissive = (matColor.a < 1.0) ? (matColor.a / 0.9961) * uDefaultEmissive : 0.0;
    } else if (uMaterialFormat == 1) { //Seus
        roughness = 1.0 - matColor.r;
        metallic = matColor.g;
        emissive = matColor.b * uDefaultEmissive;
        F0 = mix(0.0, 1.0, metallic);
        sss = max(uSSS, vCustom.w * uDefaultSubsurface);
    } else { //None
        roughness = uRoughness;
        metallic = uMetallic;
        emissive = max(uEmissive, vCustom.z * uDefaultEmissive);
        F0 = mix(0.0, 1.0, metallic);
        sss = max(uSSS, vCustom.w * uDefaultSubsurface);
    }
}

float CSPhase(float dotView, float scatter)
{
    float s2 = scatter * scatter;
    float denom = pow(1.0 + s2 - 2.0 * scatter * dotView, 1.5);
    return (3.0 * (1.0 - s2) * (1.0 + dotView)) / (2.0 * (2.0 + s2) * denom);
}

void main()
{
    vec2 tex = vTexCoord;
    vec4 baseColor = texture2D(uTexture, tex) * vColor;

    if (uAlphaHash > 0) {
        float aHash = hash(vec2(hash(vPosition.xy + (uSampleIndex / 255.0)), vPosition.z + (uSampleIndex / 255.0)));
        if (baseColor.a < aHash) discard;
        baseColor.a = 1.0;
    }

    vec3 light = vec3(0.0), spec = vec3(0.0);

    if (uIsSky > 0) {
        spec = vec3(uLightSpecular);
    } else {
        float roughness, metallic, emissive, F0, sss;
        getMaterial(roughness, metallic, emissive, F0, sss);
        vec3 normal = getMappedNormal(tex);
        float dif = 0.0, shadow = 1.0, att = 0.0, difMask = 0.0;
        vec3 subsurf = vec3(0.0);

        if (vScreenCoord.w > 0.0)
		{
            vec3 L = normalize(uLightPosition - vPosition);
            dif = max(dot(normal, L), 0.0);
            float dist = distance(vPosition, uLightPosition);
            float fadeStart = uLightFar * (1.0 - uLightFadeSize);
            att = 1.0 - clamp((dist - fadeStart) / (uLightFar * uLightFadeSize), 0.0, 1.0);
            dif *= att;

            if (dif > 0.0 || sss > 0.0) {
                vec2 fragCoord = (vec2(vScreenCoord.x, -vScreenCoord.y) / vScreenCoord.z + 1.0) * 0.5;
                if (fragCoord.x >= 0.0 && fragCoord.y >= 0.0 && fragCoord.x <= 1.0 && fragCoord.y <= 1.0)
				{
                    difMask = 1.0 - clamp((distance(fragCoord, vec2(0.5)) - 0.5 * uLightSpotSharpness) /
                                          (0.5 * max(0.01, 1.0 - uLightSpotSharpness)), 0.0, 1.0);
                }

                dif *= difMask;

                if (difMask > 0.0) {
                    vec2 shCoord = (vec2(vShadowCoord.x, -vShadowCoord.y) / vShadowCoord.z + 1.0) * 0.5;
                    float fragDepth = min(vShadowCoord.z, uLightFar);
                    float sampleDepth = uLightNear + unpackDepth(texture2D(uDepthBuffer, shCoord)) * (uLightFar - uLightNear);
                    float bias = 0.8;

                    if ((fragDepth - bias) > sampleDepth) shadow = 0.0;

                    if (sss > 0.0 && dif == 0.0 && (fragDepth - (bias * 0.01)) > sampleDepth) {
                        vec3 rad = uSSSRadius * sss;
                        vec3 dis = (fragDepth + bias - sampleDepth) / (uLightColor.rgb * uLightStrength * rad);
                        subsurf = pow(max(1.0 - pow(dis / rad, vec3(4.0)), 0.0), vec3(2.0)) /
                                  (pow(dis, vec3(2.0)) + 1.0) * att;
                    }
                }
            }
        }

        light = uLightColor.rgb * uLightStrength * dif * shadow;

        if (sss > 0.0) {
            float transDif = max(0.0, dot(-normal, normalize(uLightPosition - vPosition)));
            float cs = CSPhase(dot(normalize(vPosition - uCameraPosition), normalize(uLightPosition - vPosition)), uSSSHighlight);
            subsurf += subsurf * uSSSHighlightStrength * cs;
            light += uLightColor.rgb * uLightStrength * uSSSColor.rgb * transDif * subsurf * difMask;
            light *= mix(vec3(1.0), uSSSColor.rgb, clamp(sss, 0.0, 1.0));
        }

        if (uLightSpecular * dif * shadow > 0.0) {
            vec3 V = normalize(uCameraPosition - vPosition);
            vec3 L = normalize(uLightPosition - vPosition);
            vec3 H = normalize(V + L);
            float NDF = distributionGGX(normal, H, roughness);
            float G = geometrySmith(normal, V, L, roughness);
            float F = fresnelSchlickRoughness(max(dot(H, V), 0.0), F0, roughness);

            float numerator = NDF * G * F;
            float denominator = 4.0 * max(dot(normal, V), 0.0) * max(dot(normal, L), 0.0) + 1e-4;
            float specular = numerator / denominator;

            spec = uLightColor.rgb * shadow * difMask * uLightSpecular * dif *
                   (specular * mix(vec3(1.0), baseColor.rgb, metallic));
        }
    }

    gl_FragData[0] = vec4(light, baseColor.a);
    gl_FragData[1] = vec4(spec, baseColor.a);

    if (baseColor.a == 0.0) discard;
}
