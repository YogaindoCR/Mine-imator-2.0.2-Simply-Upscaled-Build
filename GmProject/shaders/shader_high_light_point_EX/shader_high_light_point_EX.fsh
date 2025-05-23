#define SQRT05 0.707106781
#define PI 3.14159265
#define NOISE_SAMPLES 16.0

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
uniform vec3 uShadowPosition; // static
uniform float uLightSpecular;
uniform float uLightSize;
uniform vec2 uKernel2D;

uniform sampler2D uDepthBuffer; // static
uniform float uDepthBufferSize; // static

uniform vec3 uCameraPosition; // static

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

varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vTangent;
varying mat3 vTBN;
varying vec2 vTexCoord;
varying vec4 vCustom;
varying vec4 vColor;

// Improved noise functions
float hash(vec2 c)
{
    return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
        (0.1 + abs(sin(13.0 * c.y + c.x))));
}

float noise(vec2 p)
{
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(hash(ip), hash(ip+vec2(1.0,0.0)), u.x),
        mix(hash(ip+vec2(0.0,1.0)), hash(ip+vec2(1.0,1.0)), u.x), u.y);
    return res*res;
}

// Fresnel and PBR functions
float fresnelSchlickRoughness(float cosTheta, float F0, float roughness)
{
    return F0 + (max((1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float distributionGGX(vec3 N, vec3 H, float roughness)
{
    float a2 = roughness * roughness * roughness * roughness;
    float NdotH = max(dot(N, H), 0.0);
    float denom = (NdotH * NdotH * (a2 - 1.0) + 1.0);
    return a2 / (PI * denom * denom);
}

float geometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;
    return NdotV / (NdotV * (1.0 - k) + k);
}

float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    return geometrySchlickGGX(max(dot(N, V), 0.0), roughness) *
            geometrySchlickGGX(max(dot(N, L), 0.0), roughness);
}

// Normal mapping
uniform int uUseNormalMap; // static
vec3 getMappedNormal(vec2 uv)
{
    if (uUseNormalMap < 1)
        return vec3(vTBN[2][0], vTBN[2][1], vTBN[2][2]);
    
    vec4 n = texture2D(uTextureNormal, uv).rgba;
    n.rgba = (n.a < 0.01 ? vec4(.5, .5, 0.0, 1.0) : n.rgba);
    n.xy = n.xy * 2.0 - 1.0;
    n.z = sqrt(max(0.0, 1.0 - dot(n.xy, n.xy)));
    n.y *= -1.0;
    return normalize(vTBN * n.xyz);
}

// Depth buffer handling
float unpackDepth(vec4 c)
{
    return c.r + c.g * (1.0/255.0) + c.b * (1.0/65025.0);
}

vec2 getShadowMapCoord(vec3 look)
{
    float tFOV = tan(PI / 4.0);
    vec3 u, v, toPoint = vPosition - uShadowPosition;
    vec2 coord;
    
    look = normalize(look);
    u = vec3(-look.z * look.x, -look.z * look.y, 1.0 - look.z * look.z);
    u = normalize(u) * tFOV; 
    v = normalize(cross(u, look)) * tFOV;
    
    toPoint /= dot(toPoint, look);
    coord.x = dot(toPoint, v) / (2.0 * tFOV) + 0.5;
    coord.y = 0.5 - dot(toPoint, u) / (2.0 * tFOV);
    
    coord.x /= 3.0;
    coord.y *= 0.5;
    coord = clamp(coord, 0.001, 0.999);
    
    return coord;
}

vec4 getFilteredDepth(vec2 uv, vec2 uvMin)
{
    float samples = 0.0;
    vec2 sampleuv, uvMax, texelOffset;
    vec4 color = vec4(0.0);
    texelOffset = vec2((1.0/vec2(uDepthBufferSize * 3.0, uDepthBufferSize * 2.0)) * 0.5);
    uvMax = uvMin + vec2(1.0/3.0, 0.5);
    
    // Top left
    sampleuv = uv - texelOffset.x;
    if (sampleuv.x > uvMin.x && sampleuv.x < uvMax.x &&
        sampleuv.y > uvMin.y && sampleuv.y < uvMax.y) {
        color += texture2D(uDepthBuffer, sampleuv);
        samples += 1.0;
    }
    
    // Top right
    sampleuv.y = uv.y - texelOffset.x;
    sampleuv.x = uv.x + texelOffset.y;
    if (sampleuv.x > uvMin.x && sampleuv.x < uvMax.x &&
        sampleuv.y > uvMin.y && sampleuv.y < uvMax.y) {
        color += texture2D(uDepthBuffer, sampleuv);
        samples += 1.0;
    }
    
    // Bottom left
    sampleuv.y = uv.y + texelOffset.x;
    sampleuv.x = uv.x - texelOffset.y;
    if (sampleuv.x > uvMin.x && sampleuv.x < uvMax.x &&
        sampleuv.y > uvMin.y && sampleuv.y < uvMax.y) {
        color += texture2D(uDepthBuffer, sampleuv);
        samples += 1.0;
    }
    
    // Bottom right
    sampleuv = uv + texelOffset;
    if (sampleuv.x > uvMin.x && sampleuv.x < uvMax.x &&
        sampleuv.y > uvMin.y && sampleuv.y < uvMax.y) {
        color += texture2D(uDepthBuffer, sampleuv);
        samples += 1.0;
    }
    
    return color / samples;
}

//shadow calculation
float calculateShadow(vec2 fragCoord, vec2 bufferMin, float fragDepth, float bias)
{
    float shadow = 0.0;
    float weightSum = 0.0;
	float result = 0.0;
	
	if (uLightSize > 0.0001) {
		float texelsize = uLightSize / uKernel2D[1] / 3.0;

    for (int i = 0; i < 20; i++)
    {
		float angle = float(i) * 18.0 + uKernel2D[0];
		vec2 sampleOffset = vec2(cos(angle), sin(angle)) * texelsize;
        vec2 sampleCoord = fragCoord + sampleOffset;

        // Clamp to light atlas buffer region
        vec2 clampedCoord = clamp(
            sampleCoord,
            bufferMin + vec2(0.001),
            bufferMin + vec2(1.0 / 3.0 - 0.001, 0.5 - 0.001)
        );

        float sampleDepth = uLightNear + (uLightFar - uLightNear) *
                            unpackDepth(getFilteredDepth(clampedCoord, bufferMin));

        float shadowTest = smoothstep(bias, bias, fragDepth - sampleDepth);

        // Distance weighting for softer edges
        float weight = 1.0 - smoothstep(0.0, uLightSize, length(sampleOffset));
        shadow += (1.0 - shadowTest) * weight;
        weightSum += weight;
    }
		result = (weightSum > 0.0) ? shadow / weightSum : 1.0;
	} else {
		float sampleDepth = uLightNear + (uLightFar - uLightNear) * unpackDepth(getFilteredDepth(fragCoord, bufferMin));
        shadow = ((fragDepth - bias) > sampleDepth) ? 0.0 : 1.0;
        result = shadow;
	}

    return result;
}


// Material properties
void getMaterial(out float roughness, out float metallic, out float emissive, out float F0, out float sss)
{
    vec4 matColor = texture2D(uTextureMaterial, vTexCoord);
    
    if (uMaterialFormat == 2) { // LabPBR
        if (matColor.g > 0.898) { // Metallic
            metallic = 1.0; F0 = 1.0; sss = 0.0;
        } else { // Non-metallic
            metallic = 0.0; F0 = matColor.g;
            sss = (matColor.b > 0.255 ? (((matColor.b - 0.255) / 0.745) * max(uSSS, uDefaultSubsurface)) : 0.0);
        }
        roughness = pow(1.0 - matColor.r, 2.0);
        emissive = (matColor.a < 1.0 ? matColor.a /= 0.9961 : 0.0) * uDefaultEmissive;
        return;
    }
    
    if (uMaterialFormat == 1) { // SEUS
        roughness = (1.0 - matColor.r);
        metallic = matColor.g;
        emissive = (matColor.b * uDefaultEmissive);
    } else { // No map
        roughness = uRoughness;
        metallic = uMetallic;
        emissive = max(uEmissive, vCustom.z * uDefaultEmissive);
    }
    
    F0 = mix(0.0, 1.0, metallic);
    sss = max(uSSS, vCustom.w * uDefaultSubsurface);
}

// Subsurface scattering
float CSPhase(float dotView, float scatter)
{
    float result = (3.0 * (1.0 - (scatter * scatter))) * (1.0 + dotView);
    result /= 2.0 * (2.0 + pow(scatter, 2.0)) * pow(1.0 + pow(scatter, 2.0) - 2.0 * scatter * dotView, 1.5);
    return result;
}

void main()
{
    vec3 light, spec = vec3(0.0);
    vec2 tex = vTexCoord;
    vec4 baseColor = texture2D(uTexture, tex) * vColor;
    
    // Alpha hashing
    if (uAlphaHash > 0)
	{
        if (baseColor.a < hash(vec2(hash(vPosition.xy + (uSampleIndex / 255.0)), vPosition.z + (uSampleIndex / 255.0))))
            discard;
        else
            baseColor.a = 1.0;
    }
    
    if (uIsSky > 0)
	{
        light = vec3(0.0);
        spec = vec3(uLightSpecular);
    } 
	else
	{
        // Get material properties
        float roughness, metallic, emissive, F0, sss;
        getMaterial(roughness, metallic, emissive, F0, sss);
        vec3 normal = getMappedNormal(vTexCoord);
        
        float shadow = 1.0;
        float att = 0.0;
        vec3 subsurf = vec3(0.0);
        
        // Diffuse factor
        float dif = max(0.0, dot(normal, normalize(uLightPosition - vPosition))); 
        
        // Improved attenuation with smooth transitions
        float fadeStart = uLightFar * (1.0 - uLightFadeSize);
        float fadeEnd = uLightFar;
        float dist = distance(vPosition, uLightPosition);
        att = 1.0 - smoothstep(fadeStart, fadeEnd, dist);
        att *= smoothstep(0.0, uLightNear * 2.0, dist);
        dif *= att;
        
        if (dif > 0.0 || sss > 0.0)
		{
            vec2 fragCoord, bufferMin;
            vec3 toLight = vPosition - uShadowPosition;
            vec4 lookDir = vec4(
                toLight.x / distance(vPosition.xy, uShadowPosition.xy),
                toLight.y / distance(vPosition.xy, uShadowPosition.xy),
                toLight.z / distance(vPosition.xz, uShadowPosition.xz),
                toLight.z / distance(vPosition.yz, uShadowPosition.yz)
            );
            
            // Determine shadow map face
            if (lookDir.z > SQRT05 && lookDir.w > SQRT05) { // Z+
                fragCoord = getShadowMapCoord(vec3(0.0, -0.0001, 1.0));
                fragCoord.x += 1.0/3.0;
                fragCoord.y += 0.5;
                bufferMin = vec2(1.0/3.0, 0.5);
            } else if (lookDir.z < -SQRT05 && lookDir.w < -SQRT05) { // Z-
                fragCoord = getShadowMapCoord(vec3(0.0, -0.0001, -1.0));
                fragCoord.x += 2.0/3.0;
                fragCoord.y += 0.5;
                bufferMin = vec2(2.0/3.0, 0.5);
            } else if (lookDir.x > SQRT05) { // X+
                fragCoord = getShadowMapCoord(vec3(1.0, 0.0, 0.0));
                bufferMin = vec2(0.0);
            } else if (lookDir.x < -SQRT05) { // X-
                fragCoord = getShadowMapCoord(vec3(-1.0, 0.0, 0.0));
                fragCoord.x += 1.0/3.0;
                bufferMin = vec2(1.0/3.0, 0.0);
            } else if (lookDir.y > SQRT05) { // Y+
                fragCoord = getShadowMapCoord(vec3(0.0, 1.0, 0.0));
                fragCoord.x += 2.0/3.0;
                bufferMin = vec2(2.0/3.0, 0.0);
            } else { // Y-
                fragCoord = getShadowMapCoord(vec3(0.0, -1.0, 0.0));
                fragCoord.y += 0.5;
                bufferMin = vec2(0.0, 0.5);
            }
            
            // Calculate bias and shadow
            float bias = max(0.01 * (1.0 - dot(normal, normalize(uLightPosition - vPosition))), 0.6);
            float fragDepth = distance(vPosition, uShadowPosition);
            shadow = calculateShadow(fragCoord, bufferMin, fragDepth, bias);
            
            // Subsurface scattering
            if (sss > 0.001 && dif == 0.0)
			{
                vec3 rad = uSSSRadius * sss;
                vec3 dis = vec3((fragDepth + bias) - (uLightNear + (uLightFar - uLightNear) * unpackDepth(getFilteredDepth(fragCoord, bufferMin)))) / (uLightColor.rgb * uLightStrength * rad);
                
                if ((fragDepth - (bias * 0.01)) <= (uLightNear + (uLightFar - uLightNear) * unpackDepth(getFilteredDepth(fragCoord, bufferMin))))
                    dis = vec3(0.0);
                
                subsurf = pow(max(1.0 - pow(dis / rad, vec3(4.0)), 0.0), vec3(2.0)) / (pow(dis, vec3(2.0)) + 1.0) * att;
                subsurf *= smoothstep(0.0, 1.0, (sss / 5.0));
            }
        }
        
        // Final lighting calculations
        light = uLightColor.rgb * uLightStrength * dif * shadow;
        
        // Subsurface scattering contribution
        if (sss > 0.001)
		{
            float transDif = max(0.0, dot(normalize(-normal), normalize(uLightPosition - vPosition)));
            subsurf += (subsurf * uSSSHighlightStrength * CSPhase(dot(normalize(vPosition - uCameraPosition), normalize(uLightPosition - vPosition)), uSSSHighlight));
            light += (uLightColor.rgb * uLightStrength * uSSSColor.rgb * transDif * subsurf) * smoothstep(0.0, 0.1, (sss / 50.0));
            light *= mix(vec3(1.0), uSSSColor.rgb, clamp(sss / 75.0, 0.0, 1.0));
        }
        
        // Specular highlights
        if (uLightSpecular * dif * shadow > 0.0)
		{
            vec3 N = normal;
            vec3 V = normalize(uCameraPosition - vPosition);
            vec3 L = normalize(uLightPosition - vPosition);
            vec3 H = normalize(V + L);
            
            float NDF = distributionGGX(N, H, roughness);
            float G = geometrySmith(N, V, L, roughness);
            float F = fresnelSchlickRoughness(max(dot(H, V), 0.0), F0, roughness);
            
            float numerator = NDF * G * F;
            float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
            float specular = numerator / denominator;
            
            spec = uLightColor.rgb * shadow * uLightSpecular * dif * (specular * mix(vec3(1.0), baseColor.rgb, metallic));
        }
    }
    
    // Output
    gl_FragData[0] = vec4(light, baseColor.a);
    gl_FragData[1] = vec4(spec, baseColor.a);
    
    if (baseColor.a == 0.0)
        discard;
}