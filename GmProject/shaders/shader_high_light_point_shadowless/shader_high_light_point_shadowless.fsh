#define PI 3.14159265

uniform sampler2D uTexture; // static
uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static

uniform int uIsSky;
uniform int uLightAmount; // static
uniform vec4 uLightData[128]; // static
uniform int uIsWater;
uniform vec3 uCameraPosition; // static
uniform int uMaterialFormat;
uniform float uMetallic;
uniform float uRoughness;
uniform float uEmissive;
uniform float uSSS;
uniform float uDefaultSubsurface;
uniform float uDefaultEmissive;
uniform float uLightSpecular;
uniform int uIgnoreInt;

uniform vec4 uLightColor; // static

uniform float uSampleIndex;
uniform int uAlphaHash;

varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vTangent;
varying mat3 vTBN;
varying vec4 vColor;
varying vec2 vTexCoord;
varying vec4 vCustom;

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

// Improved noise functions
float hash(vec2 c)
{
	return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
	(0.1 + abs(sin(13.0 * c.y + c.x))));
}

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
		return vec3(vTBN[2][0], vTBN[2][1], vTBN[2][2]);
	
	vec4 n = texture2D(uTextureNormal, uv).rgba;
	n.rgba = (n.a < 0.01 ? vec4(.5, .5, 0.0, 1.0) : n.rgba); // No normal?
	n.xy = n.xy * 2.0 - 1.0; // Decode
	n.z  = sqrt(1.0 - dot(n.xy, n.xy)); // Reconstruct Z
	n.y *= -1.0; // Convert Y- to Y+
	return normalize(vTBN * n.xyz);
}

void getMaterial(out float roughness, out float metallic, out float emissive, out float F0, out float sss)
{
	vec4 matColor = texture2D(uTextureMaterial, vTexCoord);
	
	if (uMaterialFormat == 2) // LabPBR
	{
		if (matColor.g > 0.898) // Metallic
		{
			metallic = 1.0; F0 = 1.0; sss = 0.0;
		}
		else // Non-metallic
		{
			metallic = 0.0; F0 = matColor.g;
			sss = (matColor.b > 0.255 ? (((matColor.b - 0.255) / 0.745) * max(uSSS, uDefaultSubsurface)) : 0.0);
		}
		
		// Convert material color to linear roughness
		roughness = pow(1.0 - matColor.r, 2.0);
		
		// Convert linear roughness to material color
		matColor.r = 1.0 - sqrt(roughness);
		
		emissive = (matColor.a < 1.0 ? matColor.a /= 0.9961 : 0.0) * uDefaultEmissive;
		
		return;
	}
	
	if (uMaterialFormat == 1) // SEUS
	{
		roughness = (1.0 - matColor.r);
		metallic = matColor.g;
		emissive = (matColor.b * uDefaultEmissive);
	}
	else // No map
	{
		roughness = uRoughness;
		metallic = uMetallic;
		emissive = max(uEmissive, vCustom.z * uDefaultEmissive);
	}
	
	F0 = mix(0.0, 1.0, metallic);
	sss = max(uSSS, vCustom.w * uDefaultSubsurface);
}

void main()
{
	vec2 tex = vTexCoord;
	vec4 baseColor = vColor * texture2D(uTexture, tex); // Get base
	
	vec3 lightResult = vec3(0.0);
	vec3 specResult = vec3(0.0);
	
	if (baseColor.a == 0.0)
		discard;
		
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
		lightResult = vec3(0.0);
		specResult = vec3(0.0);
	}
	else
	{
		// Get material data
		float roughness, metallic, emissive, F0, sss;
		getMaterial(roughness, metallic, emissive, F0, sss);
		vec3 normal = getMappedNormal(vTexCoord);
		
		for (int i = 0; i < uLightAmount; i++)
		{
			vec4 data1 = uLightData[i * 3];
			vec4 data2 = uLightData[i * 3 + 1];
			vec4 data3 = uLightData[i * 3 + 2];
			vec3 lightPosition = data1.xyz;
			float lightRange = data1.w;
			float lightFadeSize = data2.w;
			
			// No use in shading a pixel if it's not in range
			if (distance(vPosition, lightPosition) > lightRange)
				continue;
				
			float isignored;
			
			// Light linking
			if (int(data3.b) != -1)
				isignored = float((int(data3.b) == uIgnoreInt));
			else
				isignored = 1.0;
			
			if (isignored == 1.0)
			{
				// Diffuse factor
				float dif = max(0.0, dot(normal, normalize(lightPosition - vPosition)));
			
				// Attenuation factor
				float att = 1.0 - clamp((distance(vPosition, lightPosition) - lightRange * (1.0 - lightFadeSize)) / (lightRange * lightFadeSize), 0.0, 1.0);
				dif *= att;
			
				vec3 light = vec3(0.0);
				vec3 spec = vec3(0.0);
				
				// Diffuse light
				light = data2.rgb * data3.r * dif;
			
				lightResult.rgb += light;
			
				// Calculate specular highlights (PBR surface model)
				//
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
					vec3 L = normalize(lightPosition - vPosition);
					vec3 H = normalize(V + L);
					float distance = length(lightPosition - vPosition);
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
			
				spec = data2.rgb * specular * mix(vec3(1.0), baseColor.rgb * vColor.rgb, metallic) * data3.g * uLightSpecular * dif;
				specResult.rgb += spec;
			}
		}
	}
	
	// Add an ambient term to the direct lighting result Lo
	vec3 ambient = vec3(0.03) * emissive * ao;
	vec3 color = ambient + Lo;
	
	// Tone map the HDR color using the Reinhard operator
	color = color / (color + vec3(1.0));
	color = pow(color, vec3(1.0/2.2));
	
	// Final output
	gl_FragData[0] = vec4(lightResult, baseColor.a);
	gl_FragData[1] = vec4(specResult, baseColor.a);
}

