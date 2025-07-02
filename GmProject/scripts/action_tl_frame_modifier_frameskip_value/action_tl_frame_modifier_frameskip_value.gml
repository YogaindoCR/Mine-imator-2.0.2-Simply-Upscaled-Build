/// action_tl_frame_modifier_shake_offset(value, add)
/// @arg value
/// @arg add

function action_tl_frame_modifier_frameskip_value(val, add)
{
	tl_value_set_start(action_tl_frame_modifier_frameskip_value, true)
	tl_value_set(e_value.MODIFIER_FRAMESKIP_VALUE, val, add)
	tl_value_set_done()
}
