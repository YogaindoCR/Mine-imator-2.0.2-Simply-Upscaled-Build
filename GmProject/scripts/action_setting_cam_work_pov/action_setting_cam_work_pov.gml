/// action_setting_cam_work_pov(size)
/// @arg size

function action_setting_cam_work_pov(val, add)
{
	setting_cam_work_pov = setting_cam_work_pov * add + val
	render_samples = -1
}