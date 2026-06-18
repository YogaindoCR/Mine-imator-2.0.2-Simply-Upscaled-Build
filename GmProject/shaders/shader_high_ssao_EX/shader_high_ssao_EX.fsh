#define SAMPLES 512

varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;
uniform sampler2D uEmissiveBuffer;
uniform sampler2D uNoiseBuffer;
uniform sampler2D uMaskBuffer;

uniform float uNormalBufferScale;

uniform float uNear;
uniform float uFar;

uniform mat4 uProjMatrix;
uniform mat4 uProjMatrixInv;

uniform vec2 uScreenSize;
uniform float uNoiseSize;

uniform vec3 uKernel[SAMPLES];
uniform int uSampleStep;
uniform float uRadius;
uniform float uPower;
uniform float uRatio;
uniform float uRatioBalance;
uniform vec4 uColor;

uniform bool uPerformanceMode;

float unpackValue(vec4 c)
{
    return c.r + c.g * (1.0/255.0) + c.b * (1.0/65025.0);
}

float unpackDepth32(vec4 enc)
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

float transformDepth(float depth)
{
    return (uFar - (uNear * uFar) / (depth * (uFar - uNear) + uNear)) / (uFar - uNear);
}

vec3 posFromBuffer(vec2 coord, float depth)
{
    vec4 pos = uProjMatrixInv * vec4(coord.x * 2.0 - 1.0, 1.0 - coord.y * 2.0, transformDepth(depth), 1.0);
    return pos.xyz / pos.w;
}

vec3 unpackNormalBlueNoise(vec4 c)
{
    return normalize(vec3(c.r, c.g, c.b * 0.5));
}

float getSSAOstrength(vec2 uv)
{
    float emissive = unpackValue(texture2D(uEmissiveBuffer, uv)) * 255.0;
    float mask = 1.0;
	
	if (!uPerformanceMode)
		mask = texture2D(uMaskBuffer, uv).r;
		
    return (1.0 - clamp(emissive, 0.0, 1.0)) * mask;
}

void main()
{
    float depth = unpackDepth32(texture2D(uDepthBuffer, vTexCoord));
	
	// Perform depth test to ignore background
	if (depth == 0.0)
		discard;
		
    vec3 origin = posFromBuffer(vTexCoord, depth);
    vec3 normal = unpackNormal(texture2D(uNormalBuffer, vTexCoord));
    float sampleRadius = uRadius * (1.0 - depth);

    vec2 noiseScale = uScreenSize / uNoiseSize;
    vec3 randomVec = unpackNormalBlueNoise(texture2D(uNoiseBuffer, vTexCoord * noiseScale));

    vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 tbn = mat3(tangent, bitangent, normal);

    float occlusion = 0.0;
		// Pass 1
	    for (int i = 0; i < SAMPLES; i++)
		{
			if (i * 2 >= uSampleStep)
				break;
			
	        vec3 sampleVec = tbn * uKernel[i * 2];
	        vec3 samplePos = origin + sampleVec * (uRadius * uRatio);

	        vec4 projected = uProjMatrix * vec4(samplePos, 1.0);
	        vec2 sampleUV = projected.xy / projected.w * 0.5 + 0.5;
	        sampleUV.y = 1.0 - sampleUV.y;

	        if (sampleUV.x < 0.0 || sampleUV.x > 1.0 || sampleUV.y < 0.0 || sampleUV.y > 1.0)
	            continue;
				
	        float sampleDepth = unpackDepth32(texture2D(uDepthBuffer, sampleUV));
	        if (sampleDepth == 0.0)
	            continue;
				
	        vec3 sampleWorld = posFromBuffer(sampleUV, sampleDepth);
	        vec3 sampleNormal = unpackNormal(texture2D(uNormalBuffer, sampleUV));
	        float sampleStrength = getSSAOstrength(sampleUV);

	        float dist = length(sampleWorld - origin);
	        float bias = depth * 0.001;

	        float zDiff = sampleWorld.z - samplePos.z;
	        float depthHit = smoothstep(0.0001, 0.002, -zDiff - bias);
	        float rangeFalloff = 1.0 - clamp(dist / (uRadius * uRatio), 0.0, 1.0);
	        float normalFalloff = clamp(1.0 - dot(normal, sampleNormal), 0.0, 1.0);
			float angleCheck = clamp((1.0 - dot(sampleNormal, normal)) * 2.0, 0.0, 1.0);

	        occlusion += (1.0 - uRatioBalance) * depthHit * rangeFalloff * normalFalloff * angleCheck * sampleStrength;
	    
			// Pass 2
			
			sampleVec = tbn * uKernel[(i * 2) + 1];
			samplePos = origin + sampleVec * (uRadius);

	        projected = uProjMatrix * vec4(samplePos, 1.0);
	        sampleUV = projected.xy / projected.w * 0.5 + 0.5;
	        sampleUV.y = 1.0 - sampleUV.y;

	        if (sampleUV.x < 0.0 || sampleUV.x > 1.0 || sampleUV.y < 0.0 || sampleUV.y > 1.0)
	            continue;
				
	        sampleDepth = unpackDepth32(texture2D(uDepthBuffer, sampleUV));
	        if (sampleDepth == 0.0)
	            continue;

	        sampleWorld = posFromBuffer(sampleUV, sampleDepth);
	        sampleNormal = unpackNormal(texture2D(uNormalBuffer, sampleUV));
	        sampleStrength = getSSAOstrength(sampleUV);

	        dist = length(sampleWorld - origin);
	        bias = depth * 0.001;
	        zDiff = sampleWorld.z - samplePos.z;
	        depthHit = smoothstep(0.0001, 0.002, -zDiff - bias);
	        rangeFalloff = 1.0 - clamp(dist / (uRadius), 0.0, 1.0);
	        normalFalloff = clamp(1.0 - dot(normal, sampleNormal), 0.0, 1.0);
			
	        rangeFalloff = 1.0 - clamp(dist / uRadius, 0.0, 1.0);
	        normalFalloff = clamp(1.0 - dot(normal, sampleNormal), 0.0, 1.0);
			angleCheck = clamp((1.0 - dot(sampleNormal, normal)) * 2.0, 0.0, 1.0);

	        occlusion += uRatioBalance * depthHit * rangeFalloff * normalFalloff * angleCheck * sampleStrength;
		}
		
	// Raise to power
	occlusion = clamp(1.0 - pow(max(0.0, 1.0 - occlusion / float(uSampleStep)), uPower), 0.0, 1.0);
	
	// Apply strength
	occlusion *= getSSAOstrength(vTexCoord);
	occlusion = clamp(occlusion, 0.0, 1.0);
	
	// Mix
	gl_FragColor = mix(vec4(1.0), uColor, occlusion);
}