/// tl_update_modifier()

function tl_update_modifier()
{
	// Modifier shake
	if (value[e_value.MODIFIER_SHAKE] && value[e_value.MODIFIER_SHAKE_INTENSITY] != 0)
	{
		var shakeoffset, shakestrength;
		shakeoffset =  value[e_value.MODIFIER_SHAKE_OFFSET] + (value[e_value.MODIFIER_SHAKE_OFFSET_AUTOMATIC]) ? modifier_shake_auto_offset : 0
			
		if (value[e_value.MODIFIER_SHAKE_KEYFRAME_INFLUENCE] > 0.0) 
			shakestrength = value[e_value.MODIFIER_SHAKE_INTENSITY] * blend_value(1, dsin(keyframe_progress_ease * 180), value[e_value.MODIFIER_SHAKE_KEYFRAME_INFLUENCE])
		else
			shakestrength = value[e_value.MODIFIER_SHAKE_INTENSITY] * blend_value(1, 1 - dsin(keyframe_progress_ease * 180), abs(value[e_value.MODIFIER_SHAKE_KEYFRAME_INFLUENCE]))
			
		if (shakestrength != 0 && (modifier_step_prev[0] != modifier_step || modifier_step_prev[1] != shakestrength))
		{
			if (value[e_value.MODIFIER_SHAKE_POSITION])
				modifier_shake_pos = generate_shake_value(modifier_step, shakestrength * value[e_value.MODIFIER_SHAKE_POSITION_POWER], shakeoffset, false)
				
			if (value[e_value.MODIFIER_SHAKE_ROTATION])
				modifier_shake_rot = generate_shake_value(modifier_step, shakestrength * value[e_value.MODIFIER_SHAKE_ROTATION_POWER], shakeoffset + 100, false)
				
			if (value[e_value.MODIFIER_SHAKE_BEND])
				modifier_shake_bend = generate_shake_value(modifier_step, shakestrength * value[e_value.MODIFIER_SHAKE_BEND_POWER], shakeoffset + 200, false)
		}
		
		modifier_step_prev = vec2(modifier_step, shakestrength)
	} else {
		modifier_shake_pos = vec3(0)
		modifier_shake_rot = vec3(0)
		modifier_shake_bend = vec3(0)
	}
}
