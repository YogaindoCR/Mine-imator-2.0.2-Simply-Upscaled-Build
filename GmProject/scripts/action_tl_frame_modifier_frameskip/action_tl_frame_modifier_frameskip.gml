/// action_tl_frame_modifier_frameskip(enable)
/// @arg enable

function action_tl_frame_modifier_frameskip(enable)
{
	tl_value_set_start(action_tl_frame_modifier_frameskip, false)
	tl_value_set(e_value.MODIFIER_FRAMESKIP, enable, false)
	tl_value_set_done()
}
