#define SAMPLES 128

uniform sampler2D uMaskRaysTexture; // static

uniform vec3 uLightDirection; // static
uniform vec3 uCameraPosition; // static
uniform vec3 uRayColor; // static

uniform float uKernelGodRay;
uniform float uStrength;
uniform float uDensity;
uniform int uStep;

uniform mat4 uViewMatrix;

varying vec2 vTexCoord;

float dither(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{
	vec3 sunDir = normalize(uLightDirection);

	// Put fake sun very far away from camera
	vec3 sunWorldPos = uCameraPosition + sunDir * 100000.0;

	// Project to clip space
	vec4 clip = uViewMatrix * vec4(sunWorldPos, 1.0);

	// NDC
	vec3 ndc = clip.xyz / clip.w;

	// Convert to UV
	vec2 sunUV = ndc.xy * vec2(0.5, -0.5) + 0.5;
	
	vec2 dir = normalize(sunUV - vTexCoord);
	float rayLength = length(sunUV - vTexCoord);
	
	float density = uDensity;
	float weight = uStrength;
		
	float stepnormalize = 64.0 / float(uStep);
	
	float decay = 1.0 - (0.05 * stepnormalize);
	
	vec3 color = vec3(0.0);

	vec2 coord = vTexCoord;

	float illuminationDecay = 1.0;
	float kerneloffset = 1.0 + (uKernelGodRay * rayLength);
	
	for(int i = 0; i < SAMPLES; i++)
	{
		if (i > uStep)
			break;
		
	    coord += dir * rayLength * density / float(uStep) * kerneloffset;
		
		// coord *= (dither(coord.xy + vec2(uKernel.y, uKernel.z)) - 0.5) / 255.0 + 1.0;
		
		if (coord.x > 1.0 || coord.x < 0.0 || coord.y > 1.0 || coord.y < 0.0)
			break;
		
	    vec3 sampleCol = vec3(1.0) - texture2D(uMaskRaysTexture, coord).r;

	    color += sampleCol * uRayColor * illuminationDecay * weight;
	    
		illuminationDecay *= decay;
	}
	
	gl_FragColor = vec4(color * stepnormalize, 1.0);
}
