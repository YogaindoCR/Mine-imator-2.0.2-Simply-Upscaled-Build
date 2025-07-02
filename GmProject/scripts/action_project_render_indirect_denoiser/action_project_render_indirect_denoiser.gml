/// action_project_render_indirect_denoiser(value)
/// @arg value

function action_project_render_indirect_denoiser(val)
{
	
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_indirect_denoiser, project_render_indirect_denoiser, val, 1)
		
	project_render_indirect_denoiser = val
	render_samples = -1
}
