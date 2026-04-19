/// action_toolbar_exportimage_save()

function action_toolbar_exportimage_save()
{
	var fn;
	fn = file_dialog_save_image(project_name)
	
	if (fn = "")
		return 0
	
	export_filename = fn
	
	log("Export image", export_filename)
	
	// Render and save
	render_hidden = popup_exportimage.include_hidden
	render_background = !popup_exportimage.remove_background
	render_watermark = popup_exportimage.watermark
	
	log("Hidden", yesno(render_hidden))
	log("Render background", yesno(render_background))
	log("Watermark", yesno(render_watermark))
	log("High Quality", yesno(popup_exportimage.high_quality))
	log("Size", project_video_width, project_video_height)
	
	window_state = "export_image"
	exportmovie_frame = 0
	export_sample = 0
	exportmovie_start = current_time
	render_samples = -1
	
	// Free up vbuffer cache memory if needed
	if (popup_exportimage.high_quality)
	{
		with(obj_timeline)
		{
			if (model_shape_vbuffer_map_cache != null)
			{
				var key = ds_map_find_first(model_shape_vbuffer_map_cache)
		
				for (var i = 0; i< ds_map_size(model_shape_vbuffer_map_cache); i++)
				{ 
					var vbuf = model_shape_vbuffer_map_cache[? key]
			
					vbuffer_destroy(vbuf)
			
					key = ds_map_find_next(model_shape_vbuffer_map_cache, key)
				}
			
				ds_map_clear(model_shape_vbuffer_map)
				ds_map_clear(model_shape_vbuffer_map_cache)
			
				with (model_part)
					model_shape_vbuffer_map = vbuffer_default
				
				tl_update_model_shape()
			}
		}
	}
				
	if (view_main.quality = e_view_mode.RENDER)
		view_main.quality = e_view_mode.SHADED
	
	if (view_second.quality = e_view_mode.RENDER)
		view_second.quality = e_view_mode.SHADED
}
