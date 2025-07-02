/// action_project_render_dof_ghostingfix(value)
/// @arg value

function action_project_render_dof_ghostingfix(val)
{
	
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_dof_ghostingfix, project_render_dof_ghostingfix, val, 1)
		
	project_render_dof_ghostingfix = val
	render_samples = -1
}
