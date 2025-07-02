/// action_project_render_subsurface_strength(size)
/// @arg size

function action_project_render_subsurface_strength(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_subsurface_strength, project_render_subsurface_strength, project_render_subsurface_strength * add + val / 100, 1)
	else
		val *= 100
		
	project_render_subsurface_strength = project_render_subsurface_strength * add + val / 100
	render_samples = -1
}