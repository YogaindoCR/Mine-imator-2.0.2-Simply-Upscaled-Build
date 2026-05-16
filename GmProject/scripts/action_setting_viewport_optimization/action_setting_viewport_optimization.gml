/// action_setting_viewport_optimization(value)
/// @arg value

function action_setting_viewport_optimization(val)
{
	setting_viewport_optimization = val
	render_low_drawing = 0
	
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
			
			model_shape_vbuffer_map = null
			model_shape_vbuffer_map_cache = null
			
			tl_update_model_shape()
		}
	}
}
