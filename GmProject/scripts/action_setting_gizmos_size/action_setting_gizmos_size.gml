/// action_setting_cam_work_pov(size)
/// @arg size

function action_setting_gizmos_size(val, add)
{
	setting_gizmos_size = setting_gizmos_size * add + val
	render_samples = -1
}