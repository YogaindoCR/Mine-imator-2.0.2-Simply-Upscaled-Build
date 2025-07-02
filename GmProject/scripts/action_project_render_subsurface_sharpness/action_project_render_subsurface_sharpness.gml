/// action_project_render_subsurface_sharpness(value, add)
/// @arg value
/// @arg add

function action_project_render_subsurface_highlight_sharpness(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_subsurface_highlight_sharpness, project_render_subsurface_highlight_sharpness, project_render_subsurface_highlight_sharpness * add + val, 1)
	
	project_render_subsurface_highlight_sharpness = project_render_subsurface_highlight_sharpness * add + val
}
