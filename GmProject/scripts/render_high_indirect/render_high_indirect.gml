/// render_high_indirect()
/// @desc Ray traces shadow surf for light bounces, returns indirect lighting buffer

function render_high_indirect()
{
	// Raytrace
	render_surface_hdr[0] = surface_require(render_surface_hdr[0], render_width, render_height, true, true)
	render_surface_hdr[2] = surface_require(render_surface_hdr[2], render_width, render_height, true, true)
	surface_set_target(render_surface_hdr[0])
	{
		gpu_set_texrepeat(false)
		draw_clear_alpha(c_black, 1)
		
		if (project_render_engine) {
			render_shader_obj = shader_map[?shader_high_raytrace_EX]
		} else {
			render_shader_obj = shader_map[?shader_high_raytrace]
		}
		
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_high_raytrace_set(e_raytrace.INDIRECT)
		}
		
		draw_blank(0, 0, render_width, render_height)
		
		with (render_shader_obj)
			shader_clear()
		gpu_set_texrepeat(true)
	}
	surface_reset_target()
	
	// Resolve
	render_surface_hdr[1] = surface_require(render_surface_hdr[1], render_width, render_height, true, true)
	surface_set_target(render_surface_hdr[1])
	{
		draw_clear_alpha(c_black, 0)
			
		if (project_render_engine) {
			render_shader_obj = shader_map[?shader_high_raytrace_resolve_EX]
		} else {
			render_shader_obj = shader_map[?shader_high_raytrace_resolve]
		}
		
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_high_raytrace_resolve_set(true)
		}
		
		draw_surface_exists(render_surface_hdr[0], 0, 0)
		
		with (render_shader_obj)
			shader_clear()
	}
	surface_reset_target()
	
	// Blur result
	if (project_render_indirect_blur_radius > 0)
	{
		surface_set_target(render_surface_hdr[0])
		{
			draw_clear_alpha(c_black, 0)
	
			if (app.project_render_engine) {
				render_shader_obj = shader_map[?shader_high_indirect_blur_EX]
			} else {
				render_shader_obj = shader_map[?shader_high_indirect_blur]
			}
			
			with (render_shader_obj)
			{
				shader_set(shader)
				if (app.project_render_engine)
					shader_high_indirect_blur_EX_set()
				else
					shader_high_indirect_blur_set()
			}
			
			draw_surface_exists(render_surface_hdr[1], 0, 0)
			
			with (render_shader_obj)
				shader_clear()
		}
		surface_reset_target()
	}
	
	// Apply Bilateral Denoiser (optional final pass)
	if (app.project_render_indirect_denoiser)
	{
		// Denoise from whatever is currently in indirectsurf to the other buffer
		surface_set_target(render_surface_hdr[2])
		{
			draw_clear_alpha(c_black, 0)

			render_shader_obj = shader_map[?shader_bilateral_blur]

			with (render_shader_obj)
			{
				shader_set(shader)
				shader_bilateral_blur_set(render_surface_hdr[0], true)
			}

			draw_surface(render_surface_hdr[0], 0, 0) // Source: render_surface_hdr[0]

			with (render_shader_obj)
				shader_clear()
		}
		surface_reset_target()
		
		// Pass 2
		surface_set_target(render_surface_hdr[1])
		{
			draw_clear_alpha(c_black, 0)

			render_shader_obj = shader_map[?shader_bilateral_blur]

			with (render_shader_obj)
			{
				shader_set(shader)
				shader_bilateral_blur_set(render_surface_hdr[2], false)
			}

			draw_surface(render_surface_hdr[2], 0, 0) // Source: render_surface_hdr[2]

			with (render_shader_obj)
				shader_clear()
		}
		surface_reset_target()
	}
	
	// Add
	surface_set_target(render_surface_shadows)
	{
		gpu_set_blendmode(bm_add)
		draw_surface_exists(app.project_render_indirect_denoiser ? render_surface_hdr[1] : render_surface_hdr[0], 0, 0)
		gpu_set_blendmode(bm_normal)
	}
	surface_reset_target()
	
	if (render_pass = e_render_pass.INDIRECT)
		render_pass_surf = surface_duplicate(app.project_render_indirect_denoiser ? render_surface_hdr[1] : render_surface_hdr[0])
	
	if (render_pass = e_render_pass.INDIRECT_SHADOWS)
		render_pass_surf = surface_duplicate(render_surface_shadows)
}
