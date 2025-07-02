/// tab_frame_editor_modifier()

function tab_frame_editor_modifier()
{
	if (tl_edit.type == e_tl_type.CAMERA || tl_edit.type == e_tl_type.PARTICLE_SPAWNER)
		return 0
	
	// Modifier
	tab_control_switch()
	draw_button_collapse("modifier", collapse_map[?"modifier"], null, true, "frameeditormodifier")
	tab_next()
	
	if (collapse_map[?"modifier"])
	{
		tab_collapse_start()
		
		//Modifier Frame skip
		tab_control_switch()
		draw_button_collapse("modifierframeskip", collapse_map[?"modifierframeskip"], action_tl_frame_modifier_frameskip, tl_edit.value[e_value.MODIFIER_FRAMESKIP], "frameeditormodifierframeskip")
		tab_next()
		
		if (collapse_map[?"modifierframeskip"] && tl_edit.value[e_value.MODIFIER_FRAMESKIP])
		{
			tab_collapse_start()
		
				tab_control_dragger()
				draw_dragger("frameeditormodifierframeskipvalue", dx, dy, dragger_width, tl_edit.value[e_value.MODIFIER_FRAMESKIP_VALUE], 0.01, 0.01, no_limit, 1, 0.01, tab.constraints.tbx_modifier_frameskip_value, action_tl_frame_modifier_frameskip_value)
				tab_next()
		
			tab_collapse_end()
		}
		
		// Modifier Shake
		tab_control_switch()
		draw_button_collapse("modifiershake", collapse_map[?"modifiershake"], action_tl_frame_modifier_shake, tl_edit.value[e_value.MODIFIER_SHAKE], "frameeditormodifiershake")
		tab_next()
		
		if (collapse_map[?"modifiershake"] && tl_edit.value[e_value.MODIFIER_SHAKE])
		{
			tab_collapse_start()
		
				tab_control_switch()
				draw_switch("frameeditormodifiershakeposition", dx, dy, tl_edit.value[e_value.MODIFIER_SHAKE_POSITION], action_tl_frame_modifier_shake_position)
				tab_next()
		
				tab_control_switch()
				draw_switch("frameeditormodifiershakerotation", dx, dy, tl_edit.value[e_value.MODIFIER_SHAKE_ROTATION], action_tl_frame_modifier_shake_rotation)
				tab_next()
				
				tab_control_dragger()
				draw_dragger("frameeditormodifiershakeintensity", dx, dy, dragger_width, round(tl_edit.value[e_value.MODIFIER_SHAKE_INTENSITY] * 1000) / 10, 0.1, 0, no_limit, 1, 0.1, tab.constraints.tbx_modifier_shake_intensity, action_tl_frame_modifier_shake_intensity)
				tab_next()
				
				tab_control_dragger()
				draw_dragger("frameeditormodifiershakespeed", dx, dy, dragger_width, round(tl_edit.value[e_value.MODIFIER_SHAKE_SPEED] * 1000) / 10, 0.1, 0, no_limit, 1, 0.1, tab.constraints.tbx_modifier_shake_speed, action_tl_frame_modifier_shake_speed)
				tab_next()
				
				tab_control_dragger()
				draw_dragger("frameeditormodifiershakeoffset", dx, dy, dragger_width, round(tl_edit.value[e_value.MODIFIER_SHAKE_OFFSET] * 100) / 100, 0.1, -no_limit, no_limit, 0, 0.01, tab.constraints.tbx_modifier_shake_offset, action_tl_frame_modifier_shake_offset)
				tab_next()
		
			tab_collapse_end()
		}
		tab_collapse_end()
	}
}