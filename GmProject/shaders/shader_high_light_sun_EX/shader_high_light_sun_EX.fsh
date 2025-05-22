#define PI 3.14159265
#define NUM_CASCADES 3
#define SHADOW_SAMPLES 16

// Grouped uniforms by frequency of use
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
uniform float uLightSize;

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


float fresnelSchlickRoughness(float cosTheta, float F0, float roughness)
{
    return F0 + (max((1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float distributionGGX(vec3 N, vec3 H, float roughness)
{
    float a2 = roughness * roughness;
    a2 *= a2; // roughness
    float NdotH = max(dot(N, H), 0.0);
    float denom = NdotH * NdotH * (a2 - 1.0) + 1.0;
    return a2 / (PI * denom * denom);
}

float geometrySchlickGGX(float NdotV, float roughness)
{
    float r = roughness + 1.0;
    float k = (r * r) * 0.125;
    return NdotV / (NdotV * (1.0 - k) + k);
}

float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    return geometrySchlickGGX(max(dot(N, V), 0.0), roughness) *
           geometrySchlickGGX(max(dot(N, L), 0.0), roughness);
}

float unpackDepth(vec4 c)
{
    return c.r + c.g * (1.0/255.0) + c.b * (1.0/65025.0);
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

uniform int uUseNormalMap; // static
vec3 getMappedNormal(vec2 uv)
{
    if (uUseNormalMap < 1) 
		return normalize(vTBN[2]);
    
    vec4 n = texture2D(uTextureNormal, uv);
    n = (n.a < 0.01) ? vec4(0.5, 0.5, 0.0, 1.0) : n; // Fallback normal
    vec3 normal = vec3(n.xy * 2.0 - 1.0, 0.0);
    normal.z = sqrt(max(0.0, 1.0 - dot(normal.xy, normal.xy)));
    normal.y *= -1.0;
    return normalize(vTBN * normal);
}

float hash(vec2 c)
{
    return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) * (0.1 + abs(sin(13.0 * c.y + c.x))));
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
        roughness = (1.0 - matColor.r) * (1.0 - matColor.r);
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

float calculateShadow(int cascade, vec2 coord, float fragDepth, float bias)
{
    float result;
    float shadow = 0.0;

    if (uLightSize > 0.02) {
        // Apply blur based on cascade level (farther cascades get more blur)
        float blurAmount = uLightSize * (uLightSize / 2.0) * (0.01 + float(cascade) * 0.001);
        float samples = 0.0;

        // Poisson disk samples for soft shadows
        vec2 poissonDisk[16];
        poissonDisk[0]  = vec2(-0.94201624, -0.39906216);
        poissonDisk[1]  = vec2(-0.6961816,   0.45697793);
        poissonDisk[2]  = vec2(-0.20310713,  0.42402853);
        poissonDisk[3]  = vec2( 0.96234106, -0.1949834);
        poissonDisk[4]  = vec2( 0.47343425, -0.4800269);
        poissonDisk[5]  = vec2( 0.519456,    0.7670221);
        poissonDisk[6]  = vec2( 0.18546124, -0.8931231);
        poissonDisk[7]  = vec2( 0.5074318,   0.0644256);
        poissonDisk[8]  = vec2( 0.89642,     0.4124583);
        poissonDisk[9]  = vec2(-0.3219406,  -0.9326146);
        poissonDisk[10] = vec2(-0.791559,   -0.597705);
        poissonDisk[11] = vec2(-0.5463055,   0.7622272);
        poissonDisk[12] = vec2(-0.4621936,  -0.283806);
        poissonDisk[13] = vec2( 0.4144426,   0.1581487);
        poissonDisk[14] = vec2( 0.1342776,   0.6742424);
        poissonDisk[15] = vec2(-0.9083806,   0.0433386);

        for (int i = 0; i < SHADOW_SAMPLES; i++) {
            vec2 sampleCoord = coord + poissonDisk[i] * blurAmount;

            if (sampleCoord.x >= 0.0 && sampleCoord.y >= 0.0) {
                float sampleDepth = mix(
                    uSunNear[cascade], 
                    uSunFar[cascade], 
                    unpackDepth(cascadeDepthBuffer(cascade, sampleCoord))
                );

                shadow += (fragDepth - bias) > sampleDepth ? 0.0 : 1.0;
                samples += 1.0;
            }
        }

        // Fallback for samples outside the shadow map
        result = (samples == 0.0) ? 1.0 : shadow / samples;

    } else {
        if (coord.x >= 0.0 && coord.y >= 0.0) {
            float sampleDepth = mix(
                uSunNear[cascade], 
                uSunFar[cascade], 
                unpackDepth(cascadeDepthBuffer(cascade, coord))
            );

            shadow += (fragDepth - bias) > sampleDepth ? 0.0 : 1.0;
        }

        result = shadow;
    }

    return result;
}

void main()
{
    vec2 tex = vTexCoord;
    vec4 baseColor = texture2D(uTexture, tex) * vColor;
    
    // Early alpha test
    if (uAlphaHash > 0 && baseColor.a < hash(vec2(hash(vPosition.xy + (uSampleIndex * (1.0/255.0))), vPosition.z + (uSampleIndex * (1.0/255.0)))))
	{
      discard;
	}
	
	vec3 light, spec;
    
    if (uIsSky > 0)
	{
		light = vec3(0.0);
		spec = vec3(uLightSpecular);
    }
	else
	{
	    // Get material data
	    float roughness, metallic, emissive, F0, sss;
	    getMaterial(roughness, metallic, emissive, F0, sss);
    
	    vec3 normal = getMappedNormal(tex);
	    float dif = max(dot(normal, uLightDirection), 0.0);
    
	    vec3 shadow = vec3(1.0);
	    vec3 subsurf = vec3(0.0);
    
	    if (dif > 0.0 || sss > 0.0)
		{
	        // Find cascade using binary search pattern
	        int i;
			if (vClipSpaceDepth < uCascadeEndClipSpace[1]) {
			    if (vClipSpaceDepth < uCascadeEndClipSpace[0]) {
			        i = 0;
			    } else {
			        i = 1;
			    }
			} else {
			    i = 2;
			}
        
	        float fragDepth = vScreenCoord[i].z;
	        vec2 fragCoord = vScreenCoord[i].xy;
        
	        if (fragCoord.x >= 0.0 && fragCoord.y >= 0.0 && fragCoord.x <= 1.0 && fragCoord.y <= 1.0)
			{
			    fragDepth = mix(uSunNear[i], uSunFar[i], fragDepth);
			    float bias = max(0.01 * (1.0 - dot(normal, normalize(uLightDirection - vPosition))), 0.6);
            
	            // Use the new soft shadow calculation
	            shadow = vec3(calculateShadow(i, fragCoord, fragDepth, bias));
            
	            if (sss > 0.0 && dif == 0.0)
				{
					float sampleDepth = mix(uSunNear[i], uSunFar[i], unpackDepth(cascadeDepthBuffer(i, fragCoord)));
					vec3 rad = uSSSRadius * sss;
					vec3 dis = vec3((fragDepth + bias) - sampleDepth) / (uLightColor.rgb * uLightStrength * rad);
					
					if ((fragDepth - (bias * 0.01)) <= sampleDepth)
						dis = vec3(0.0);
					
					subsurf = pow(max(1.0 - pow(dis / rad, vec3(4.0)), 0.0), vec3(2.0)) / (pow(dis, vec3(2.0)) + 1.0);
					subsurf *= smoothstep(0.0, 1.0, (sss / 5.0));
				}
	        }
	    }
    
	    // Diffuse light
	    light = uLightColor.rgb * (uLightStrength * dif * shadow);
    
	    // Subsurface scattering
	    if (sss > 0.0)
		{
			float transDif = max(0.0, dot(normalize(-normal), uLightDirection));
			subsurf += (subsurf * uSSSHighlightStrength * CSPhase(dot(normalize(vPosition - uCameraPosition), uLightDirection), uSSSHighlight));
			light += uLightColor.rgb * uLightStrength * uSSSColor.rgb * transDif * subsurf;
			light *= mix(vec3(1.0), uSSSColor.rgb, clamp(sss / 75.0, 0.0, 1.0));
		}
		
	    // Specular
	    spec = vec3(0.0);
	    if (uLightSpecular * dif * shadow.r > 0.0)
		{
	        vec3 V = normalize(uCameraPosition - vPosition);
	        vec3 H = normalize(V + uLightDirection);
	        float NDF = distributionGGX(normal, H, roughness);
	        float G = geometrySmith(normal, V, uLightDirection, roughness);
	        float F = fresnelSchlickRoughness(max(dot(H, V), 0.0), F0, roughness);
        
	        float denominator = 4.0 * max(dot(normal, V), 0.0) * max(dot(normal, uLightDirection), 0.0) + 0.0001;
	        spec = uLightColor.rgb * (uLightSpecular * dif * shadow) * (NDF * G * F / denominator) * mix(vec3(1.0), baseColor.rgb, metallic);
	    }
	}
	
    //final color
	
    gl_FragData[0] = vec4(light, baseColor.a);
    gl_FragData[1] = vec4(spec, baseColor.a);
    
    if (baseColor.a == 0.0) 
	{
		discard;
	}
}
