/// action_tl_frame_ik_target_offset(value)
/// @arg value

function action_tl_frame_ik_target_offset(value)
{
	tl_value_set_start(action_tl_frame_ik_target_offset, false)
	tl_value_set(e_value.IK_TARGET_OFFSET, value, false)
	tl_value_set_done()
}