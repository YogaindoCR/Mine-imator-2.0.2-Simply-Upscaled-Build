uniform sampler2D uTexture; // static
uniform sampler2D uTextureMaterial; // static
uniform vec2 uTextureSize;

uniform sampler2D uGlintTexture; // static
uniform vec2 uGlintOffset;
uniform vec2 uGlintSize;
uniform int uGlintEnabled;
uniform float uGlintStrength;

uniform float uSampleIndex;
uniform int uAlphaHash;

uniform int uColorsExt;
uniform vec4 uRGBAdd;
uniform vec4 uRGBSub;
uniform vec4 uHSBAdd;
uniform vec4 uHSBSub;
uniform vec4 uHSBMul;
uniform vec4 uMixColor;

uniform int uFogShow;
uniform int uFogHeightShow;
uniform vec4 uFogColor; // static
uniform float uFogDistance; // static
uniform float uFogSize; // static
uniform float uFogHeight; // static
uniform float uFogHeightSize; // static
uniform float uFogHeightOffset; // static
uniform vec4 uFogHeightColor; // static

uniform float uDefaultEmissive;
uniform float uDefaultSubsurface;
uniform int uMaterialFormat;
uniform float uMetallic;
uniform float uRoughness;
uniform float uEmissive;

uniform vec4 uFallbackColor;
uniform vec4 uAmbientColor;

uniform vec3 uCameraPosition; // static

uniform int uTonemapper;
uniform float uExposure;
uniform float uGamma;

varying vec3 vPosition;
varying vec3 vNormal;
varying float vDepth;
varying vec4 vColor;
varying vec2 vTexCoord;
varying vec3 vDiffuse;
varying vec4 vCustom;

vec4 rgbtohsb(vec4 c)
{
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec4(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x, c.a);
}

vec4 hsbtorgb(vec4 c)
{
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return vec4(c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y), c.a);
}

vec2 getFog()
{
    float fog1 = 0.0;
    float fog2 = 0.0;

    if (uFogShow > 0)
    {
        float fogDepth = distance(vPosition, uCameraPosition);

        // Main fog
        fog1 = clamp(1.0 - (uFogDistance - fogDepth) / uFogSize, 0.0, 1.0);
        fog1 *= clamp(1.0 - (vPosition.z - uFogHeight) / uFogSize, 0.0, 1.0);

        // Height fog
        if (uFogHeightShow > 0)
        {
            fog2 = clamp(1.0 - (0.0 - fogDepth) / uFogHeightSize, 0.0, 1.0);
            fog2 *= clamp(1.0 - (vPosition.z - uFogHeightOffset) / uFogHeightSize, 0.0, 1.0);
        }
    }

    return vec2(fog1, fog2);
}

