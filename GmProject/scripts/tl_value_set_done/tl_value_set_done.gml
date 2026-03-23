/// tl_value_set_done()

function tl_value_set_done()
{
	with (app)
	{
		tl_update_matrix()
		
		// Record keyframes functionality
		if (timeline_record_keyframes)
		{
			timeline_playing = true
			if (timeline_record_time_reset && timeline_record_time_last = timeline_marker)
			{
				timeline_playing_start_time = current_time
				timeline_record_time_reset = false
			}
		}
	}
}