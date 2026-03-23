uniform sampler2D uTexture; // static

varying vec2 vTexCoord;
varying float vDepth;
varying vec4 vColor;

varying vec3 vPosition;
uniform float uSampleIndex;
uniform int uAlphaHash;

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

float hash(vec2 c)
{
	return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
	(0.1 + abs(sin(13.0 * c.y + c.x))));
}

void main()
{
	vec2 tex = vTexCoord;
	vec4 col = texture2D(uTexture, tex) * vColor;
	
	if (col.a < 0.001)
		discard;
	
	vec4 depth = packDepth(vDepth);
	
	if (uAlphaHash > 0 && (col.a < hash(vec2(hash(vPosition.xy + (uSampleIndex / 255.0)), vPosition.z + (uSampleIndex / 255.0)))))
		depth.a = 0.0;
	else
		col.a = 1.0;
	
	if (col.a <= 0.011)
		depth.a = 0.0;
		
	gl_FragColor = depth;
}

