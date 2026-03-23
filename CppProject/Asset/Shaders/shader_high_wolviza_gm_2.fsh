uniform sampler2D uTexture; // static
uniform sampler2D uTextureNormal; // static

uniform float uNormalBufferScale;
uniform float uNormalStrength;

uniform vec2 uTextureSize;

uniform sampler2D uGlintTexture; // static
uniform vec2 uGlintOffset;
uniform vec2 uGlintSize;
uniform int uGlintEnabled;
uniform float uGlintStrength;

uniform float uGamma;

uniform float uSampleIndex;
uniform int uAlphaHash;

varying vec3 vPosition;
varying vec2 vTexCoord;
varying float vDepth;
varying vec4 vColor;
varying mat3 vTBN;

vec4 packDepth(float depth)
{
    vec4 enc = fract(depth * vec4(
        1.0,
        255.0,
        65025.0,
        16581375.0
    ));

    enc -= enc.yzww * vec4(
        1.0/255.0,
        1.0/255.0,
        1.0/255.0,
        0.0
    );

    return enc;
}

vec4 packNormal(vec3 n)
{
	return vec4(((n + vec3(1.0)) * 0.5) * uNormalBufferScale, 1.0);
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
	//n.y *= -1.0; // Convert Y- to Y+

	vec3 smoothNormal = normalize(mix(vec3(0.0, 0.0, 1.0), n.xyz, uNormalStrength));
	return normalize(vTBN * smoothNormal);
}

float hash(vec2 c)
{
	return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
	(0.1 + abs(sin(13.0 * c.y + c.x))));
}

void main()
{
	vec2 tex = vTexCoord;
	vec4 baseColor = vColor * texture2D(uTexture, tex);
	
	gl_FragData[0] = baseColor;
}