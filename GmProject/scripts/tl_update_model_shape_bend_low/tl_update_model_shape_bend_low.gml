/// tl_update_model_shape_bend_low()
/// @desc Updates the shapes of the model part if the bending was changed since the last call.

function tl_update_model_shape_bend_low()
{
	var bend = vec3(value_inherit[e_value.BEND_ANGLE_X],
					value_inherit[e_value.BEND_ANGLE_Y],
					value_inherit[e_value.BEND_ANGLE_Z]);
	
	// No change
	if (vec3_equals(bend_rot_last, bend) && bend_model_part_last = model_part)
		return 0
	
	// Invalid part, no bending or no shapes
	if (model_part = null || model_part.bend_part = null || model_part.shape_list = null)
		return 0
	
	if (ds_map_size(model_shape_vbuffer_map_cache) > 1000)
	{
		var key = ds_map_find_first(model_shape_vbuffer_map_cache)
		for (var i = 0; i < 100; i++)
		{
			var vbuf = model_shape_vbuffer_map_cache[? key]
			
			vbuffer_destroy(vbuf)
			
			var keyprev = key
			key = ds_map_find_next(model_shape_vbuffer_map_cache, key)
			ds_map_delete(model_shape_vbuffer_map_cache, keyprev)
		}
	}
			
	// Create map if unavailable
	if (model_shape_vbuffer_map = null)
	{
	    model_shape_vbuffer_map = ds_map_create();
	    model_shape_vbuffer_map_cache = ds_map_create();
	}

	bend_rot_last = bend;
	bend_model_part_last = model_part;

	model_part_fill_shape_vbuffer_map_low(model_part, model_shape_vbuffer_map, model_shape_alpha_map, bend_rot_last, model_shape_vbuffer_map_cache);
}
