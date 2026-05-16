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
    x *= (uExposure / 2.5);

    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;

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

vec3 agxDefaultContrastApprox(vec3 x)
{
    vec3 x2 = x * x;
    vec3 x4 = x2 * x2;

    return 15.5 * x4 * x2 - 40.14  * x4 * x + 31.96  * x4 - 6.868  * x2 * x + 0.4298 * x2 + 0.1191 * x - 0.00232;
}

vec3 mulMat3Vec3(
    vec3 r0,
    vec3 r1,
    vec3 r2,
    vec3 v)
{
    return vec3(
        dot(r0, v),
        dot(r1, v),
        dot(r2, v)
    );
}

vec3 mapAGX(vec3 color, float exposure, float gamma)
{
    // AGX Inset Matrix (TRANSPOSED FOR ROW-DOT MULTIPLY)
    vec3 AgXInsetMatrixR0 = vec3(
        0.856627153315983,
        0.095121240538159,
        0.048251606145858
    );

    vec3 AgXInsetMatrixR1 = vec3(
        0.137318972929847,
        0.761241990602591,
        0.101439036467562
    );

    vec3 AgXInsetMatrixR2 = vec3(
        0.111898212999950,
        0.076799418603190,
        0.811302368396859
    );

    // AGX Outset Matrix (TRANSPOSED)
    vec3 AgXOutsetMatrixR0 = vec3(
         1.127100581814437,
        -0.110606643096603,
        -0.016493938717835
    );

    vec3 AgXOutsetMatrixR1 = vec3(
        -0.141329763498438,
         1.157823702216272,
        -0.016493938717834
    );

    vec3 AgXOutsetMatrixR2 = vec3(
        -0.141329763498438,
        -0.110606643096603,
         1.251936406595041
    );

    // REC2020 -> SRGB (TRANSPOSED)
    vec3 REC2020_TO_SRGB_R0 = vec3(
         1.6605,
        -0.5876,
        -0.0728
    );

    vec3 REC2020_TO_SRGB_R1 = vec3(
        -0.1246,
         1.1329,
        -0.0083
    );

    vec3 REC2020_TO_SRGB_R2 = vec3(
        -0.0182,
        -0.1006,
         1.1187
    );

    // SRGB -> REC2020 (TRANSPOSED)
    vec3 SRGB_TO_REC2020_R0 = vec3(
        0.6274,
        0.3293,
        0.0433
    );

    vec3 SRGB_TO_REC2020_R1 = vec3(
        0.0691,
        0.9195,
        0.0113
    );

    vec3 SRGB_TO_REC2020_R2 = vec3(
        0.0164,
        0.0880,
        0.8956
    );

    float AgxMinEv = -12.47393;
    float AgxMaxEv = 4.026069;

    // Exposure
    color *= exposure;

    // SRGB -> REC2020
    color = mulMat3Vec3(
        SRGB_TO_REC2020_R0,
        SRGB_TO_REC2020_R1,
        SRGB_TO_REC2020_R2,
        color
    );

    // Inset
    color = mulMat3Vec3(
        AgXInsetMatrixR0,
        AgXInsetMatrixR1,
        AgXInsetMatrixR2,
        color
    );

    // Avoid negative / zero
    color = max(color, vec3(1e-10));

    // Log2 encoding
    color = log2(color);

    // Normalize EV range
    color = (color - AgxMinEv) / (AgxMaxEv - AgxMinEv);

    // Clamp
    color = clamp(color, 0.0, 1.0);

    // Contrast curve
    color = agxDefaultContrastApprox(color);

    // Outset
    color = mulMat3Vec3(
        AgXOutsetMatrixR0,
        AgXOutsetMatrixR1,
        AgXOutsetMatrixR2,
        color
    );

    // Gamma-ish transform
    color = pow(max(vec3(0.0), color), vec3(gamma));

    // REC2020 -> SRGB
    color = mulMat3Vec3(
        REC2020_TO_SRGB_R0,
        REC2020_TO_SRGB_R1,
        REC2020_TO_SRGB_R2,
        color
    );

    return color;
}

void main()
{
	// Get base
	vec4 baseColor = texture2D(gm_BaseTexture, vTexCoord);
	vec4 color = baseColor;
	
	// Exposure
	if (uTonemapper != 5)
		color.rgb *= uExposure;
	
	// Tone map
	if (uTonemapper == 0);
	else if (uTonemapper == 1)
		color.rgb /= (1.0 + color.rgb); // Reinhard
	else if (uTonemapper == 2)
		color.rgb = mapACES(color.rgb); // ACES
	else if (uTonemapper == 3)
	    color.rgb = mapFilmic(color.rgb); // Filmic
	else if (uTonemapper == 4)
	    color.rgb = mapACESApprox(color.rgb); // ACES Approx
	else
		color.rgb = mapAGX(color.rgb, uExposure, uGamma); // AGX
	
	// Gamma
	if (uTonemapper != 5)
		color.rgb = pow(color.rgb, vec3(1.0/uGamma));
	
	gl_FragColor = mix(baseColor, color, texture2D(uMask, vTexCoord).r);
}