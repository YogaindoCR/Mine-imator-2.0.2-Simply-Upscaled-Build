/// shader_high_godray_set(mask)
/// @arg mask

function shader_high_godray_set(mask)
{
	render_set_uniform_vec3("uLightDirection", render_sun_direction[X], render_sun_direction[Y], render_sun_direction[Z])
	render_set_uniform_vec3("uCameraPosition", cam_from[X], cam_from[Y], cam_from[Z])
	
	render_set_uniform_vec3("uRayColor", color_get_red(app.background_sunlight_color_final) / 255, color_get_green(app.background_sunlight_color_final) / 255, color_get_blue(app.background_sunlight_color_final) / 255)
	render_set_uniform("uViewMatrix", view_proj_matrix)
	render_set_uniform("uKernelGodRay", render_sample_current = 1 ? 1.0 : (random_range(0.0, 1.0)))
	render_set_uniform("uStrength", app.background_godray_strength / 10)
	render_set_uniform("uDensity", app.background_godray_density)
	render_set_uniform_int("uStep", app.project_render_godray_step)
	
	texture_set_stage(sampler_map[?"uMaskRaysTexture"], surface_get_texture(mask))
	gpu_set_texfilter_ext(sampler_map[?"uMaskRaysTexture"], true)
}
