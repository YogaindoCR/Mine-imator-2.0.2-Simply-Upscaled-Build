/// action_project_render_indirect_raystep(size)
/// @arg size

function action_project_render_indirect_raystep(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_indirect_raystep, project_render_indirect_raystep, project_render_indirect_raystep * add + val, 1)
		
	project_render_indirect_raystep = project_render_indirect_raystep * add + val
	render_samples = -1
}