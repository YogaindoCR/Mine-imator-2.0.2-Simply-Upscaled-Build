varying vec2 vTexCoord;

uniform sampler2D uMask;

uniform int uTonemapper;
uniform float uExposure;
uniform float uGamma;

/// ACES (implementation by Stephen Hill, @self_shadow)
vec3 RRTAndODTFit(vec3 v)
{
	vec3 a = v * (v + 0.0245786) - 0.000090537;
	vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
	return a / b;
}

vec3 mapACESApprox(vec3 x)
{
    x *= (uExposure / 2.5); // adjust exposure
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14 * (uGamma / 2.2);
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

//Filmic
vec3 mapFilmic(vec3 x)
{
    float A = 0.22; // shoulder strength
    float B = 0.30; // linear strength
    float C = 0.10; // linear angle
    float D = 0.20; // toe strength
    float E = 0.01; // toe numerator
    float F = 0.30; // toe denominator
    
    return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F)) - E/F;
}

vec3 mapLottes(vec3 x)
{
    float a = 1.6;
    float d = 0.977;
    float hdrMax = 8.0;
    float midIn = 0.18;
    float midOut = 0.267;
    
    float b = (-pow(midIn, a) + pow(hdrMax, a) * midOut) / 
                   ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
    float c = (pow(hdrMax, a * d) * pow(midIn, a) - pow(hdrMax, a) * pow(midIn, a * d) * midOut) / 
                   ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
    
    return pow(x, vec3(a)) / (pow(x, vec3(a * d)) * b + c);
}

vec3 mapACES(vec3 color)
{
	// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
	color = vec3(
		color.r * 0.59719 + color.g * 0.35458 + color.b * 0.04823,
		color.r * 0.07600 + color.g * 0.90834 + color.b * 0.01566,
		color.r * 0.02840 + color.g * 0.13383 + color.b * 0.83777
	);
	
	color = RRTAndODTFit(color);
	
	// ODT_SAT => XYZ => D60_2_D65 => sRGB
	color = vec3(
		color.r *  1.60475 + color.g * -0.53108 + color.b * -0.07367,
		color.r * -0.10208 + color.g *  1.10813 + color.b * -0.00605,
		color.r * -0.00327 + color.g * -0.07276 + color.b *  1.07602
	);
	
	return color;
}

void main()
{
	// Get base
	vec4 baseColor = texture2D(gm_BaseTexture, vTexCoord);
	vec4 color = baseColor;
	
	// Exposure
	color.rgb *= uExposure;
	
	// Tone map
	if (uTonemapper == 0);
	else if (uTonemapper == 1)
		color.rgb /= (1.0 + color.rgb); // Reinhard
	else if (uTonemapper == 2)
		color.rgb = mapACES(color.rgb); // ACES
	else if (uTonemapper == 3)
	    color.rgb = mapFilmic(color.rgb); // Filmic
	else
	    color.rgb = mapACESApprox(color.rgb); // ACES Approx
	
	// Gamma
	color.rgb = pow(color.rgb, vec3(1.0/uGamma));
	
	gl_FragColor = mix(baseColor, color, texture2D(uMask, vTexCoord).r);
}