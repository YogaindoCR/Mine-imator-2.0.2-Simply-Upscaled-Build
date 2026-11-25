/// tab_frame_editor_constraints()

function tab_frame_editor_constraints()
{
	// Follow path
	tab_frame_editor_path()
	
	// Look at
	tab_frame_editor_look_at()
	
	// Copy Position, rotation, scale
	tab_control_switch()
	draw_button_collapse("copyconstraint", collapse_map[?"copyconstraint"], null, true, "frameeditorcopyconstraint")
	tab_next()
	if (collapse_map[?"copyconstraint"])
	{
		tab_collapse_start()
		
		tab_frame_editor_copy_pos()
		tab_frame_editor_copy_rot()
		tab_frame_editor_copy_scale()
		
		tab_collapse_end()
	}
	
	// Inverse kinematics
	tab_frame_editor_ik()
	tab_frame_editor_bend_ik()
	
	// Modifier
	tab_frame_editor_modifier()
}
