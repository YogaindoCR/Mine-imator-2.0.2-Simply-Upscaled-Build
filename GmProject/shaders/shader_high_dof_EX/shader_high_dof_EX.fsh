uniform sampler2D uBlurBuffer;
uniform vec2 uScreenSize;
uniform float uBlurSize;

uniform float uBias;
uniform float uThreshold;
uniform float uGain;
uniform float uDesaturation;

uniform bool uGhostingFix;
uniform float uGhostingFixThreshold;

uniform int uFringe;
uniform vec3 uFringeAngle;
uniform vec3 uFringeStrength;

uniform int uSampleAmount;
uniform vec2 uSamples[128];
uniform float uWeightSamples[128];

varying vec2 vTexCoord;

float getBlur(vec2 coord)
{
    vec2 blur = texture2D(uBlurBuffer, coord).xy;
    return clamp(blur.x + blur.y, 0.0, 1.0);
}

vec4 getFringe(vec2 coord, float blur, vec4 color)
{
    float screenSampleSize = uScreenSize.y * uBlurSize;
    vec2 texelSize = 1.0 / uScreenSize;
    vec4 baseColor = color;

    if (uFringe < 1) return baseColor;

    float fringeSize = texelSize.x * blur * screenSampleSize;

    // Red channel
    vec2 redOffset = vec2(cos(uFringeAngle.x), sin(uFringeAngle.x)) * (uFringeStrength.x * fringeSize);
    baseColor.r = texture2D(gm_BaseTexture, coord + redOffset).r;

    // Green channel
    vec2 greenOffset = vec2(cos(uFringeAngle.y), sin(uFringeAngle.y)) * (uFringeStrength.y * fringeSize);
    baseColor.g = texture2D(gm_BaseTexture, coord + greenOffset).g;

    // Blue channel
    vec2 blueOffset = vec2(cos(uFringeAngle.z), sin(uFringeAngle.z)) * (uFringeStrength.z * fringeSize);
    baseColor.b = texture2D(gm_BaseTexture, coord + blueOffset).b;

    return baseColor;
}

vec4 getColor(vec2 coord, float blur)
{
    vec4 baseColor = texture2D(gm_BaseTexture, coord);
    baseColor = getFringe(coord, blur, baseColor);

    float lum = dot(baseColor.rgb, vec3(0.299, 0.587, 0.114));
    float highlight = max((lum - uThreshold) * uGain, 0.0);
    vec3 boostedColor = baseColor.rgb + baseColor.rgb * highlight * blur;

    // Smooth desaturation based on blur
	if (uDesaturation != 0.0) {
	    float desatAmount = smoothstep(0.0, 1.0, blur);
	    desatAmount *= uDesaturation;  // Scale with user control

	    float desat = dot(boostedColor, vec3(0.333));
	    boostedColor = mix(vec3(desat), boostedColor, 1.0 - desatAmount);
	}

    baseColor.rgb = boostedColor;
    return baseColor;
}

void main()
{
    vec2 texelSize = 1.0 / uScreenSize;
    float screenSampleSize = uScreenSize.y * uBlurSize;

    vec2 blurTex = texture2D(uBlurBuffer, vTexCoord).xy;
    float myBlur = clamp(blurTex.r + blurTex.g, 0.0, 1.0);
    float blurAmount = myBlur * screenSampleSize;

    vec4 colorAdd = vec4(0.0);
    float colorDiv = 0.0;
    float weightStrength = 0.0;
    float blur = 0.0;
	gl_FragColor = vec4(0.0);

    // No blur needed, use base texture
    if (blurAmount > 0.0)
    {
		for (int i = 0; i < 128; i++)
	    {
	        if (i >= uSampleAmount)
	            break;

	        if (uWeightSamples[i] < 0.05)
	            continue;

	        vec2 offset = uSamples[i];
	        float dist = length(offset);
	        offset *= blurAmount;

	        vec2 sampleCoord = vTexCoord + texelSize * offset;

	        float sampleBlur = getBlur(sampleCoord);
			
			// Ghosting Fix
			if (uGhostingFix) {
				// Compare difference between current blur and sample blur
				float blurDiff = abs(sampleBlur - myBlur);

				// Reject samples too different (ghosting source)
				if (blurDiff > uGhostingFixThreshold) continue;
			}
			
	        float bias = mix(1.0, smoothstep(0.0, 1.0, uWeightSamples[i]), uBias * 0.2);
	        float falloff = exp(-dist * dist * 1.5); // optional soft edge

	        float baseWeight = (1.0 - (1.0 - sampleBlur) * myBlur) * bias * falloff;

	        vec4 sampleColor = getColor(sampleCoord, sampleBlur);
	        float brightness = dot(sampleColor.rgb, vec3(0.299, 0.587, 0.114));
	        float brightnessBias = smoothstep(0.0, 1.0, brightness);

	        float weight = baseWeight * mix(0.2, 1.0, brightnessBias); // reduce dark bleed

	        if (weight > 0.0)
	        {
	            colorAdd += sampleColor * weight;
	            colorDiv += weight;
	        }

	        blur += sampleBlur;
	        weightStrength += bias;
	    }

	    // Normalize blur strength
	    blur = (weightStrength > 0.0) ? blur / weightStrength : 0.0;
	    blur += myBlur;

	    // Apply blurred result
	    if (colorDiv > 0.0)
	    {
	        colorAdd *= blur;
	        colorDiv *= blur;
	        gl_FragColor = colorAdd / colorDiv;
	    }
	    else
	        gl_FragColor = texture2D(gm_BaseTexture, vTexCoord);
    } else
        gl_FragColor = texture2D(gm_BaseTexture, vTexCoord);
}