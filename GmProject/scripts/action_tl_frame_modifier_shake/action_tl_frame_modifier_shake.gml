/// action_tl_frame_modifier_shake(enable)
/// @arg enable

function action_tl_frame_modifier_shake(enable)
{
	tl_value_set_start(action_tl_frame_modifier_shake, false)
	tl_value_set(e_value.MODIFIER_SHAKE, enable, false)
	tl_value_set_done()
}
