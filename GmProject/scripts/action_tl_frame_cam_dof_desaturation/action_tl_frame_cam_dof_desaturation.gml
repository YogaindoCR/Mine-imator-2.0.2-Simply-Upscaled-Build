/// action_tl_frame_cam_dof_desaturation(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_dof_desaturation(val, add)
{
	tl_value_set_start(action_tl_frame_cam_dof_desaturation, true)
	tl_value_set(e_value.CAM_DOF_DESATURATION, val / 100, add)
	tl_value_set_done()
}
