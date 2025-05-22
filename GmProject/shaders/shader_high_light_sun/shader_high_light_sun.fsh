#define PI 3.14159265
#define NUM_CASCADES 3

uniform sampler2D uTexture; // static
uniform int uIsSky;
uniform int uIsWater;

uniform float uSampleIndex;
uniform int uAlphaHash;

uniform vec3 uLightDirection; // static
uniform vec4 uLightColor; // static
uniform float uLightStrength; // static
uniform float uSunNear[NUM_CASCADES]; // static
uniform float uSunFar[NUM_CASCADES]; // static

uniform sampler2D uDepthBuffer0; // static
uniform sampler2D uDepthBuffer1; // static
uniform sampler2D uDepthBuffer2; // static
uniform float uCascadeEndClipSpace[NUM_CASCADES]; // static

uniform float uSSS;
uniform vec3 uSSSRadius;
uniform vec4 uSSSColor;
uniform float uSSSHighlight;
uniform float uSSSHighlightStrength;
uniform float uLightSpecular;

uniform float uDefaultSubsurface;
uniform float uDefaultEmissive;
uniform int uMaterialFormat;

uniform vec3 uCameraPosition; // static
uniform float uRoughness;
uniform float uMetallic;
uniform float uEmissive;

uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static

varying vec3 vPosition;
varying float vDepth;
varying vec3 vNormal;
varying vec3 vTangent;
varying mat3 vTBN;
varying vec2 vTexCoord;
varying vec4 vScreenCoord[NUM_CASCADES];
varying vec4 vCustom;
varying float vClipSpaceDepth;
varying vec4 vColor;

uniform int uUseNormalMap; // static

