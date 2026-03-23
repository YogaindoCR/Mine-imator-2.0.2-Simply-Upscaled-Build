/// action_tl_frame_look_at_target(target)
/// @arg target

function action_tl_frame_look_at_target(target)
{
	render_low_drawing = -1
	tl_value_set_start(action_tl_frame_look_at_target, false)
	tl_value_set(e_value.LOOK_AT_TARGET, target, false)
	tl_value_set_done()
}