uniform sampler2D uTexture; // static
uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static

uniform float uNormalBufferScale;
uniform float uNormalStrength;

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

uniform vec3 uCameraPosition; // static

uniform float uMetallic;
uniform float uRoughness;
uniform float uEmissive;
uniform int uIsSky;

// Materials
uniform int uMaterialFormat;
uniform int uBlendMode;
uniform float uDefaultEmissive;
uniform float uDefaultSubsurface;

varying vec3 vPosition;
varying float vDepth;
varying vec3 vNormal;
varying vec3 vNormal2;
varying vec3 vTangent;
varying vec3 vTangent2;
varying vec4 vColor;
varying vec2 vTexCoord;
varying vec4 vCustom;
varying mat3 vTBN;
varying mat3 vTBN2;

// Fresnel Schlick approximation
float fresnelSchlickRoughness(float cosTheta, float F0, float roughness)
{
	return F0 + (max((1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

uniform int uUseNormalMap; // static
vec3 getMappedNormal(vec2 uv)
{
	if (uUseNormalMap < 1)
		return vec3(vTBN[2][0], vTBN[2][1], vTBN[2][2]);
	
	vec4 n = texture2D(uTextureNormal, uv).rgba;
	n.rgba = (n.a < 0.01 ? vec4(.5, .5, 0.0, 1.0) : n.rgba); // No normal?
	n.xy = n.xy * 2.0 - 1.0; // Decode
	n.z = sqrt(max(0.0, 1.0 - dot(n.xy, n.xy))); // Get Z
	n.y *= -1.0; // Convert Y- to Y+
	vec3 smoothNormal = normalize(mix(vec3(0.0, 0.0, 1.0), n.xyz, uNormalStrength));
	
	return normalize(vTBN * smoothNormal);
}

vec3 getMappedNormal2(vec2 uv)
{
	if (uUseNormalMap < 1)
		return vec3(vTBN2[2][0], vTBN2[2][1], vTBN2[2][2]);
	
	vec4 n = texture2D(uTextureNormal, uv).rgba;
	n.rgba = (n.a < 0.01 ? vec4(.5, .5, 0.0, 1.0) : n.rgba); // No normal?
	n.xy = n.xy * 2.0 - 1.0; // Decode
	n.z = sqrt(max(0.0, 1.0 - dot(n.xy, n.xy))); // Get Z
	//n.y *= -1.0; // Convert Y- to Y+

	vec3 smoothNormal = normalize(mix(vec3(0.0, 0.0, 1.0), n.xyz, uNormalStrength));
	return normalize(vTBN2 * smoothNormal);
}

vec4 packDepth(float depth)
{
    vec4 enc = vec4(depth, fract(depth * vec3(255.0, 65025.0, 16581375.0)));

    enc -= enc.yzww * vec4(
        1.0/255.0,
        1.0/255.0,
        1.0/255.0,
        0.0
    );

	enc.a = 1.0; // opaque
    return enc;
}

vec4 packNormal(vec3 n)
{
	return vec4(((n + vec3(1.0)) * 0.5) * uNormalBufferScale, 1.0);
}

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

float getFog()
{
	float fog, fog2;
	if (uFogShow > 0)
	{
		float fogDepth = distance(vPosition, uCameraPosition);
		
		fog = clamp(1.0 - (uFogDistance - fogDepth) / uFogSize, 0.0, 1.0);
		fog *= clamp(1.0 - (vPosition.z - uFogHeight) / uFogSize, 0.0, 1.0);
		
		if (uFogHeightShow > 0) {
			fog2 = clamp(1.0 - (0.0 - fogDepth) / uFogHeightSize, 0.0, 1.0);
			fog2 *= clamp(1.0 - (vPosition.z - uFogHeightOffset) / uFogHeightSize, 0.0, 1.0);
			fog += fog2;
		}
	}
	else
		fog = 0.0;
	
	return fog;
}

float hash(vec2 c)
{
	return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
	(0.1 + abs(sin(13.0 * c.y + c.x))));
}

vec3 packEmissive(float f)
{
	return vec3(floor(f * 255.0) / 255.0, fract(f * 255.0), fract(f * 255.0 * 255.0));
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
		
		roughness = pow(1.0 - matColor.r, 2.0);
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

void main()
{
	vec2 tex = vTexCoord;
	vec4 baseColor = vColor * texture2D(uTexture, tex); // Get base
	vec4 DiffuseResult, MaterialsResult, EmmisivesResult, DepthResult, NormalsResult;
	
	DiffuseResult = vec4(0.0);
	MaterialsResult = vec4(0.0);
	EmmisivesResult = vec4(0.0);
	DepthResult = vec4(0.0);
	NormalsResult = vec4(0.0);
	
	if (baseColor.a == 0.0)
		discard;
	
	if (uAlphaHash > 0 && (baseColor.a < hash(vec2(hash(vPosition.xy + (uSampleIndex / 255.0)), vPosition.z + (uSampleIndex / 255.0)))))
		discard;
	
	/* ====== DIFFUSE ======
	
	if (uColorsExt > 0)
	{
		DiffuseResult = clamp(baseColor + uRGBAdd - uRGBSub, 0.0, 1.0); // Transform RGB
		DiffuseResult = hsbtorgb(clamp(rgbtohsb(DiffuseResult) + uHSBAdd - uHSBSub, 0.0, 1.0) * uHSBMul); // Transform HSB
		DiffuseResult = mix(DiffuseResult, uMixColor, uMixColor.a); // Mix
		DiffuseResult = mix(DiffuseResult, uFogColor, getFog()); // Mix fog
		DiffuseResult.a = baseColor.a; // Correct alpha
	}
	else 
	{
		DiffuseResult = mix(baseColor, uFogColor, getFog()); // Mix fog
		DiffuseResult.a = baseColor.a; // Correct alpha
	}
	
	if (uAlphaHash > 0)
	{
		if (DiffuseResult.a < hash(vec2(hash(vPosition.xy + (uSampleIndex / 255.0)), vPosition.z + (uSampleIndex / 255.0))))
			discard;
		else
			DiffuseResult.a = 1.0;
	}
	
	if (DiffuseResult.a == 0.0)
		discard;
	*/
	// =====================
	// ====== MATERIAL & EMMISIVE ======
	
	
	baseColor = vColor * texture2D(uTexture, tex);
	
	// Get material data
	float roughness, metallic, emissive, F0, sss;
	getMaterial(roughness, metallic, emissive, F0, sss);
	
	// Fresnel
	vec3 N = getMappedNormal(vTexCoord);
	vec3 V  = normalize(uCameraPosition - vPosition);
	vec3 H  = normalize(V + -reflect(V, N));
	float F = fresnelSchlickRoughness(max(dot(H, V), 0.0), F0, roughness);
	
	if (uIsSky > 0)
		F = 0.0;
	
	MaterialsResult = vec4(roughness, metallic, F, 1.0);
	
	// Emissive
	EmmisivesResult = vec4(packEmissive((emissive / 255.0) * baseColor.a), baseColor.a);
	
	// =====================
	// ====== DEPTH & NORMAL ======
	
	
	baseColor = vColor * texture2D(uTexture, tex);
	
	// Depth
	DepthResult = packDepth(vDepth);
	
	// Normal
	NormalsResult = packNormal(getMappedNormal2(tex));
	
	if (baseColor.a <= 0.011) {
		MaterialsResult.a = 0.0;
		EmmisivesResult.a = 0.0;
		DepthResult.a = 0.0;
		NormalsResult.a = 0.0;
	}
	
	gl_FragData[0] = MaterialsResult;
	gl_FragData[1] = EmmisivesResult;
	gl_FragData[2] = DepthResult;
	gl_FragData[3] = NormalsResult;
}