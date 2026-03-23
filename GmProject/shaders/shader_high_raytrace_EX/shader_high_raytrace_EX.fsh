#define PI 3.14159265
#define up vec3(0.0, 0.0, 1.0)
#define RAY_SPECULAR 0
#define RAY_DIFFUSE 1

varying vec2 vTexCoord;

// Buffers
uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;
uniform sampler2D uNoiseBuffer;

// Material for reflections, emissive for indirect
uniform sampler2D uMaterialBuffer;

// Specular tint for reflections, diffuse for indirect
uniform sampler2D uDiffuseBuffer;

// Scene color for reflections, shadows for indirect
uniform sampler2D uDataBuffer;

// Reflection Probe Texture 2D
uniform sampler2D uReflectionProbeBuffer;

uniform float uNormalBufferScale;

// Scene data
uniform vec4 uSkyColor;
uniform vec4 uFogColor;

// Camera data
uniform mat4 uProjMatrix;
uniform mat4 uProjMatrixInv;
uniform mat4 uViewMatrixInv;
uniform float uNear;
uniform float uFar;
uniform vec2 uScreenSize;
uniform vec3 uCameraPosition;

uniform float uPrecision;
uniform float uThickness;
uniform float uNoiseSize;

uniform int uRayType;
uniform int uReflectionProbe;
uniform float uRayDistance;
uniform float uReflectionProbeRot;
uniform float uReflectionProbeStrength;

// Reflections
uniform float uFadeAmount;
uniform float uGamma;

// Indirect
uniform float uIndirectStength;

uniform float uSampleIndex;

// Unpacks depth value from packed color
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

// Transforms Z depth with camera data
float transformDepth(float depth)
{
	return (uFar - (uNear * uFar) / (depth * (uFar - uNear) + uNear)) / (uFar - uNear);
}

// Reconstruct a position from a screen space coordinate and (linear) depth
vec3 posFromBuffer(vec2 coord, float depth)
{
	vec4 pos = uProjMatrixInv * vec4(coord.x * 2.0 - 1.0, 1.0 - coord.y * 2.0, transformDepth(depth), 1.0);
	return pos.xyz / pos.w;
}

// Get Normal Value
vec3 unpackNormal(vec4 c)
{
	return (c.rgb / uNormalBufferScale) * 2.0 - 1.0;
}

vec2 viewPosToPixel(vec3 viewPos)
{
	vec4 coord	= (uProjMatrix * vec4(viewPos, 1.0));
	coord.xy	= (coord.xy / coord.w) * 0.5 + 0.5;
	coord.y		= 1.0 - coord.y;
	coord.xy	*= uScreenSize;
	
	return floor(coord.xy);
}

vec2 viewPosToUv(vec3 viewPos)
{
	vec4 coord	= (uProjMatrix * vec4(viewPos, 1.0));
	coord.xy	= (coord.xy / coord.w) * 0.5 + 0.5;
	coord.y		= 1.0 - coord.y;
	return coord.xy;
}

vec3 unpackNormalBlueNoise(vec4 c)
{
	return normalize(vec3(cos(c.r * 2.0 * PI), sin(c.r * 2.0 * PI), c.g));
}

// GGX importance sampling (https://learnopengl.com/PBR/IBL/Specular-IBL)
float VanDerCorput(int n, int base)
{
    float invBase = 1.0 / float(base);
    float factor  = invBase;
    float result  = 0.0;

    for (int i = 0; i < 16; i++)
    {
        if (n <= 0) break;

        int digit = int(mod(float(n), float(base)));
        result += float(digit) * factor;

        n = int(float(n) / float(base));
        factor /= float(base);
    }

    return result;
}



vec2 Hammersley(int i, int N)
{
	return vec2(float(i)/float(N), VanDerCorput(i, 2));
}

vec3 sampleGGX(vec2 Xi, float roughness)
{
	float a = roughness * roughness;
	float phi = 2.0 * PI * Xi.x;
	float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a * a - 1.0) * Xi.y));
	float sinTheta = sqrt(1.0 - cosTheta * cosTheta);
	
	return vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
}

float percent(float xx, float start, float end)
{
	return clamp((xx - start) / (end - start), 0.0, 1.0);
}


vec3 sampleReflectionProbe(vec3 dir)
{
    // Convert view-space direction to world-space direction (vec4 with w=0)
    vec3 worldDir = normalize((uViewMatrixInv * vec4(normalize(dir), 0.0)).xyz);
	vec3 d = worldDir;

	// rotate 90 degrees around X-axis
	float t = d.y;
	d.y = d.z;
	d.z =  -t;

	// now use rotated direction
	float u = 0.5 + atan(d.z, d.x) / (2.0 * PI)
	        + (radians(-uReflectionProbeRot) / (2.0 * PI));
	u = 1.0 - u; // flip x
	
	float v = 0.5 - asin(clamp(d.y, -1.0, 1.0)) / PI;

    // sample the 2D probe (wrap/edge handling depends on texture sampler settings)
    return texture2D(uReflectionProbeBuffer, vec2(u, v)).rgb;
}


