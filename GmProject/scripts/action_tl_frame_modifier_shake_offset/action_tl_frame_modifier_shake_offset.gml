/// action_tl_frame_modifier_shake_offset(value, add)
/// @arg value
/// @arg add

function action_tl_frame_modifier_shake_offset(val, add)
{
	tl_value_set_start(action_tl_frame_modifier_shake_offset, true)
	tl_value_set(e_value.MODIFIER_SHAKE_OFFSET, val, add)
	tl_value_set_done()
}
