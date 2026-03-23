/// action_tl_record_keyframes()

function action_tl_record_keyframes()
{
	project_changed = true
	timeline_record_keyframes = !timeline_record_keyframes
	
	if (timeline_record_keyframes) {
		action_tl_play(true)
		timeline_record_time_reset = true
		timeline_record_time_last = timeline_marker
		timeline_playing = false
		timeline_record_keyframes = true // Explicit Enable
	}
}