vec3 rayTrace(vec3 rayStart, vec3 rayDir, float rayThickness, vec3 noise)
{
	// Ray data
	vec3 rayEnd	= rayStart.xyz + rayDir * uRayDistance;
	
	// Clip to near camera plane
	if (rayEnd.z < uNear)
		rayEnd.xyz	= rayStart.xyz + (rayDir * (rayStart.z - uNear));
	
	vec2 rayPx, rayPxStart, rayPxEnd, rayPxDis, rayUv, rayUvStart;
	rayPxStart	= viewPosToPixel(rayStart);
	rayPxEnd	= viewPosToPixel(rayEnd);
	rayPxDis	= rayPxEnd - rayPxStart;
	rayUvStart	= rayPxStart / uScreenSize;
	float thickness = rayThickness;
	
	// Get pixel data for line tracing, swizzel to keep longest axis in X
	bool rayHit	= false;
	bool rayVertical	= (abs(rayPxDis.y) > abs(rayPxDis.x));
	
	if (rayVertical)
	{
		rayPxStart	= rayPxStart.yx;
		rayPxDis	= rayPxDis.yx;
	}
	
	vec2 stepPx = rayPxDis / max(abs(rayPxDis.x), 0.001);
	
	// Correct swizzel, UV coords needs to be correct
	vec2 uvStep = ((rayVertical ? stepPx.yx : stepPx.xy) / uScreenSize);
	
	float progress, progressPrev, p;
	float rayZ, sampleZ, delta, deltaPrev;
	float sampleDepth;
	progress = 1.001;
	p = progress;
	
	float i = 0.0;
	float steps = 256.0 * (uScreenSize[1] / 460.0 + uPrecision); // Gradually increase max steps
	float stepscount = 0.0;
	float precisionJitter = (uRayType == RAY_SPECULAR ? 1.0 : noise.g);
	float ScreenScale = 0.5 + uScreenSize[1] / 720.0;
	for (; i < steps; i += 1.0)
	{
		// Get previous progress for refining later
		progressPrev	= progress;
		deltaPrev		= delta;
		
		float stride	= ScreenScale + ((i * (1.0 - uPrecision)) * precisionJitter);
		progress		= p + (stride * noise.r);
		p				+= stride;
		
		// Move forward
		rayUv	= rayUvStart + (uvStep * progress);
		
		if (rayUv.x < 0.0 || rayUv.y < 0.0 || rayUv.x > 1.0 || rayUv.y > 1.0)
			break;
		
		sampleDepth = unpackDepth32(texture2D(uDepthBuffer, rayUv));
		
		if (sampleDepth == 0.0)
			continue;
		
		// Get ray/scene depth
		float progressPx = (stepPx.x * progress) / rayPxDis.x;
		
		// Past end point
		if (progressPx > 1.0)
			break;
		
		rayZ		= (rayStart.z * rayEnd.z) / mix(rayEnd.z, rayStart.z, progressPx);
		sampleZ		= posFromBuffer(rayUv, sampleDepth).z;
		thickness	= rayThickness * max(1.0, pow(sampleDepth, 5.0) * 1500.0);
		
		// Distance between ray Z and object Z
		delta	= sampleZ - rayZ;
		
		// Negative depth, check for collision
		rayHit	= (delta < 0.0);
		rayHit	= rayHit && ((delta > -thickness) || abs(delta) < abs(rayDir.z * stride * 2.0));
		
		if (rayHit || (rayZ - rayStart.z > uRayDistance))
			break;
		
		stepscount++;
	}
	
	// Prevent backface hit
	rayHit = rayHit && (deltaPrev > 0.0);
	
	// Depth check
	if (!rayHit || sampleDepth < 0.001)
		return vec3(-1.0, -1.0, stepscount);
	
	// Refine
	progress = mix(progressPrev, progress, clamp(deltaPrev / (deltaPrev - delta), 0.0, 1.0));
	rayUv = rayUvStart + (uvStep * progress);
	
	return vec3(rayUv, stepscount);
}

