#define PI 3.141592653589793
#define INV_PI 0.3183098861837907
#define GOLDEN_ANGLE 2.399963

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
uniform float uBlurSample;
uniform float uNormalStrength;
uniform vec2 uKernel2D;
uniform float uShadowBlurSample;
uniform bool uIgnore;
uniform float uBias;
uniform bool uRenderShadow;

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

uniform int uUseNormalMap; // static
vec3 getMappedNormal(vec2 uv)
{
    if (uUseNormalMap < 1)
        return normalize(vNormal);
    
    vec4 n = texture2D(uTextureNormal, uv).rgba;
    if (n.a < 0.01) return normalize(vNormal); // Fallback to vertex normal
    
    n.xy = n.xy * 2.0 - 1.0;
	n.z  = sqrt(1.0 - dot(n.xy, n.xy));
	//n.y *= -1.0;

	vec3 smoothNormal = normalize(mix(vec3(0.0, 0.0, 1.0), n.xyz, uNormalStrength));
	return normalize(vTBN * smoothNormal);
}

// Faster depth unpacking using bit manipulation emulation
float unpackDepth(vec4 enc)
{
    return dot(enc, vec4(
        1.0,
        1.0/255.0,
        1.0/65025.0,
        1.0/16581375.0
    ));
}

// Better hash function with less artifacts
float hash(vec2 c)
{
	return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
	(0.1 + abs(sin(13.0 * c.y + c.x))));
}

