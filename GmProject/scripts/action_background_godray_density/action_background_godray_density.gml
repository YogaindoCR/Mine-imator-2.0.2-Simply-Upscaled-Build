/// action_background_godray_density(value, add)
/// @arg value
/// @arg add

function action_background_godray_density(val, add)
{
	if (!history_undo && !history_redo)
	{
		if (action_tl_select_single(null, e_tl_type.BACKGROUND))
		{
			tl_value_set_start(background_godray_density, true)
			tl_value_set(e_value.BG_GODRAY_DENSITY, val, add)
			tl_value_set_done()
			return 0
		}
		
		history_set_var(action_background_godray_density, background_godray_density, background_godray_density * add + val, true)
	}
	
	background_godray_density = background_godray_density * add + val
}
