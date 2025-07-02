/// action_project_render_indirect_denoiser_strength(size)
/// action_project_render_indirect_denoiser_strength(size)
/// @arg size

function action_project_render_motionblur_power(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_motionblur_power, project_render_motionblur_power, project_render_motionblur_power * add + (val / 100), 1)
		
	project_render_motionblur_power = project_render_motionblur_power * add + (val / 100)
	render_samples = -1
}