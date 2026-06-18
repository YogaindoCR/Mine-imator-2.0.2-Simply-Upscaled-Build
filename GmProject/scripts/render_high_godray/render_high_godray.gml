/// render_high_godray(basesurf)
/// @arg basesurf

function render_high_godray(prevsurf)
{
	render_surface[2] = surface_require(render_surface[2], render_width, render_height, false, true)
	render_surface[3] = surface_require(render_surface[3], render_width, render_height, false, true)
	var godray_surf = render_surface[2]
	var resultsurf = render_surface[3]
	
	surface_set_target(godray_surf)
	{
		gpu_set_blendmode(bm_normal)
		render_shader_obj = shader_map[?shader_high_godray]
			
		draw_clear(c_black)
			
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_high_godray_set(render_surface_scene_test)
		}
		
		draw_blank(0, 0, render_width, render_height) // Blank quad
		with (render_shader_obj)
			shader_clear()
	}
	surface_reset_target()
	
	// Apply Godray
	
	/*
	surface_set_target(prevsurf)
	{
		gpu_set_blendmode(bm_add)
		draw_surface(godray_surf, 0, 0)
		gpu_set_blendmode(bm_normal)
	}
	surface_reset_target()
	*/
	
	surface_set_target(resultsurf)
	{
		draw_clear_alpha(c_black, 0)
		
		render_shader_obj = shader_map[?shader_add]
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_add_set(godray_surf, 1, c_white, 1, "screen")
		}
		draw_surface_exists(prevsurf, 0, 0)
		with (render_shader_obj)
			shader_clear()
	}
	surface_reset_target()
	surface_copy(prevsurf, 0, 0, resultsurf)
	
	return;
}