/// action_tl_frame_modifier_shake_position(enable)
/// @arg enable

function action_tl_frame_modifier_shake_position(enable)
{
	tl_value_set_start(action_tl_frame_modifier_shake_position, false)
	tl_value_set(e_value.MODIFIER_SHAKE_POSITION, enable, false)
	tl_value_set_done()
}
