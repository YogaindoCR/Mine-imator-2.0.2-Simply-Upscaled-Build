/// action_project_render_indirect_raystep(size)
/// @arg size

function action_project_render_ssao_samples(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_ssao_samples, project_render_ssao_samples, project_render_ssao_samples * add + val, 1)
		
	project_render_ssao_samples = project_render_ssao_samples * add + val
	render_samples = -1
}