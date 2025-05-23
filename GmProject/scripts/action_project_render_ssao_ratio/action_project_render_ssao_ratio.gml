/// action_project_render_ssao_radius(value, add)
/// @arg value
/// @arg add

function action_project_render_ssao_ratio(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_ssao_ratio, project_render_ssao_ratio, project_render_ssao_ratio * add + val, 1)
	
	project_render_ssao_ratio = project_render_ssao_ratio * add + val
}