void getMaterial(out float roughness, out float metallic, out float emissive, out float F0, out float sss)
{
    vec4 matColor = texture2D(uTextureMaterial, vTexCoord);
    
    if (uMaterialFormat == 2) { // LabPBR
        metallic = step(0.898, matColor.g); // Metallic threshold
        F0 = mix(matColor.g, 1.0, metallic);
        sss = (matColor.b > 0.255) ? ((matColor.b - 0.255) * (1.0/0.745) * max(uSSS, uDefaultSubsurface)) : 0.0;
        roughness = pow(1.0 - matColor.r, 2.0); // Convert material color to linear roughness
		matColor.r = 1.0 - sqrt(roughness);		// Convert linear roughness to material color
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
    
    if (uIsSky > 0 || uIgnore) {
		if (!uIgnore)
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
        vec3 subsurfhightlight = vec3(0.0);
        
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
                // PCSS shadow calculation
				if (difMask > 0.0 && uRenderShadow)
				{
					vec2 shadowCoord = (vec2(vShadowCoord.x, -vShadowCoord.y) / vShadowCoord.w + 1.0) * 0.5;
				    if (shadowCoord.x > 0.0 && shadowCoord.y > 0.0 && shadowCoord.x < 1.0 && shadowCoord.y < 1.0) {
						float fragDepth = min(vShadowCoord.z, uLightFar);
				        float cosTheta = clamp(dot(normal, normalize(uLightPosition - vPosition)), 0.0, 1.0);
				        float bias = mix(1.6, uLightSize / 100.0 + 0.1, cosTheta) * uBias;
        
				        // PCSS parameters
				        float lightSizeUV = uLightSize * 0.01 * uKernel2D[1]; // Convert light size to UV space
						float searchWidth = lightSizeUV * (fragDepth - uLightNear) / fragDepth;
				        float blockerDistance = 0.0;
				        float numBlockers = 0.0;
        
				        // Blocker search
				        if (uLightSize > 0.1)
						{
				            float sumDepth = 0.0;
            
				            for (float i = 0.0; i < 64.0; i++) {
				                if (i > (uShadowBlurSample)) break;
								// Golden Sampling
								float r = sqrt(float(i)+0.5) / sqrt(float(uShadowBlurSample));
								float theta = float(i) * GOLDEN_ANGLE + uKernel2D[0];
								
								vec2 offset = vec2(cos(theta), sin(theta)) * r * searchWidth;
				                float sampleDepth = uLightNear + unpackDepth(texture2D(uDepthBuffer, shadowCoord + offset)) * (uLightFar - uLightNear);
                
				                if (sampleDepth < fragDepth - bias) {
				                    sumDepth += sampleDepth;
				                    numBlockers++;
				                }
				            }
            
				            if (numBlockers > 0.0) {
				                blockerDistance = sumDepth / numBlockers;
				            }
				        }
        
				        // Penumbra calculation
				        float penumbraWidth = 0.0;
				        if (numBlockers > 0.0) {
				            penumbraWidth = (fragDepth - blockerDistance) * lightSizeUV / blockerDistance / 2.0;
				        } else {
							penumbraWidth = lightSizeUV / 30.0;
						}
						
						// float penumbraWidth = lightSizeUV / 20.0;
						
				        // PCSS filtering
				        shadow = 0.0;
				        if (uLightSize > 0.1)
						{
				            for (float i = 0.0; i < 128.0; i++)
							{
				                if (i > uShadowBlurSample) break;
								// Golden Sampling
								float r = sqrt(float(i)+0.5) / sqrt(float(uShadowBlurSample));
								float theta = float(i) * GOLDEN_ANGLE + uKernel2D[0];

								vec2 offset = vec2(cos(theta), sin(theta)) * r * penumbraWidth;
				                float sampleDepth = uLightNear + unpackDepth(texture2D(uDepthBuffer, shadowCoord + offset)) * (uLightFar - uLightNear);
				                shadow += step(fragDepth - bias, sampleDepth);
                
				                // Subsurface scattering
						        if (uSSSHighQuality && sss > 0.001 && dif == 0.0)
								{
									vec3 rad, dis, falloff;
							
									// Subsurface
									if (uSSSStrength > 0.01)
									{
										rad = uSSSRadius * sss;
										dis = vec3((fragDepth + bias) - sampleDepth) / (mix((uLightColor.rgb), vec3(1.0), uSSSColorThreshold) * uLightStrength * rad);
						
										if ((fragDepth - (bias * 0.01)) <= sampleDepth)
											dis = vec3(0.0);
								
										// Sharpness
										falloff = pow(max(1.0 - pow(dis / rad, vec3(uSSSSharpness)), 0.0), vec3(uSSSSharpness * 0.5)); // adjust both terms

										subsurf += ((falloff / (pow(dis, vec3(2.0)) + 1.0) * att) * uSSSStrength);
										subsurf *= smoothstep(0.0, 0.5, sss);
									}
							
									// Subsurface Highlight
									if (uSSSHighlightStrength > 0.01)
									{
										// Normalize based on both highlight affectance and strength
										rad = uSSSRadius * sss * (1.0 - uSSSHighlight);
								
										// Color Threshold
										dis = vec3((fragDepth + bias) - sampleDepth) / (mix((uLightColor.rgb), vec3(1.0), uSSSHighlightColorThreshold) * uLightStrength * rad);
                
										if ((fragDepth - (bias * 0.01)) <= sampleDepth)
											dis = vec3(0.0);
                
										// Sharpness
										falloff = pow(max(1.0 - pow(dis / rad, vec3(uSSSHighlightSharpness)), 0.0), vec3(uSSSHighlightSharpness * 0.5)); // adjust both terms

										// Power by uSSSHighlightStrength
										subsurfhightlight += ((falloff / (pow(dis, vec3(2.0)) + 1.0) * att) * uSSSHighlightStrength);
									}
								}
				            }
				            shadow /= uShadowBlurSample;
							if (uSSSHighQuality && sss > 0.001 && dif == 0.0) {
					            subsurf /= uShadowBlurSample;
					            subsurfhightlight /= uShadowBlurSample;
							}
				        } else {
				            float sampleDepth = uLightNear + unpackDepth(texture2D(uDepthBuffer, shadowCoord)) * (uLightFar - uLightNear);
				            shadow = step(fragDepth - bias, sampleDepth);
				            
							// Subsurface scattering
						    if (sss > 0.001 && dif == 0.0)
							{
								vec3 rad, dis, falloff;
							
								// Subsurface
								if (uSSSStrength > 0.01)
								{
									rad = uSSSRadius * sss;
									dis = vec3((fragDepth + bias) - sampleDepth) / (mix((uLightColor.rgb), vec3(1.0), uSSSColorThreshold) * uLightStrength * rad);
						
									if ((fragDepth - (bias * 0.01)) <= sampleDepth)
										dis = vec3(0.0);
								
									// Sharpness
									falloff = pow(max(1.0 - pow(dis / rad, vec3(uSSSSharpness)), 0.0), vec3(uSSSSharpness * 0.5)); // adjust both terms

									subsurf += ((falloff / (pow(dis, vec3(2.0)) + 1.0) * att) * uSSSStrength);
									subsurf *= smoothstep(0.0, 0.5, sss);
								}
							
								// Subsurface Highlight
								if (uSSSHighlightStrength > 0.01)
								{
									// Normalize based on both highlight affectance and strength
									rad = uSSSRadius * sss * (1.0 - uSSSHighlight);
								
									// Color Threshold
									dis = vec3((fragDepth + bias) - sampleDepth) / (mix((uLightColor.rgb), vec3(1.0), uSSSHighlightColorThreshold) * uLightStrength * rad);
                
									if ((fragDepth - (bias * 0.01)) <= sampleDepth)
										dis = vec3(0.0);
                
									// Sharpness
									falloff = pow(max(1.0 - pow(dis / rad, vec3(uSSSHighlightSharpness)), 0.0), vec3(uSSSHighlightSharpness * 0.5)); // adjust both terms

									// Power by uSSSHighlightStrength
									subsurfhightlight += ((falloff / (pow(dis, vec3(2.0)) + 1.0) * att) * uSSSHighlightStrength);
								}
							}
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
			float absorption = CSPhase(dot(normalize(vPosition - uCameraPosition), normalize(uLightPosition - vPosition)), uAbsorption);
			
			subsurf *= absorption;
			subsurfhightlight *= absorption;
			
			// Mix both subsurface layers
			light += (mix(uLightColor.rgb, vec3(1.0), uSSSDesaturation) * uLightStrength * uSSSColor.rgb * transDif * subsurf * difMask * smoothstep(0.0, 0.05, (sss / 50.0)));
			light += (mix(uLightColor.rgb, vec3(1.0), uSSSHighlightDesaturation) * uLightStrength * uSSSColor.rgb * transDif * subsurfhightlight * difMask * smoothstep(0.0, 0.05, (sss / 50.0)));
			
			light *= mix(vec3(1.0), uSSSColor.rgb, clamp(sss / 75.0, 0.0, 1.0));
		}
        
        // Calculate specular highlights (PBR surface model)
		if (uLightSpecular > 0.0 && dif * shadow > 0.0)
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
				vec3 L = normalize(uLightPosition - vPosition);
				vec3 H = normalize(V + L);
				float distance = length(uLightPosition - vPosition);
				att			   = 1.0 / (distance * distance);
				vec3 radiance  = uLightColor.rgb * att;
					
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

		    spec = uLightColor.rgb * shadow * difMask * uLightSpecular * dif * (specular * mix(vec3(1.0), baseColor.rgb, metallic));
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
    
    if (baseColor.a == 0.0)
        discard;
}