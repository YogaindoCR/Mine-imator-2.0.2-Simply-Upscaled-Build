/// action_background_godray(godray)
/// @arg twilight

function action_background_godray(godray)
{
	if (!history_undo && !history_redo)
	{
		if (action_tl_select_single(null, e_tl_type.BACKGROUND))
		{
			tl_value_set_start(action_background_godray, true)
			tl_value_set(e_value.BG_GODRAY, godray, false)
			tl_value_set_done()
			return 0
		}
		
		history_set_var(action_background_godray, background_godray, godray, false)
	}
	
	background_godray = godray
}
