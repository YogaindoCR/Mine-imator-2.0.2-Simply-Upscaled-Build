/// render_high_vertex_snap(basesurf)
/// @arg basesurf
/// @desc Applies PS1-style vertex snapping effect by quantizing the rendered image to a lower resolution grid

function render_high_vertex_snap(prevsurf)
{
	var snap_amount = render_camera.value[e_value.CAM_VERTEX_SNAP_AMOUNT];
	
	if (snap_amount <= 1)
		return prevsurf;
		
	var resultsurf = render_high_get_apply_surf();
	
	// Calculate snapped resolution
	var snap_width  = max(1, floor(render_width  / snap_amount));
	var snap_height = max(1, floor(render_height / snap_amount));
	
	// Create temporary surface
	var temp_surf = surface_create(snap_width, snap_height);
	if (!surface_exists(temp_surf)) return prevsurf;
	
	// Calculate exact scaling ratio to avoid rounding mismatch
	var scale_x = snap_width  / render_width;
	var scale_y = snap_height / render_height;
	
	var gpufilterprev = gpu_get_tex_filter()
	
	// Downscale accurately
	surface_set_target(temp_surf);
	{
		draw_clear_alpha(c_black, 0);
		gpu_set_tex_filter(false);
		draw_surface_ext(prevsurf, 0, 0, scale_x, scale_y, 0, c_white, 1);
		gpu_set_tex_filter(true);
	}
	surface_reset_target();
	
	// Upscale accurately back to result
	surface_set_target(resultsurf);
	{
		draw_clear_alpha(c_black, 0);
		gpu_set_tex_filter(false);
		
		// Calculate upscale ratio to perfectly fit the render surface
		var upscale_x = render_width  / snap_width;
		var upscale_y = render_height / snap_height;
		
		draw_surface_ext(temp_surf, 0, 0, upscale_x, upscale_y, 0, c_white, 1);
		
		gpu_set_tex_filter(true);
	}
	surface_reset_target();
	
	surface_free(temp_surf);
	
	gpu_set_tex_filter(gpufilterprev);
	
	return resultsurf;
}