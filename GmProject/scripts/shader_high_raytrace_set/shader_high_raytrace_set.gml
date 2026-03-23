/// shader_high_raytrace_set(mode, [surf])
/// @arg mode
/// @arg surf

function shader_high_raytrace_set(mode, surf = null)
{
	texture_set_stage(sampler_map[?"uDepthBuffer"], surface_get_texture(render_surface_depth))
	texture_set_stage(sampler_map[?"uNormalBuffer"], surface_get_texture(render_surface_normal))
	texture_set_stage(sampler_map[?"uNoiseBuffer"], surface_get_texture(render_sample_noise_texture))
	texture_set_stage(sampler_map[?"uMaterialBuffer"], surface_get_texture(render_surface_material))
	
	if (app.project_render_engine) {
		if (app.background_image_show && app.background_image != null && app.background_image_type != "image") {
			texture_set_stage(sampler_map[?"uReflectionProbeBuffer"], sprite_get_texture(app.background_image.texture, 0))
		
		gpu_set_texrepeat_ext(sampler_map[?"uReflectionProbeBuffer"], true)
		gpu_set_tex_filter_ext(sampler_map[?"uReflectionProbeBuffer"], true)
		
		render_set_uniform("uReflectionProbeRot", app.background_image_rotation + 90)
		render_set_uniform("uReflectionProbeStrength", app.background_image_probe_strength)
		/*
		if (app.background_reflection_probe_show && app.background_reflection_probe_image != null) {
		texture_set_stage(sampler_map[?"uReflectionProbeBuffer"], sprite_get_texture(app.background_reflection_probe_image, 0))
		
		gpu_set_texrepeat_ext(sampler_map[?"uReflectionProbeBuffer"], true)
		
		render_set_uniform_int("uReflectionProbe", (app.background_reflection_probe_show && app.background_reflection_probe_image != null) ? 1 : 0)
		render_set_uniform("uReflectionProbeRot", app.background_reflection_probe_rot)
		*/
		}
	}
	render_set_uniform_int("uReflectionProbe", (app.background_image_show && app.background_image != null) ? 1 : 0)
	
	texture_set_stage(sampler_map[?"uDiffuseBuffer"], surface_get_texture(render_surface_diffuse))
	gpu_set_texrepeat_ext(sampler_map[?"uNoiseBuffer"], true)
	
	render_set_uniform_int("uRayType", mode)
	
	render_set_uniform("uNormalBufferScale", is_cpp() ? normal_buffer_scale : 1)
	
	if (mode = e_raytrace.INDIRECT)
	{
		render_set_uniform("uPrecision", app.project_render_indirect_precision)
		render_set_uniform("uThickness", 0.001)
		render_set_uniform("uRayDistance", app.project_render_engine ? 10000 : 5000)
		
		texture_set_stage(sampler_map[?"uMaterialBuffer"], surface_get_texture(render_surface_emissive))
		texture_set_stage(sampler_map[?"uDataBuffer"], surface_get_texture(render_surface_shadows))
	}
	
	if (mode = e_raytrace.REFLECTIONS)
	{
		render_set_uniform("uPrecision", app.project_render_reflections_precision)
		render_set_uniform("uThickness", app.project_render_reflections_thickness)
		render_set_uniform("uRayDistance", app.project_render_engine ? 30000 : 6000)
		
		texture_set_stage(sampler_map[?"uDataBuffer"], surface_get_texture(surf))
	}
	
	render_set_uniform("uNoiseSize", render_sample_noise_size)
	render_set_uniform("uNear", depth_near)
	render_set_uniform("uFar", depth_far_custom)
	render_set_uniform("uProjMatrix", proj_matrix)
	render_set_uniform("uProjMatrixInv", matrix_inverse(proj_matrix))
	render_set_uniform_vec2("uScreenSize", render_width, render_height)
	render_set_uniform("uViewMatrixInv", matrix_inverse(view_matrix))
	
	// Reflections
	render_set_uniform_color("uSkyColor", app.background_sky_color_final, 1)
	render_set_uniform_color("uFogColor", app.background_fog_color_final, 1)
	render_set_uniform("uFadeAmount", app.project_render_reflections_fade_amount)
	render_set_uniform("uGamma", render_gamma)
	
	// Indirect
	render_set_uniform("uIndirectStength", app.project_render_indirect_strength)
}