// Fresnel-Schlick approximation (injected roughness term)
// -------------------------------------------------------
// https://learnopengl.com/PBR/IBL/Diffuse-irradiance
float fresnelSchlickRoughness(float cosTheta, float F0, float roughness)
{
    return F0 + (max(float(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float hash(vec2 c)
{
	return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
	(0.1 + abs(sin(13.0 * c.y + c.x))));
}

void getMaterial(out float roughness, out float metallic, out float emissive, out float F0, out float sss)
{
	vec4 matColor = texture2D(uTextureMaterial, vTexCoord);
	
	if (uMaterialFormat == 2) // LabPBR
	{
		if (matColor.g > 0.898) // Metallic
		{
			metallic = 1.0; F0 = 1.0; sss = 0.0;
		}
		else // Non-metallic
		{
			metallic = 0.0; F0 = matColor.g;
			sss = (matColor.b > 0.255 ? (((matColor.b - 0.255) / 0.745) * uDefaultSubsurface) : 0.0);
		}
		
		// Convert material color to linear roughness
		roughness = pow(1.0 - matColor.r, 2.0);
		
		// Convert linear roughness to material color
		matColor.r = 1.0 - sqrt(roughness);
		
		emissive = (matColor.a < 1.0 ? matColor.a /= 0.9961 : 0.0) * uDefaultEmissive;
		
		return;
	}
	
	if (uMaterialFormat == 1) // SEUS
	{
		roughness = (1.0 - matColor.r);
		metallic = matColor.g;
		emissive = (matColor.b * uDefaultEmissive);
	}
	else // No map
	{
		roughness = uRoughness;
		metallic = uMetallic;
		emissive = max(uEmissive, vCustom.z * uDefaultEmissive);
	}
	
	F0 = mix(0.0, 1.0, metallic);
	sss = vCustom.w * uDefaultSubsurface;
}

// ACES (implementation by Stephen Hill, @self_shadow)
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

// Filmic
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
	vec2 tex = vTexCoord;
	vec4 baseColor = vColor * texture2D(uTexture, tex); // Get base
	
	// Get material data
	float roughness, metallic, emissive, F0, sss;
	getMaterial(roughness, metallic, emissive, F0, sss);
	
	// Fresnel
	vec3 N  = vNormal;
	vec3 V  = normalize(uCameraPosition - vPosition);
	vec3 H  = normalize(V + -reflect(V, N));
	float F = fresnelSchlickRoughness(max(dot(H, V), 0.0), F0, roughness);
	
	// Diffuse
	vec3 dif;
	
	// Assume no shading
	if (vDiffuse.r < 0.0)
	{
		dif = vec3(1.0);
		F = 0.0;
	}
	else
		dif = vDiffuse + uAmbientColor.rgb;
	
	dif *= (1.0 - F);
	dif = max(vec3(0.0), dif);
	
	vec4 col;
	vec3 spec;
	
	if (baseColor.a == 0.0)
		discard;
	
	if (uColorsExt > 0)
	{
		col = clamp(baseColor + uRGBAdd - uRGBSub, 0.0, 1.0); // Transform RGB
		col = hsbtorgb(clamp(rgbtohsb(col) + uHSBAdd - uHSBSub, 0.0, 1.0) * uHSBMul); // Transform HSB
		col = mix(col, uMixColor, uMixColor.a); // Mix
	}
	else
		col = baseColor;
	
	if (vDiffuse.r >= 0.0)
		col.rgb = pow(col.rgb, vec3(uGamma));
	
	// Get specular color
	spec = (mix(vec3(1.0), col.rgb, metallic) * pow(uFallbackColor.rgb, vec3(uGamma)) * F);
	
	dif *= (1.0 - metallic);
	
	// Emissive
	dif += emissive;
	
	col.rgb *= dif; // Multiply diffuse
	
	col.rgb += spec;
	
	if (uGlintEnabled > 0 && col.a > 0.0)
		col.rgb += pow(texture2D(uGlintTexture, (tex * ((uTextureSize / uGlintSize))) + uGlintOffset).rgb * col.a * uGlintStrength, vec3(uGamma));
	
	if (vDiffuse.r >= 0.0)
	{
		// Exposure
		if (uTonemapper != 5)
			col.rgb *= uExposure;
	
		// Tone map
		if (uTonemapper == 0);
		else if (uTonemapper == 1)
			col.rgb /= (1.0 + col.rgb); // Reinhard
		else if (uTonemapper == 2)
			col.rgb = mapACES(col.rgb); // ACES
		else if (uTonemapper == 3)
		    col.rgb = mapFilmic(col.rgb); // Filmic
		else if (uTonemapper == 4)
		    col.rgb = mapACESApprox(col.rgb); // ACES Approx
		else
			col.rgb = mapAGX(col.rgb, uExposure, uGamma); // AGX
	
		// Gamma
		if (uTonemapper != 5)
			col.rgb = pow(col.rgb, vec3(1.0/uGamma));
	}
	
	vec2 fog = getFog();

	col = mix(col, uFogHeightColor, fog.y);
	col = mix(col, uFogColor, fog.x);
		
	col.a = mix(baseColor.a, 1.0, F); // Correct alpha
	
	if (uAlphaHash > 0)
	{
		if (col.a < hash(vec2(hash(vPosition.xy + (uSampleIndex / 255.0)), vPosition.z + (uSampleIndex / 255.0))))
			discard;
		else
			col.a = 1.0;
	}
	
	gl_FragColor = col;
}
