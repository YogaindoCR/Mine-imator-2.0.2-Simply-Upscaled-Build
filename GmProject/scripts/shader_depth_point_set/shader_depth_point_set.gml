/// shader_depth_point_set()

function shader_depth_point_set()
{
	render_set_uniform_vec3("uEye", render_proj_from[X], render_proj_from[Y], render_proj_from[Z])
	render_set_uniform("uNear", proj_depth_near)
	render_set_uniform("uFar", proj_depth_far)
	
	if (proj_depth_paraboloid)
	{
		render_set_uniform("uParaboloid", proj_depth_paraboloid)
		render_set_uniform_vec3("uLightPos", render_light_from[X], render_light_from[Y], render_light_from[Z])
		render_set_uniform("uLightRange", render_light_far)
		render_set_uniform_int("uHemisphere", proj_depth_hemisphere)
	}
}