float fresnelSchlickRoughness(float cosTheta, float F0, float roughness)
{
    return F0 + (max((1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float distributionGGX(vec3 N, vec3 H, float roughness)
{
    float a2 = roughness * roughness * roughness * roughness;
    float NdotH = max(dot(N, H), 0.0);
    float denom = ((NdotH * NdotH) * (a2 - 1.0) + 1.0);
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

float unpackDepth(vec4 c)
{
    return dot(c.rgb, vec3(1.0, 0.003921569, 0.00001538));
}

vec4 cascadeDepthBuffer(int index, vec2 coord)
{
    if (index == 0) return texture2D(uDepthBuffer0, coord);
    if (index == 1) return texture2D(uDepthBuffer1, coord);
    return texture2D(uDepthBuffer2, coord);
}

float hash(vec2 c) {
    return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
                 (0.1 + abs(sin(13.0 * c.y + c.x))));
}

vec3 getMappedNormal(vec2 uv)
{
    if (uUseNormalMap < 1) return normalize(vTBN[2]);

    vec4 n = texture2D(uTextureNormal, uv);
    n = (n.a < 0.01) ? vec4(0.5, 0.5, 0.0, 1.0) : n;
    n.xy = n.xy * 2.0 - 1.0;
    n.z = sqrt(max(0.0, 1.0 - dot(n.xy, n.xy)));
    n.y *= -1.0;

    return normalize(vTBN * n.xyz);
}

void getMaterial(out float roughness, out float metallic, out float emissive, out float F0, out float sss)
{
    roughness = uRoughness;
    metallic = uMetallic;
    emissive = max(uEmissive, vCustom.z * uDefaultEmissive);
    F0 = mix(0.0, 1.0, metallic);
    sss = max(uSSS, vCustom.w * uDefaultSubsurface);

    if (uMaterialFormat == 0) return;

    vec4 matColor = texture2D(uTextureMaterial, vTexCoord);

    if (uMaterialFormat == 2) { // LabPBR
        metallic = (matColor.g > 0.898) ? 1.0 : 0.0;
        F0 = (metallic > 0.5) ? 1.0 : matColor.g;
        sss = (matColor.b > 0.255) ? ((matColor.b - 0.255) / 0.745) * max(uSSS, uDefaultSubsurface) : 0.0;
        roughness = pow(1.0 - matColor.r, 2.0);
        emissive = (matColor.a < 1.0) ? (matColor.a / 0.9961) * uDefaultEmissive : 0.0;
    } else if (uMaterialFormat == 1) { // Seus
        roughness = 1.0 - matColor.r;
        metallic = matColor.g;
        emissive = matColor.b * uDefaultEmissive;
        F0 = mix(0.0, 1.0, metallic);
        sss = max(uSSS, vCustom.w * uDefaultSubsurface);
    }
}

float CSPhase(float dotView, float scatter)
{
    float g = scatter;
    float k = (1.0 - g * g);
    float denom = 2.0 * (2.0 + g * g) * pow(1.0 + g * g - 2.0 * g * dotView, 1.5);
    return 3.0 * k * (1.0 + dotView) / denom;
}

void main()
{
    vec2 tex = vTexCoord;
    vec4 baseColor = texture2D(uTexture, tex) * vColor;

    // Alpha hashed transparency
    if (uAlphaHash > 0) {
        float h = hash(vec2(hash(vPosition.xy + (uSampleIndex / 255.0)), vPosition.z + (uSampleIndex / 255.0)));
        if (baseColor.a < h) discard;
        baseColor.a = 1.0;
    }

    // Fully transparent pixels are discarded
    if (baseColor.a == 0.0)
        discard;

    vec3 light = vec3(0.0);
    vec3 spec = vec3(0.0);

    if (uIsSky > 0) {
        // Sky pixels just get specular fallback
        spec = vec3(uLightSpecular);
    } else {
        // Material properties
        float roughness, metallic, emissive, F0, sss;
        getMaterial(roughness, metallic, emissive, F0, sss);

        // Surface normal
        vec3 normal = getMappedNormal(tex);
        float dif = clamp(dot(normal, uLightDirection), 0.0, 1.0);
        bool doLighting = (dif > 0.0 || sss > 0.0);

        // Lighting variables
        vec3 shadow = vec3(1.0);
        vec3 subsurf = vec3(0.0);

        if (doLighting) {
            // Select cascade based on depth
            int i = 0;
            if (vClipSpaceDepth >= uCascadeEndClipSpace[0]) i = 1;
            if (vClipSpaceDepth >= uCascadeEndClipSpace[1]) i = 2;

            vec2 fragCoord = vScreenCoord[i].xy;
            float fragDepth = uSunNear[i] + vScreenCoord[i].z * (uSunFar[i] - uSunNear[i]);

            // Shadow sampling
            if (fragCoord.x >= 0.0 && fragCoord.y >= 0.0 && fragCoord.x <= 1.0 && fragCoord.y <= 1.0) {
                float sampleDepth = uSunNear[i] + unpackDepth(cascadeDepthBuffer(i, fragCoord)) * (uSunFar[i] - uSunNear[i]);
                float bias = 1.0 + float(i) * 2.0;

                if ((fragDepth - bias) > sampleDepth)
                    shadow = vec3(0.0);

                // Subsurface scattering estimation
                if (sss > 0.0 && dif == 0.0) {
                    vec3 rad = uSSSRadius * sss;
                    vec3 invLight = 1.0 / (uLightColor.rgb * uLightStrength * rad + 0.001);
                    vec3 dis = max((fragDepth + bias) - sampleDepth, 0.0) * invLight;

                    subsurf = pow(max(1.0 - pow(dis / rad, vec3(4.0)), 0.0), vec3(2.0)) / (pow(dis, vec3(2.0)) + 1.0);
                }
            }
        }

        // Final diffuse lighting
        vec3 lightColor = uLightColor.rgb * uLightStrength;
        light = lightColor * dif * shadow;

        // Add subsurface scattering contribution
        if (sss > 0.0) {
            vec3 viewDir = normalize(vPosition - uCameraPosition);
            float transDif = max(0.0, dot(-normal, uLightDirection));
            subsurf += subsurf * uSSSHighlightStrength * CSPhase(dot(viewDir, uLightDirection), uSSSHighlight);
            light += lightColor * uSSSColor.rgb * transDif * subsurf;
            light *= mix(vec3(1.0), uSSSColor.rgb, clamp(sss, 0.0, 1.0));
        }

        // Specular PBR lighting
        if (uLightSpecular * dif * shadow.r > 0.0) {
            vec3 N = normal;
            vec3 L = uLightDirection;
            vec3 V = normalize(uCameraPosition - vPosition);
            vec3 H = normalize(V + L);

            float NDF = distributionGGX(N, H, roughness);
            float G = geometrySmith(N, V, L, roughness);
            float F = fresnelSchlickRoughness(max(dot(H, V), 0.0), F0, roughness);

            float numerator = NDF * G * F;
            float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
            float specular = numerator / denominator;

            spec = lightColor * uLightSpecular * dif * shadow * (specular * mix(vec3(1.0), baseColor.rgb, metallic));
        }
    }

    // Final render target outputs
    gl_FragData[0] = vec4(light, baseColor.a);
    gl_FragData[1] = vec4(spec, baseColor.a);
}
