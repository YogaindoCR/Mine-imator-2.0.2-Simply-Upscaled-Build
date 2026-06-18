/// action_project_render_godray_step(size)
/// @arg size

function action_project_render_godray_step(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_godray_step, project_render_godray_step, project_render_godray_step * add + val, 1)
		
	project_render_godray_step = project_render_godray_step * add + val
	render_samples = -1
}