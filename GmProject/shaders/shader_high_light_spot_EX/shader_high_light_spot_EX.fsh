#define PI 3.141592653589793
#define INV_PI 0.3183098861837907

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
uniform float uLightSize;
uniform float uResolution;
uniform float uBlurSample;

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

// Optimized Fresnel Schlick approximation
float fresnelSchlickRoughness(float cosTheta, float F0, float roughness)
{
    float powTerm = pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
    return F0 + (max(1.0 - roughness, F0) - F0) * powTerm;
}

// Optimized GGX distribution
float distributionGGX(vec3 N, vec3 H, float roughness)
{
    float a2 = roughness * roughness;
    a2 *= a2; // roughness^4
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;
    float denom = NdotH2 * (a2 - 1.0) + 1.0;
    return a2 / (PI * denom * denom);
}

// Optimized geometry function
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
        return normalize(vNormal);
    
    vec4 n = texture2D(uTextureNormal, uv).rgba;
    if (n.a < 0.01) return normalize(vNormal); // Fallback to vertex normal
    
    n.xy = n.xy * 2.0 - 1.0;
    n.z = sqrt(max(0.0, 1.0 - dot(n.xy, n.xy)));
    n.y *= -1.0;
    return normalize(vTBN * n.xyz);
}

// Faster depth unpacking using bit manipulation emulation
float unpackDepth(vec4 c)
{
    return c.r + c.g * (1.0/255.0) + c.b * (1.0/65025.0);
}

// Better hash function with less artifacts
float hash(vec2 c)
{
    return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
}

void getMaterial(out float roughness, out float metallic, out float emissive, out float F0, out float sss)
{
    vec4 matColor = texture2D(uTextureMaterial, vTexCoord);
    
    if (uMaterialFormat == 2) { // LabPBR
        metallic = step(0.898, matColor.g); // Metallic threshold
        F0 = mix(matColor.g, 1.0, metallic);
        sss = (matColor.b > 0.255) ? ((matColor.b - 0.255) * (1.0/0.745) * max(uSSS, uDefaultSubsurface)) : 0.0;
        roughness = pow(1.0 - matColor.r, 2.0);
        emissive = (matColor.a < 1.0 ? matColor.a * (1.0/0.9961) : 0.0) * uDefaultEmissive;
        return;
    }
    
    if (uMaterialFormat == 1) { // SEUS
        roughness = 1.0 - matColor.r;
        metallic = matColor.g;
        emissive = matColor.b * uDefaultEmissive;
    } else { // No map
        roughness = uRoughness;
        metallic = uMetallic;
        emissive = max(uEmissive, vCustom.z * uDefaultEmissive);
    }
    
    F0 = mix(0.04, 0.95, metallic); // Better F0 defaults
    sss = max(uSSS, vCustom.w * uDefaultSubsurface);
}

// Optimized subsurface scattering function
float CSPhase(float dotView, float scatter)
{
    float scatter2 = scatter * scatter;
    float denom = 2.0 * (2.0 + scatter2) * pow(1.0 + scatter2 - 2.0 * scatter * dotView, 1.5);
    return (3.0 * (1.0 - scatter2) * (1.0 + dotView)) / denom;
}

