#define PI 3.14159265
#define NUM_CASCADES 3
#define GOLDEN_ANGLE 2.399963

uniform int uIsSky;

uniform sampler2D uTexture; // static
uniform float uSampleIndex;
uniform int uAlphaHash;

uniform vec3 uLightDirection; // static
uniform vec4 uLightColor; // static
uniform float uLightStrength; // static
uniform float uSunNear[NUM_CASCADES]; // static
uniform float uSunFar[NUM_CASCADES]; // static
uniform vec2 uKernel2D;

uniform sampler2D uDepthBuffer0; // static
uniform sampler2D uDepthBuffer1; // static
uniform sampler2D uDepthBuffer2; // static
uniform float uCascadeEndClipSpace[NUM_CASCADES]; // static

uniform float uSSS;
uniform vec3 uSSSRadius;
uniform vec4 uSSSColor;
uniform float uSSSStrength;
uniform float uSSSSharpness;
uniform float uSSSDesaturation;
uniform float uSSSColorThreshold;
uniform float uAbsorption;
uniform float uSSSHighlight;
uniform float uSSSHighlightStrength;
uniform float uSSSHighlightSharpness;
uniform float uSSSHighlightColorThreshold;
uniform float uSSSHighlightDesaturation;
uniform bool uSSSHighQuality;
uniform float uLightSpecular;
uniform float uLightSize;
uniform float uShadowBlurSample;
uniform float uBias;

uniform float uDefaultSubsurface;
uniform float uDefaultEmissive;
uniform int uMaterialFormat;

uniform vec3 uCameraPosition; // static
uniform float uRoughness;
uniform float uMetallic;
uniform float uEmissive;
uniform float uNormalStrength;

uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static
uniform int uUseNormalMap; // static

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

// Material parameters for PBR surface model
uniform float emissive;
uniform float metallic;
uniform float roughness;
uniform float ao;
uniform sampler2D metallicMap;
uniform sampler2D roughnessMap;
uniform sampler2D aoMap;

// Declare variables "specular" and "Lo" as uniforms to bypass a compilation error
uniform float specular;
uniform vec3 Lo;

