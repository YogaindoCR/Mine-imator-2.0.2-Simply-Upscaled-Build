/// action_project_render_shadows_blur(value, add)
/// @arg value
/// @arg add

function action_project_render_shadows_blur(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_shadows_blur, project_render_shadows_blur, project_render_shadows_blur * add + val, 1)
	
	project_render_shadows_blur = project_render_shadows_blur * add + val
}
