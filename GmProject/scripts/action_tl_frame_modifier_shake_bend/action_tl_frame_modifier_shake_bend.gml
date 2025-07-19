/// action_tl_frame_modifier_shake_bend(enable)
/// @arg enable

function action_tl_frame_modifier_shake_bend(enable)
{
	tl_value_set_start(action_tl_frame_modifier_shake_bend, false)
	tl_value_set(e_value.MODIFIER_SHAKE_BEND, enable, false)
	tl_value_set_done()
}