void main()
{
    vec3 light = vec3(0.0);
    vec3 spec = vec3(0.0);
    float difMask = 0.0;
    vec2 tex = vTexCoord;
    vec4 baseColor = texture2D(uTexture, tex) * vColor;
    
    // Alpha testing
    if (uAlphaHash > 0) {
        if (baseColor.a < hash(vec2(hash(vPosition.xy + (uSampleIndex / 255.0)), vPosition.z + (uSampleIndex / 255.0))))
            discard;
        baseColor.a = 1.0;
    }
    
    if (uIsSky > 0) {
        spec = vec3(uLightSpecular);
    } else {
        // Get material data
        float roughness, metallic, emissive, F0, sss;
        getMaterial(roughness, metallic, emissive, F0, sss);
        vec3 normal = getMappedNormal(vTexCoord);
        
        float dif = 0.0;
        float shadow = 1.0;
        float att = 0.0;
        vec3 subsurf = vec3(0.0);
        
        // Early exit if behind light
        if (vScreenCoord.w > 0.0) {
            vec3 lightDir = uLightPosition - vPosition;
            float lightDist = length(lightDir);
            lightDir /= lightDist;
            
            // Diffuse factor
            dif = max(0.0, dot(normal, lightDir));
            
            // Attenuation
            float fadeStart = uLightFar * (1.0 - uLightFadeSize);
            att = 1.0 - smoothstep(fadeStart, uLightFar, lightDist);
            dif *= att;
            
            if (dif > 0.0 || sss > 0.0) {
                // Spotlight projection
                vec2 fragCoord = (vec2(vScreenCoord.x, -vScreenCoord.y) / vScreenCoord.w + 1.0) * 0.5;
                difMask = 0.0;
                
                if (fragCoord.x >= 0.0 && fragCoord.y >= 0.0 && fragCoord.x <= 1.0 && fragCoord.y <= 1.0) {
				    float distToCenter = distance(fragCoord, vec2(0.5));
				    difMask = 1.0 - smoothstep(0.5 * uLightSpotSharpness, 0.5, distToCenter);
				} else {
				    difMask = 0.0;
				}
                
                dif *= difMask;
                
                // Shadow calculation
               if (difMask > 0.0) {
					
                    vec2 shadowCoord = (vec2(vShadowCoord.x, -vShadowCoord.y) / vShadowCoord.w + 1.0) * 0.5;
                    
                   if (shadowCoord.x > 0.0 && shadowCoord.y > 0.0 && shadowCoord.x < 1.0 && shadowCoord.y < 1.0) {
                        float fragDepth = min(vShadowCoord.z, uLightFar);
						float bias = max(0.01 * (1.0 - dot(normal, normalize(lightDir - vPosition))), 0.6);
                        
                        float sampleDepth = uLightNear + unpackDepth(texture2D(uDepthBuffer, shadowCoord)) * (uLightFar - uLightNear);
						shadow = 0.0;
						
						//Shadow Blur
						if (uLightSize > 0.1)
						{
							float texelSize = (0.5 / uResolution) * uLightSize;

							for (float i = 0.0;i <= 32.0;i++) {
							    vec2 offset = vec2(sin(i), cos(i)) * texelSize;
							    float sampleDepth = uLightNear + unpackDepth(texture2D(uDepthBuffer, shadowCoord + offset)) * (uLightFar - uLightNear);
							    shadow += step(fragDepth - bias, sampleDepth);
							}
							shadow /= 32.0; // Average the samples
						
						} else {
							float sampleDepth = uLightNear + unpackDepth(texture2D(uDepthBuffer, shadowCoord)) * (uLightFar - uLightNear);
						    shadow += step(fragDepth - bias, sampleDepth);
						}

                        
                        // Subsurface scattering
                        if (sss > 0.001 && dif == 0.0)
						{
							vec3 rad = uSSSRadius * sss;
							vec3 dis = vec3((fragDepth + bias) - sampleDepth) / (uLightColor.rgb * uLightStrength * rad);
						
							if ((fragDepth - (bias * 0.01)) <= sampleDepth)
								dis = vec3(0.0);
						
							subsurf = pow(max(1.0 - pow(dis / rad, vec3(4.0)), 0.0), vec3(2.0)) / (pow(dis, vec3(2.0)) + 1.0) * att;
						}
                    }
                }
            }
        }
        
        // Light calculation
        light = uLightColor.rgb * uLightStrength * dif * shadow;
        
        // Subsurface scattering
        if (sss > 0.001)
		{
			float transDif = max(0.0, dot(normalize(-normal), normalize(uLightPosition - vPosition)));
			subsurf += (subsurf * uSSSHighlightStrength * CSPhase(dot(normalize(vPosition - uCameraPosition), normalize(uLightPosition - vPosition)), uSSSHighlight));
			light += (uLightColor.rgb * uLightStrength * uSSSColor.rgb * transDif * subsurf * difMask) * smoothstep(0.0, 0.1, (sss / 50.0));
			light *= mix(vec3(1.0), uSSSColor.rgb, clamp((sss / 20.0), 0.0, 0.5));
		}
        
        // Specular calculation
        if (uLightSpecular > 0.0 && dif * shadow > 0.0) {
		    vec3 V = normalize(uCameraPosition - vPosition);
		    vec3 L = normalize(uLightPosition - vPosition);
		    vec3 H = normalize(V + L);
    
		    float NDF = distributionGGX(normal, H, roughness);
		    float G = geometrySmith(normal, V, L, roughness);
		    float F = fresnelSchlickRoughness(max(dot(H, V), 0.0), F0, roughness);
    
		    vec3 kS = vec3(F);
		    vec3 kD = vec3(1.0) - kS;
		    kD *= 1.0 - metallic;
    
		    float numerator = NDF * G * F;
		    float denominator = 4.0 * max(dot(normal, V), 0.0) * max(dot(normal, L), 0.0) + 0.0001;
		    vec3 specular = vec3(numerator / denominator);
    
		    spec = uLightColor.rgb * shadow * uLightSpecular * dif * specular * mix(vec3(1.0), baseColor.rgb, metallic);
		}
    }
    
    gl_FragData[0] = vec4(light, baseColor.a);
    gl_FragData[1] = vec4(spec, baseColor.a);
    
    if (baseColor.a == 0.0)
        discard;
}