/// action_project_render_subsurface_quality(size)
/// @arg size

function action_project_render_subsurface_quality(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_subsurface_quality, project_render_subsurface_quality, val, 1)
		
	project_render_subsurface_quality = val
	render_samples = -1
}