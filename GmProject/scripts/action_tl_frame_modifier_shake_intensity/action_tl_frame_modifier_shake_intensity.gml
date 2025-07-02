/// action_tl_frame_modifier_shake_intensity(value, add)
/// @arg value
/// @arg add

function action_tl_frame_modifier_shake_intensity(val, add)
{
	tl_value_set_start(action_tl_frame_modifier_shake_intensity, true)
	tl_value_set(e_value.MODIFIER_SHAKE_INTENSITY, val / 100, add)
	tl_value_set_done()
}
