#define SAMPLES 8

varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;
uniform sampler2D uEmissiveBuffer;

uniform float uNormalBufferScale;
uniform float uNear;
uniform float uFar;

uniform mat4 uProjMatrixInv;

uniform float uRadius;
uniform float uPower;
uniform float uThresholdDepth;
uniform float uThresholdDepthFade;
uniform float uThresholdNormal;
uniform float uThresholdNormalFade;
uniform bool uOutlineNormal;
uniform vec4 uColor;
uniform vec2 uScreenSize;
uniform int uBlendMode;

// Helper functions from SSAO
float unpackValue(vec4 c) {
    return dot(c.rgb, vec3(1.0, 0.003921569, 0.00001538));
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

vec3 unpackNormal(vec4 c) {
    return (c.rgb / uNormalBufferScale) * 2.0 - 1.0;
}

float transformDepth(float depth) {
    return (uFar - (uNear * uFar) / (depth * (uFar - uNear) + uNear)) / (uFar - uNear);
}

vec3 posFromBuffer(vec2 coord, float depth) {
    vec4 pos = uProjMatrixInv * vec4(coord.x * 2.0 - 1.0, 1.0 - coord.y * 2.0, transformDepth(depth), 1.0);
    return pos.xyz / pos.w;
}

void main()
{
	// Base Color
	vec4 baseColor = texture2D(gm_BaseTexture, vTexCoord);
	float edge;
	float centerDepth = unpackDepth32(texture2D(uDepthBuffer, vTexCoord));
	
    // Skip background
    if (centerDepth != 0.0)
	{
	    // Base data
	    vec3 centerNormal = unpackNormal(texture2D(uNormalBuffer, vTexCoord));

	    // Edge accumulation
	    float edgeDepth = 0.0;
	    float edgeNormal = 0.0;
	    float sampleCount = 0.0;
	
		// Texel Normalized on Height
		vec2 texel = 1.0 / (uScreenSize / uScreenSize.y);

	    // Sample offsets for edge detection
	    vec2 offsets[8];
	    offsets[0] = vec2(-1.0, -1.0);
	    offsets[1] = vec2( 0.0, -1.0);
	    offsets[2] = vec2( 1.0, -1.0);
	    offsets[3] = vec2(-1.0,  0.0);
	    offsets[4] = vec2( 1.0,  0.0);
	    offsets[5] = vec2(-1.0,  1.0);
	    offsets[6] = vec2( 0.0,  1.0);
	    offsets[7] = vec2( 1.0,  1.0);

	    for (int i = 0; i < 8; i++)
	    {
	        vec2 uv = vTexCoord + offsets[i] * 0.001 * uRadius * texel;

	        float d = transformDepth(unpackDepth32(texture2D(uDepthBuffer, uv)));
			float centerD = transformDepth(centerDepth);
			vec3 n = unpackNormal(texture2D(uNormalBuffer, uv));
			float depthDiff = abs(d - centerD);
	        float normalDiff = 1.0 - dot(n, centerNormal);

	        // Accumulate both depth and normal contrast
	        edgeDepth += smoothstep(uThresholdDepth, uThresholdDepth + uThresholdDepthFade, depthDiff); //threshold + falloff
	        if (uOutlineNormal)
				edgeNormal += smoothstep(uThresholdNormal, uThresholdNormal + uThresholdNormalFade, normalDiff);
        
			sampleCount += 1.0;
	    }

	    // Normalize
	    edgeDepth /= sampleCount;
		if (uOutlineNormal)
			edgeNormal /= sampleCount;

	    // Combined edge intensity
	    edge = clamp((edgeDepth + edgeNormal) * uPower, 0.0, 1.0);
	
	    // Apply emissive/mask influence (reuse from SSAO)
	    float emissive = unpackDepth32(texture2D(uEmissiveBuffer, vTexCoord)) * 255.0;
	    float strength = 1.0 - clamp(emissive, 0.0, 1.0);

	    edge *= strength;
	
		// Fade on distance
		float distFade = smoothstep(uNear, uFar, centerDepth) / uFar;
	    edge *= (1.0 - distFade);
		
		// Fade when close to camera Fix
		float linearDepth = transformDepth(centerDepth * 0.225);
		float fadeNear = smoothstep(0.5, 1.0, linearDepth);
		edge *= fadeNear;
	} else {
		edge = 0.0;
	}
	vec3 screenColor;
	vec3 blend = uColor.rgb;

	// NORMAL
	if (uBlendMode == 0) {
	    screenColor = blend;
	}

	// ADDITION
	if (uBlendMode == 1) {
	    screenColor = baseColor.rgb + mix(vec3(0.0), blend, edge);
	}

	// SCREEN
	if (uBlendMode == 2) {
	    screenColor = 1.0 - (1.0 - baseColor.rgb) * (1.0 - blend);
	}

	// MULTIPLY
	if (uBlendMode == 3) {
	    screenColor = baseColor.rgb * blend;
	}

	// OVERLAY
	if (uBlendMode == 4) {
	    screenColor = mix(
	        2.0 * baseColor.rgb * blend,
	        1.0 - 2.0 * (1.0 - baseColor.rgb) * (1.0 - blend),
	        step(0.5, baseColor.rgb)
	    );
	}

	// FINAL MIX WITH EDGE
	vec3 finalColor = mix(baseColor.rgb, screenColor, edge);

    // Final toon outline color
    gl_FragColor = vec4(finalColor, baseColor.a);
}