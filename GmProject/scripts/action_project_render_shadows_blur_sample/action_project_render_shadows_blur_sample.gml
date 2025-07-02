/// action_project_render_shadows_blur_sample(value, add)
/// @arg value
/// @arg add

function action_project_render_shadows_blur_sample(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_shadows_blur_sample, project_render_shadows_blur_sample, project_render_shadows_blur_sample * add + val, 1)
	
	project_render_shadows_blur_sample = project_render_shadows_blur_sample * add + val
}
