/// action_tl_frame_light_shadow_blur(value, add)
/// @arg value
/// @arg add

function action_tl_frame_light_shadow_blur(val, add)
{
	tl_value_set_start(action_tl_frame_light_shadow_blur, true)
	tl_value_set(e_value.LIGHT_SHADOW_BLUR, val, add)
	tl_value_set_done()
}