// Fresnel-Schlick approximation (injected roughness term)
// -------------------------------------------------------
// https://learnopengl.com/PBR/IBL/Diffuse-irradiance
float fresnelSchlickRoughness(float cosTheta, float F0, float roughness)
{
    return F0 + (max(float(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

// Normal distribution function (Trowbridge-Reitz GGX)
// ---------------------------------------------------
// https://learnopengl.com/PBR/Lighting
float distributionGGX(vec3 N, vec3 H, float roughness)
{
    float a      = roughness * roughness;
	float a2     = a * a;
	float NdotH  = max(dot(N, H), 0.0);
	float NdotH2 = NdotH * NdotH;
	
	float num   = a2;
	float denom = (NdotH2 * (a2 - 1.0) + 1.0);
	denom = PI * denom * denom;
	
	return num / denom;
}

// Geometry function (Schlick-GGX)
float geometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
	float k = (r * r) / 8.0;
	
	float num   = NdotV;
	float denom = NdotV * (1.0 - k) + k;
	
	return num / denom;
}

// Smith's method with Schlick-GGX
float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float ggx2  = geometrySchlickGGX(NdotV, roughness);
	float ggx1  = geometrySchlickGGX(NdotL, roughness);
	
	return ggx1 * ggx2;
}

float unpackDepth(vec4 enc)
{
    return dot(enc, vec4(
        1.0,
        1.0/255.0,
        1.0/65025.0,
        1.0/16581375.0
    ));
}

vec4 cascadeDepthBuffer(int index, vec2 coord)
{
    if (index == 0)
        return texture2D(uDepthBuffer0, coord);
    else if (index == 1)
        return texture2D(uDepthBuffer1, coord);
    else
        return texture2D(uDepthBuffer2, coord);
}

vec3 getMappedNormal(vec2 uv)
{
    if (uUseNormalMap < 1)
        return vec3(vTBN[2][0], vTBN[2][1], vTBN[2][2]);
    
    vec4 n = texture2D(uTextureNormal, uv).rgba;
    n.rgba = (n.a < 0.01 ? vec4(.5, .5, 0.0, 1.0) : n.rgba);
    n.xy = n.xy * 2.0 - 1.0;
	n.z  = sqrt(1.0 - dot(n.xy, n.xy));
	//n.y *= -1.0; // DirectX fix if needed

	vec3 smoothNormal = normalize(mix(vec3(0.0, 0.0, 1.0), n.xyz, uNormalStrength));
	return normalize(vTBN * smoothNormal);
}

float hash(vec2 c)
{
	return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
	(0.1 + abs(sin(13.0 * c.y + c.x))));
}

void getMaterial(out float roughness, out float metallic, out float emissive, out float F0, out float sss)
{
    vec4 matColor = texture2D(uTextureMaterial, vTexCoord);
    
    if (uMaterialFormat == 2) { // LabPBR
        if (matColor.g > 0.898) { // Metallic
            metallic = 1.0; F0 = 1.0; sss = 0.0;
        } else { // Non-metallic
            metallic = 0.0; F0 = matColor.g;
            sss = (matColor.b > 0.255) ? ((matColor.b - 0.255) * 1.34228) * max(uSSS, uDefaultSubsurface) : 0.0;
        }
        roughness = pow(1.0 - matColor.r, 2.0); // Convert material color to linear roughness
		matColor.r = 1.0 - sqrt(roughness);		// Convert linear roughness to material color
        emissive = (matColor.a < 1.0) ? matColor.a * 1.00392 * uDefaultEmissive : 0.0;
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
    
    F0 = mix(0.0, 1.0, metallic);
    sss = max(uSSS, vCustom.w * uDefaultSubsurface);
}

float CSPhase(float dotView, float scatter)
{
    float scatter2 = scatter * scatter;
    float numerator = 3.0 * (1.0 - scatter2) * (1.0 + dotView);
    float denominator = 2.0 * (2.0 + scatter2);
    float root = 1.0 + scatter2 - 2.0 * scatter * dotView;
    return numerator / (denominator * root * sqrt(root));
}

void main()
{
    vec2 tex = vTexCoord;
    vec4 baseColor = texture2D(uTexture, tex) * vColor;
    
    // Early alpha test
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
    float shadow = 1.0;
    vec3 subsurf = vec3(0.0);
    vec3 subsurfHighlight = vec3(0.0);

    if (uIsSky > 0) {
        // Sky pixels just get specular fallback
        spec = vec3(uLightSpecular);
	} else {
		
	    // Get material data
	    float roughness, metallic, emissive, F0, sss;
	    getMaterial(roughness, metallic, emissive, F0, sss);
    
	    vec3 normal = getMappedNormal(tex);
	    float dif = max(dot(normal, uLightDirection), 0.0);
    
	    if (dif > 0.0 || sss > 0.0)
		{
	        // Find cascade using binary search pattern
	        int cascadeIndex = 0;
	        if (vClipSpaceDepth < uCascadeEndClipSpace[1]) {
	            if (vClipSpaceDepth < uCascadeEndClipSpace[0]) {
	                cascadeIndex = 0;
	            } else {
	                cascadeIndex = 1;
	            }
	        } else {
	            cascadeIndex = 2;
	        }
        
	        float fragDepth = vScreenCoord[cascadeIndex].z;
	        vec2 fragCoord = vScreenCoord[cascadeIndex].xy;
        
	        if (fragCoord.x >= 0.0 && fragCoord.y >= 0.0 && fragCoord.x <= 1.0 && fragCoord.y <= 1.0) {
	            fragDepth = mix(uSunNear[cascadeIndex], uSunFar[cascadeIndex], fragDepth);
	            float bias = (mix(3.6, 0.1, dot(normal, uLightDirection)) + (uLightSize * 10.0)) * uBias;

	            if (uLightSize > 0.005)
				{
	                float blurAmount = uLightSize * (0.01 + (float(cascadeIndex) * -0.004)) * uKernel2D[1];
	                bias += (float(cascadeIndex) * (float(cascadeIndex) / 1.2) * 1.5);
					shadow = 0.0;
					float goldenAngle = 2.399963;
                
	                for (int i = 0; i < 128; i++)
					{
						if (i > int(uShadowBlurSample))
							break;
						// Golden Sampling
						float r = sqrt(float(i)+0.5) / sqrt(float(uShadowBlurSample));
						float theta = float(i) * GOLDEN_ANGLE + uKernel2D[0];

						vec2 sampleOffset = vec2(cos(theta), sin(theta)) * r * blurAmount;
	                    vec2 sampleCoord = fragCoord + sampleOffset;
                    
	                    if (sampleCoord.x >= 0.0 && sampleCoord.y >= 0.0 && sampleCoord.x <= 1.0 && sampleCoord.y <= 1.0) {
	                        float sampleDepth = mix(uSunNear[cascadeIndex], uSunFar[cascadeIndex], 
	                                             unpackDepth(cascadeDepthBuffer(cascadeIndex, sampleCoord)));
                        
	                        // Shadow calculation
	                        shadow += (fragDepth - bias) > sampleDepth ? 0.0 : 1.0;
                        
	                        // Subsurface scattering
	                        if (uSSSHighQuality && sss > 0.0) {
	                            vec3 rad, dis, falloff;
                            
	                            // Main SSS
	                            if (uSSSStrength > 0.01) {
	                                rad = uSSSRadius * sss;
	                                dis = vec3((fragDepth + bias) - sampleDepth) / 
	                                     (mix(uLightColor.rgb, vec3(1.0), uSSSColorThreshold) * uLightStrength * rad);
                                
	                                if (fragDepth - (bias * 0.1) <= sampleDepth)
	                                    dis = vec3(0.0);
                                
	                                falloff = pow(max(1.0 - pow(dis / rad, vec3(uSSSSharpness)), 0.0), 
	                                         vec3(uSSSSharpness * 0.5));
	                                subsurf += (falloff / (pow(dis, vec3(2.0)) + 1.0)) * uSSSStrength;
	                            }
                            
	                            // Highlight SSS
	                            if (uSSSHighlightStrength > 0.01) {
	                                rad = uSSSRadius * sss * (1.0 - uSSSHighlight);
	                                dis = vec3((fragDepth + bias) - sampleDepth) / 
	                                     (mix(uLightColor.rgb, vec3(1.0), uSSSHighlightColorThreshold) * uLightStrength * rad);
                                
	                                if (fragDepth - (bias * 0.1) <= sampleDepth)
	                                    dis = vec3(0.0);
                                
	                                falloff = pow(max(1.0 - pow(dis / rad, vec3(uSSSHighlightSharpness)), 0.0), 
	                                         vec3(uSSSHighlightSharpness * 0.5));
	                                subsurfHighlight += (falloff / (pow(dis, vec3(2.0)) + 1.0)) * uSSSHighlightStrength;
	                            }
	                        }
	                    }
	                }
                
	                shadow /= uShadowBlurSample;
	                if (uSSSHighQuality && sss > 0.0) {
	                    subsurf /= uShadowBlurSample;
	                    subsurfHighlight /= uShadowBlurSample;
	                }
	            } else {
	                float sampleDepth = mix(uSunNear[cascadeIndex], uSunFar[cascadeIndex], 
	                                     unpackDepth(cascadeDepthBuffer(cascadeIndex, fragCoord)));
	                shadow = (fragDepth - bias) > sampleDepth ? 0.0 : 1.0;
                
	                // Non-high quality SSS
	                if (sss > 0.0) {
	                    vec3 rad, dis, falloff;
                    
	                    // Main SSS
	                    if (uSSSStrength > 0.01) {
	                        rad = uSSSRadius * sss;
	                        dis = vec3((fragDepth + bias) - sampleDepth) / 
	                             (mix(uLightColor.rgb, vec3(1.0), uSSSColorThreshold) * uLightStrength * rad);
                        
	                        if (fragDepth - (bias * 0.1) <= sampleDepth)
	                            dis = vec3(0.0);
                        
	                        falloff = pow(max(1.0 - pow(dis / rad, vec3(uSSSSharpness)), 0.0), 
	                                 vec3(uSSSSharpness * 0.5));
	                        subsurf = (falloff / (pow(dis, vec3(2.0)) + 1.0)) * uSSSStrength;
	                    }
                    
	                    // Highlight SSS
	                    if (uSSSHighlightStrength > 0.01) {
	                        rad = uSSSRadius * sss * (1.0 - uSSSHighlight);
	                        dis = vec3((fragDepth + bias) - sampleDepth) / 
	                             (mix(uLightColor.rgb, vec3(1.0), uSSSHighlightColorThreshold) * uLightStrength * rad);
                        
	                        if (fragDepth - (bias * 0.1) <= sampleDepth)
	                            dis = vec3(0.0);
                        
	                        falloff = pow(max(1.0 - pow(dis / rad, vec3(uSSSHighlightSharpness)), 0.0), 
	                                 vec3(uSSSHighlightSharpness * 0.5));
	                        subsurfHighlight = (falloff / (pow(dis, vec3(2.0)) + 1.0)) * uSSSHighlightStrength;
	                    }
	                }
	            }
			
				// Non-high quality SSS
	            if (sss > 0.0 && !uSSSHighQuality) {
	                vec3 rad, dis, falloff;
	                float sampleDepth = mix(uSunNear[cascadeIndex], uSunFar[cascadeIndex], 
	                                     unpackDepth(cascadeDepthBuffer(cascadeIndex, fragCoord)));
                    
	                // Main SSS
	                if (uSSSStrength > 0.01) {
	                    rad = uSSSRadius * sss;
	                    dis = vec3((fragDepth + bias) - sampleDepth) / 
	                            (mix(uLightColor.rgb, vec3(1.0), uSSSColorThreshold) * uLightStrength * rad);
                        
	                    if (fragDepth - (bias * 0.1) <= sampleDepth)
	                        dis = vec3(0.0);
                        
	                    falloff = pow(max(1.0 - pow(dis / rad, vec3(uSSSSharpness)), 0.0), 
	                                vec3(uSSSSharpness * 0.5));
	                    subsurf = (falloff / (pow(dis, vec3(2.0)) + 1.0)) * uSSSStrength;
	                }
                    
	                // Highlight SSS
	                if (uSSSHighlightStrength > 0.01) {
	                    rad = uSSSRadius * sss * (1.0 - uSSSHighlight);
	                    dis = vec3((fragDepth + bias) - sampleDepth) / 
	                            (mix(uLightColor.rgb, vec3(1.0), uSSSHighlightColorThreshold) * uLightStrength * rad);
                        
	                    if (fragDepth - (bias * 0.1) <= sampleDepth)
	                        dis = vec3(0.0);
                        
	                    falloff = pow(max(1.0 - pow(dis / rad, vec3(uSSSHighlightSharpness)), 0.0), 
	                                vec3(uSSSHighlightSharpness * 0.5));
	                    subsurfHighlight = (falloff / (pow(dis, vec3(2.0)) + 1.0)) * uSSSHighlightStrength;
	                }
	            }
	        }
	    }
    
	    // Diffuse light
	    light = uLightColor.rgb * (uLightStrength * dif * shadow);
    
	    // Subsurface scattering
	    if (sss > 0.0)
		{
	        float transDif = max(0.0, dot(normalize(-normal), uLightDirection));
	        float absorption = CSPhase(dot(normalize(vPosition - uCameraPosition), uLightDirection), uAbsorption);
        
	        subsurf *= absorption;
	        subsurfHighlight *= absorption;
        
	        // Mix both subsurface layers
	        light += (mix(uLightColor.rgb, vec3(1.0), uSSSDesaturation) * uLightStrength * uSSSColor.rgb * transDif * subsurf) * smoothstep(0.0, 0.05, (sss / 50.0));
	        light += (mix(uLightColor.rgb, vec3(1.0), uSSSHighlightDesaturation) * uLightStrength * uSSSColor.rgb * transDif * subsurfHighlight) * smoothstep(0.0, 0.05, (sss / 50.0));
        
	        light *= mix(vec3(1.0), uSSSColor.rgb, clamp(sss / 75.0, 0.0, 1.0));
	    }
    
	    // Calculate specular highlights (PBR surface model)
	    if (uLightSpecular * dif * shadow > 0.0)
		{
	        // Textured PBR
			float metallic  = texture2D(metallicMap, vTexCoord).r;
			float roughness = texture2D(roughnessMap, vTexCoord).r;
			float ao        = texture2D(aoMap, vTexCoord).r;
				
			vec3 N = normalize(normal);
			vec3 V = normalize(uCameraPosition - vPosition);
				
			// Mix material parameters
			F0 = mix(F0, emissive, metallic);
				
			// Reflectance equation
			vec3 Lo = vec3(0.0);
			for (int i = 0; i < 4; ++i)
			{
				// Calculate per-light radiance
				vec3 L = normalize(uLightDirection - vPosition);
				vec3 H = normalize(V + L);
				float distance    = length(uLightDirection - vPosition);
				float attenuation = 1.0 / (distance * distance);
				vec3 radiance     = uLightColor.rgb * attenuation;
					
				// Cook-Torrance BRDF
				float NDF = distributionGGX(N, H, roughness);
				float G   = geometrySmith(N, V, L, roughness);
				float F   = fresnelSchlickRoughness(max(dot(N, V), 0.0), F0, roughness);
					
				float kS = F;
				vec3  kD = vec3(1.0) - kS;
				kD *= 1.0 - metallic;
					
				float numerator   = NDF * G * F;
				float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
				float specular    = numerator / denominator;
					
				// Add to outgoing radiance Lo
				float NdotL = max(dot(N, L), 0.0);
				Lo += (kD * emissive / PI + specular) * radiance * NdotL;
			}
			
	        spec = uLightColor.rgb * uLightSpecular * dif * shadow * (specular * mix(vec3(1.0), baseColor.rgb, metallic));
	    }
	}
	
	// Add an ambient term to the direct lighting result Lo
	vec3 ambient = vec3(0.03) * emissive * ao;
	vec3 color = ambient + Lo;
	
	// Tone map the HDR color using the Reinhard operator
	color = color / (color + vec3(1.0));
	color = pow(color, vec3(1.0/2.2));
    
    // Final output
    gl_FragData[0] = vec4(light, baseColor.a);
    gl_FragData[1] = vec4(spec, baseColor.a);
}