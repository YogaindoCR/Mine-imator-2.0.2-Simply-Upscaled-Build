/// shader_blur

attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;

uniform vec3 uLightDirection; // static
uniform vec3 uCameraPosition; // static

uniform mat4 uViewMatrix;

varying vec2 vTexCoord;
varying vec2 vSunUV;

void main()
{
	vTexCoord = in_TextureCoord;
	gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position, 1.0);

	vec3 sunDir = normalize(uLightDirection);

	// Put fake sun very far away from camera
	vec3 sunWorldPos = uCameraPosition + sunDir * 100000.0;

	// Project to clip space
	vec4 clip = uViewMatrix * vec4(sunWorldPos, 1.0);

	// NDC
	vec3 ndc = clip.xyz / clip.w;

	// Convert to UV
	vSunUV = ndc.xy * vec2(0.5, -0.5) + 0.5;
}