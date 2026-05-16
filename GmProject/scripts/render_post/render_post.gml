/// render_post(surface, [sceneeffects, posteffects])
/// @arg surface
/// @arg sceneeffects
/// @arg posteffects

function render_post(finalsurf, sceneeffects = true, posteffects = true)
{
	// Start post processing
	finalsurf = render_high_post_start(finalsurf)
	render_post_kernel = (render_samples < 2 || render_quality != 2) ? 1 : random_range(0.85, 1.15)
	
	// Fill in the depth & normal surface blank
	if (sceneeffects && render_quality == e_view_mode.RENDER) 
	{
		var depthtemp = null
	
		depthtemp = surface_require(depthtemp, render_width, render_height)
		
		surface_set_target(depthtemp)
		{
			draw_clear(c_white)
			draw_surface(render_surface_depth, 0, 0)
		}
		surface_reset_target()
	
		surface_copy(render_surface_depth, 0, 0, depthtemp)
	
		surface_free(depthtemp)
		
		/*
		if (render_camera_outline && render_camera.value[e_value.CAM_OUTLINE_NORMAL]) // Initiate when needed
		{
			var normaltemp = null
			normaltemp = surface_require(normaltemp, render_width, render_height)
			
			surface_set_target(normaltemp)
			{
				draw_clear(c_white)
				draw_surface(render_surface_normal, 0, 0)
			}
			surface_reset_target()
	
			surface_copy(render_surface_normal, 0, 0, normaltemp)
			
			surface_free(normaltemp)
		}
		*/
	}
	
	if (render_glow && sceneeffects)
		render_surface_glow_cache = surface_require(render_surface_glow_cache, render_width, render_height)
	
	// Outline
	if (render_camera_outline && sceneeffects && render_quality = 2)
		finalsurf = render_high_outline(finalsurf)
	render_update_effects()

	// Glow (Affected by DOF)
	if (project_render_dof_affect_glow)
	{
		// Glow
		if (render_glow && sceneeffects)
			finalsurf = render_high_glow(finalsurf)
		render_update_effects()
	
		// Glow (Falloff)
		if (render_glow_falloff && sceneeffects)
			finalsurf = render_high_glow(finalsurf, true)
		render_update_effects()
	}
	
	// DOF
	if (render_camera_dof && sceneeffects)
		finalsurf = render_high_dof(finalsurf)
	render_update_effects()
	
	// Glow (Not affected by DOF)
	if (!project_render_dof_affect_glow)
	{
		// Glow
		if (render_glow && sceneeffects)
			finalsurf = render_high_glow(finalsurf)
		render_update_effects()
	
		// Glow (Falloff)
		if (render_glow_falloff && sceneeffects)
			finalsurf = render_high_glow(finalsurf, true)
		render_update_effects()
	}
	
	// Bloom
	if (render_camera_bloom && posteffects)
		finalsurf = render_high_bloom(finalsurf)
	render_update_effects()
	
	// Lens dirt overlay (sceneeffects applies to glow, posteffects applies to bloom)
	if (render_camera_lens_dirt && (sceneeffects || posteffects))
		finalsurf = render_high_lens_dirt(finalsurf)
	render_update_effects()
	
	// Chromatic aberration
	if (render_camera_ca && posteffects)
		finalsurf = render_high_ca(finalsurf)
	render_update_effects()
	
	// Distort
	if (render_camera_distort && posteffects)
		finalsurf = render_high_distort(finalsurf)
	render_update_effects()
	
	// Heat distortion
	if (render_camera_heat_distortion && posteffects)
		finalsurf = render_high_heat_distortion(finalsurf)
	render_update_effects()
	
	// Color correction
	if (render_camera_color_correction && posteffects)
		finalsurf = render_high_cc(finalsurf)
	render_update_effects()
	
	// Film grain
	if (render_camera_grain && posteffects)
		finalsurf = render_high_grain(finalsurf)
	render_update_effects()
	
	// Vertex snap (PS1 style)
	if (render_camera_vertex_snap && posteffects)
		finalsurf = render_high_vertex_snap(finalsurf)
	render_update_effects()
	
	// Vignette
	if (render_camera_vignette && posteffects)
		finalsurf = render_high_vignette(finalsurf)
	render_update_effects()
	
	// Black lines
	if (render_camera_black_lines && posteffects)
		finalsurf = render_high_black_lines(finalsurf)
	render_update_effects()
	
	// VHS
	if (render_camera_vhs && posteffects)
		finalsurf = render_high_vhs(finalsurf)
	render_update_effects()
	
	// SMAA
	if (app.project_render_aa && render_smaa && posteffects) {
		finalsurf = render_high_smaa(finalsurf)
	}
	render_update_effects()
	
	// 2D overlay (camera colors/watermark)
	if (render_overlay && posteffects)
		finalsurf = render_high_overlay(finalsurf)
	render_update_effects()
	
	return finalsurf
}