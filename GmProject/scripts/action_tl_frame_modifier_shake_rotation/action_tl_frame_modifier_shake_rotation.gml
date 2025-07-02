/// action_tl_frame_modifier_shake_rotation(enable)
/// @arg enable

function action_tl_frame_modifier_shake_rotation(enable)
{
	tl_value_set_start(action_tl_frame_modifier_shake_rotation, false)
	tl_value_set(e_value.MODIFIER_SHAKE_ROTATION, enable, false)
	tl_value_set_done()
}
