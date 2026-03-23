/// action_background_image_probe_strength(value, add)
/// @arg value
/// @arg add

function action_background_image_probe_strength(val, add)
{
	if (!history_undo && !history_redo)
	{
		if (action_tl_select_single(null, e_tl_type.BACKGROUND))
		{
			tl_value_set_start(action_background_image_probe_strength, true)
			tl_value_set(e_value.BG_IMAGE_PROBE_STRENGTH, val / 100, add)
			tl_value_set_done()
			return 0
		}
		
		history_set_var(action_background_image_probe_strength, background_image_probe_strength, background_image_probe_strength * add + val, true)
	}
	
	background_image_probe_strength = background_image_probe_strength * add + val / 100
}
