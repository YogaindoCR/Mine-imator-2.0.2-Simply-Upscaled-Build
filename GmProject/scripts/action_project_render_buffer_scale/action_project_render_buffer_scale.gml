/// action_project_render_buffer_scale(size)
/// @arg size

function action_project_render_buffer_scale(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_buffer_scale, project_render_buffer_scale, project_render_buffer_scale * add + val, 1)
		
	project_render_buffer_scale = project_render_buffer_scale * add + val
	render_samples = -1
}