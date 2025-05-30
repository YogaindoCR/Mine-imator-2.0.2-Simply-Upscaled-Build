/// action_project_render_indirect_denoiser_strength(size)
/// @arg size

function action_project_render_indirect_denoiser_strength(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_indirect_denoiser_strength, project_render_indirect_denoiser_strength, project_render_indirect_denoiser_strength * add + val, 1)
		
	project_render_indirect_denoiser_strength = project_render_indirect_denoiser_strength * add + val
	render_samples = -1
}