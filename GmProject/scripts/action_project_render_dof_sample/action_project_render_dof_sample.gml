/// action_project_render_indirect_raystep(size)
/// @arg size

function action_project_render_dof_sample(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_dof_sample, project_render_dof_sample, project_render_dof_sample * add + val, 1)
		
	project_render_dof_sample = project_render_dof_sample * add + val
	render_samples = -1
}