#define PI 3.14159265

varying vec2 vTexCoord;

uniform sampler2D uIndirectTex;
uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;

uniform vec2 uScreenSize;
uniform float uDepthSigma;
uniform float uNormalSigma;
uniform float uBilateralRadius;

uniform float uNormalBufferScale;

vec3 unpackNormal(vec4 c) {
    return (c.rgb / uNormalBufferScale) * 2.0 - 1.0;
}

float unpackDepth(vec4 c) {
    return dot(c.rgb, vec3(1.0, 1.0/255.0, 1.0/65025.0));
}

void main()
{
    vec2 texelSize = (1.0 / uScreenSize) * uBilateralRadius;
    vec3 centerColor = texture2D(uIndirectTex, vTexCoord).rgb;
    float centerDepth = unpackDepth(texture2D(uDepthBuffer, vTexCoord));
    vec3 centerNormal = unpackNormal(texture2D(uNormalBuffer, vTexCoord));

    vec3 finalColor = vec3(0.0);
    float totalWeight = 0.0;

    for (int y = -5; y <= 5; y++) {
        for (int x = -5; x <= 5; x++) {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            vec2 sampleCoord = vTexCoord + offset;

            if (sampleCoord.x < 0.0 || sampleCoord.y < 0.0 || sampleCoord.x > 1.0 || sampleCoord.y > 1.0)
                continue;
				
            vec3 sampleColor = texture2D(uIndirectTex, sampleCoord).rgb;
			
			// Black Color artifact fix
			if (length(sampleColor) == 0.0)
				continue;
			
            float sampleDepth = unpackDepth(texture2D(uDepthBuffer, sampleCoord));
			
			// Invalid depth fix
			if (sampleDepth <= 0.0001)
			    continue;
				
            vec3 sampleNormal = unpackNormal(texture2D(uNormalBuffer, sampleCoord));
			
			float depthDiff = abs(centerDepth - sampleDepth);
			
			if (depthDiff > 0.002) 
				continue;

            float spatialWeight = exp(-dot(offset, offset) / (uBilateralRadius));
            float depthWeight = exp(-pow(depthDiff, 2.0) * uDepthSigma);
            float normalWeight = exp(-1.0 * (1.0 - dot(centerNormal, sampleNormal)) * uNormalSigma);

            float weight = spatialWeight * depthWeight * normalWeight;
			
            finalColor += sampleColor * weight;
            totalWeight += weight;
        }
    }

    finalColor /= max(totalWeight, 0.0001);
    gl_FragColor = vec4(finalColor, 1.0);
}