void main()
{
	// Depth quick exit
	float depth		= unpackDepth32(texture2D(uDepthBuffer, vTexCoord));
	
	// Sample material (Specular only)
	vec3 materialData = vec3(0.0);
	if (uRayType == RAY_SPECULAR)
		materialData = texture2D(uMaterialBuffer, vTexCoord).rgb;
	
	vec3 normal = vec3(0.0);
	vec3 rayDir = vec3(0.0);
	
	vec3 rayCoord = vec3(-1.0);
	
	// Don't calculate ray if depth isn't valid
	if (!(depth == 0.0 || depth > 0.9999999 || materialData.r > 0.95))
	{
		// Sample buffers
		normal	= unpackNormal(texture2D(uNormalBuffer, vTexCoord));
		vec4 noise	= texture2D(uNoiseBuffer, vTexCoord * (uScreenSize / uNoiseSize));
	
		// Calculate ray direction
		vec3 rayPos	 = posFromBuffer(vTexCoord, depth);
		vec3 tangent = normalize(up - normal * dot(up, normal));
		mat3 mat	 = mat3(tangent, cross(normal, tangent), normal);
		
		// Specular (GGX)
		if (uRayType == RAY_SPECULAR)
		{
			for (int i = 0; i < 4; i++)
			{
				vec2 Xi = Hammersley(int(256.0 + ((noise.r - .5) * 256.0)) + i, 512);
				vec3 H  = normalize(mat * sampleGGX(Xi, materialData.r));
				rayDir = reflect(normalize(rayPos), H);
			
				if (dot(normal, rayDir) > 0.0)
					break;
			}
		}
		else // Diffuse
			rayDir = normalize(mat * unpackNormalBlueNoise(noise));
	
		// Ray thickness (Increase based on steepness of ray)
		float rayThickness = uThickness * max(1.0, pow(1.0 - abs(max(0.0, dot(rayDir, normal))), 7.0) * 100.0);
		
		if (rayDir.z < 0.2)
			rayThickness *= 6.0;
		
		// Ray trace
		rayCoord = rayTrace(rayPos, rayDir, rayThickness, noise.rgb);
	}
	
	vec3 rayColor = uSkyColor.rgb;
	vec3 hitNormal = vec3(0.0);
	
	if (rayCoord.x > 0.0)
	{
		hitNormal = unpackNormal(texture2D(uNormalBuffer, rayCoord.xy));
		
		if (dot(hitNormal, normal) > 0.5)
			rayCoord.x = -1.0;
	}
	
	// Specular
	if (uRayType == RAY_SPECULAR)
	{
		// Fade by edge
		float vis = (rayCoord.x > 0.0 ? 1.0 : 0.0);
		
		if (rayCoord.x > 0.0)
		{
			vec2 fadeUV = smoothstep(0.2, 0.6, abs(vec2(0.5, 0.5) - rayCoord.xy)) * uFadeAmount;
			vis *= clamp(1.0 - (fadeUV.x + fadeUV.y), 0.0, 1.0);
			
			// Fade if roughness is too high
			vis *= 1.0 - percent(materialData.r, .85, .97);
			vis = clamp(vis * 1.5, 0.0, 1.0);
			
			rayColor = texture2D(uDataBuffer, rayCoord.xy).rgb;
		}
		
		// Get color
        // If the ray missed (vis==0) then choose between sky or reflection probe
		vec3 envColor = pow(uSkyColor.rgb, vec3(uGamma)); // default env color
		
		// if reflection probe is enabled (>1) sample spherical map using rayDir
		if (vis <= 0.0 && uReflectionProbe > 0)
		{
			// sample probe using the outgoing reflection direction (rayDir)
			vec3 probeCol = sampleReflectionProbe(rayDir) * uReflectionProbeStrength;
			// apply gamma to probe to match how sky was handled (keeps appearance consistent)
			envColor = pow(probeCol, vec3(uGamma));
		}
		
		// Mix env (sky or probe) with hit color based on visibility
		rayColor = mix(envColor, rayColor, vis);
		
		// Specular tint from mettalic
		if (materialData.g > 0.0)
			rayColor *= mix(vec3(1.0), texture2D(uDiffuseBuffer, vTexCoord).rgb, materialData.g);
		
		// Multiply by fresnel
		rayColor *= materialData.b;
		
		gl_FragColor = vec4(rayColor, 1.0);
	}
	else // Diffuse
	{
		vec3 light = vec3(0.0);		
		
		if (rayCoord.x > 0.0)
		{
			// Get direct light and emissive
			light = (texture2D(uDataBuffer, rayCoord.xy).rgb + (unpackValue(texture2D(uMaterialBuffer, rayCoord.xy)) * 255.0)) * uIndirectStength;
			
			// Diffuse tint
			light *= texture2D(uDiffuseBuffer, rayCoord.xy).rgb;
			
			// Multiply by diffuse & strength
			light *= max(0.0, dot(-hitNormal, rayDir));
		}
		
		gl_FragColor = vec4(light, 1.0);
	}
	
	// Debug XY hit coords(RG) and steps(B)
	//if (vTexCoord.x < 0.0)
	//	gl_FragColor = vec4(rayCoord.xy, rayCoord.z/256.0, 1.0);
}
