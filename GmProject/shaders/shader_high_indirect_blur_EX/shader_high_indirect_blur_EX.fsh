#define DEPTH_SENSITIVITY 100.0 
#define SAMPLES 27
#define PI 3.14159265

varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;
uniform sampler2D uNoiseBuffer;
uniform vec2 uScreenSize;
uniform vec2 uPixelCheck;

uniform float uNormalBufferScale;
uniform float uNoiseSize;
uniform float uSamples;
uniform float uBlurSize2;

uniform float uRayStep;

float unpackDepth(vec4 c)
{
    return c.r + c.g * (1.0/255.0) + c.b * (1.0/65025.0);
}

vec3 unpackNormal(vec4 c)
{
    return (c.rgb / uNormalBufferScale) * 2.0 - 1.0;
}

void main()
{
    vec2 texelSize = 1.0 / (uScreenSize / 2.0);
    float centerDepth = unpackDepth(texture2D(uDepthBuffer, vTexCoord));
    vec3 centerNormal = unpackNormal(texture2D(uNormalBuffer, vTexCoord));

    float theta = texture2D(uNoiseBuffer, vTexCoord * (uScreenSize / uNoiseSize)).r * 2.0 * PI;
    float cosTheta = cos(theta);
    float sinTheta = sin(theta);

    vec2 taps[SAMPLES];
    taps[0] = vec2(-0.8835609, 2.523391);
    taps[1] = vec2(-1.387375, 1.056318);
    taps[2] = vec2(-2.854452, 1.313645);
    taps[3] = vec2(0.6326182, 1.14569);
    taps[4] = vec2(1.331515, 3.637297);
    taps[5] = vec2(-2.175307, 3.885795);
    taps[6] = vec2(-0.5396664, 4.1938);
    taps[7] = vec2(-0.6708734, -0.36875);
    taps[8] = vec2(-2.083908, -0.6921188);
    taps[9] = vec2(-3.219028, 2.85465);
    taps[10] = vec2(-1.863933, -2.742254);
    taps[11] = vec2(-4.125739, -1.283028);
    taps[12] = vec2(-3.376766, -2.81844);
    taps[13] = vec2(-3.974553, 0.5459405);
    taps[14] = vec2(3.102514, 1.717692);
    taps[15] = vec2(2.951887, 3.186624);
    taps[16] = vec2(1.33941, -0.166395);
    taps[17] = vec2(2.814727, -0.3216669);
    taps[18] = vec2(0.7786853, -2.235639);
    taps[19] = vec2(-0.7396695, -1.702466);
    taps[20] = vec2(0.4621856, -3.62525);
    taps[21] = vec2(4.181541, 0.5883132);
    taps[22] = vec2(4.22244, -1.11029);
    taps[23] = vec2(2.116917, -1.789436);
    taps[24] = vec2(1.915774, -3.425885);
    taps[25] = vec2(3.142686, -2.656329);
    taps[26] = vec2(-1.108632, -4.023479);

    float weight = 0.0;
    vec3 color = vec3(0.0);
	float RayStep = 0.0;
	
	//Prevent users from going above 128 so it doesn't crash their devices
	if (uRayStep > 128.0) {
		RayStep = 128.0;
	} else { 
		RayStep = clamp(uRayStep * (1.0 - centerDepth), 1.0, uRayStep); 
	}

    for (int i = 0; i < SAMPLES; i++) {
        // Normalize and rotate direction
        vec2 dir = normalize(taps[i]);
        float rx = dir.x * cosTheta - dir.y * sinTheta;
        float ry = dir.x * sinTheta + dir.y * cosTheta;
        vec2 rotatedDir = vec2(rx, ry);

        // Raymarching
        for (float step = 1.0; step <= RayStep; step++) {
			
            vec2 samplePos = vTexCoord + rotatedDir * texelSize * (step * uBlurSize2);

            if (samplePos.x < 0.0 || samplePos.y < 0.0 || samplePos.x > 1.0 || samplePos.y > 1.0)
                continue;

            vec3 sampleNormal = unpackNormal(texture2D(uNormalBuffer, samplePos));
            float sampleDepth = unpackDepth(texture2D(uDepthBuffer, samplePos));
            vec3 sampleColor = texture2D(gm_BaseTexture, samplePos).rgb;

            float sampleWeight = (max(0.0, dot(centerNormal, sampleNormal))) * (exp(-abs(centerDepth - sampleDepth) * DEPTH_SENSITIVITY));

            color += sampleColor * sampleWeight;
            weight += sampleWeight;
        }
    }

    if (weight > 0.0)
        color /= weight;

    // Brightness boost
    //color *= 10.0;

    gl_FragColor = vec4(color, 1.0);
}
