/// render_world_tl_shadow()
/// @desc Renders the 3D model of the timeline instance for shadowpass.

function render_world_tl_shadow()
{
	// No 3D representation?
	if (type = e_tl_type.CHARACTER ||
		type = e_tl_type.SPECIAL_BLOCK ||
		type = e_tl_type.FOLDER ||
		type = e_tl_type.BACKGROUND ||
		type = e_tl_type.AUDIO ||
		type = e_tl_type.PATH_POINT ||
		type = e_tl_type.SPOT_LIGHT ||
		type = e_tl_type.POINT_LIGHT ||
		type = e_tl_type.CAMERA)
		return 0
	
	if (type = e_tl_type.MODEL && (temp.model = null || temp.model.model_format = e_model_format.MIMODEL))
		return 0
	
	if (!app.place_tl_render && (placed || parent_is_placed))
		return 0
	
	// Invisible?
	if (!render_visible) 
		return 0
	
	// Not registered on shadow depth testing?
	if (!shadows && (render_mode = e_render_mode.HIGH_LIGHT_SUN_DEPTH ||
		 render_mode = e_render_mode.HIGH_LIGHT_SPOT_DEPTH ||
		 render_mode = e_render_mode.HIGH_LIGHT_POINT_DEPTH))
		return 0
		
	if ((value_inherit[e_value.ALPHA]) = 0)
		return 0
	
	if (depth_ignore)
		return 0
		
	if (app.project_render_performance_mode && (render_mode = e_render_mode.HIGH_LIGHT_POINT_DEPTH || render_mode = e_render_mode.HIGH_LIGHT_SPOT_DEPTH) && point3D_distance(render_light_from, world_pos) > render_light_far + (16 * max(value[e_value.SCA_X], value[e_value.SCA_Y], value[e_value.SCA_Z])) + app.project_render_performance_mode_light_occlusion_distance && type != e_tl_type.SCENERY)
		return 0
	
	// Only render glow effect?
	if ((glow && only_render_glow))
		return 0
	
	/*
	// Ignore any depth test for volume mode
	if (volume_mode && !shadowpass && !shadowdepthpass)
		return 0
	*/
	
	// Set render options
	render_set_culling(!backfaces)
	shader_texture_filter_linear = texture_blur
	shader_texture_filter_mipmap = (app.project_render_texture_filtering && texture_filtering)
	
	// Light and Object Tags linking
	if (render_light_tl != null && render_light_tl != "Main" && object_tag != render_light_tl)
	{
		if (shader_uniform_ignore != true)
		{
			shader_uniform_ignore = true
			render_set_uniform("uIgnore", shader_uniform_ignore)
		}
	} 
	else
	{
		if (shader_uniform_ignore != false)
		{
			shader_uniform_ignore = false
			render_set_uniform("uIgnore", shader_uniform_ignore)
		}
	}
	
	if (shader_uniform_ignore_int != object_tag_int)
	{
		shader_uniform_ignore_int = object_tag_int
		render_set_uniform_int("uIgnoreInt", shader_uniform_ignore_int)
	}
	
	if (shader_blend_color != value_inherit[e_value.RGB_MUL] || shader_blend_color != value_inherit[e_value.ALPHA])
	{
		shader_blend_color = value_inherit[e_value.RGB_MUL]
		shader_blend_alpha = value_inherit[e_value.ALPHA]
		render_set_uniform_color("uBlendColor", shader_blend_color, shader_blend_alpha)
	}
	
	if (!render_alpha_hash_force)
	{
		render_alpha_hash = (alpha_mode = e_alpha_mode.DEFAULT ? app.project_render_alpha_mode : alpha_mode)
		render_set_uniform_int("uAlphaHash", render_alpha_hash)
	}
	
	if (value_inherit[e_value.EMISSIVE] != shader_uniform_emissive)
	{
		shader_uniform_emissive = value_inherit[e_value.EMISSIVE]
		render_set_uniform("uEmissive", shader_uniform_emissive)
	}
	
	if (value_inherit[e_value.METALLIC] != shader_uniform_metallic)
	{
		shader_uniform_metallic = value_inherit[e_value.METALLIC]
		render_set_uniform("uMetallic", shader_uniform_metallic)
	}
	
	if (value_inherit[e_value.ROUGHNESS] != shader_uniform_roughness)
	{
		shader_uniform_roughness = value_inherit[e_value.ROUGHNESS]
		render_set_uniform("uRoughness", shader_uniform_roughness)
	}
	
	if (value_inherit[e_value.NORMAL_STRENGTH] != shader_uniform_normal_strength)
	{
		shader_uniform_normal_strength = value_inherit[e_value.NORMAL_STRENGTH]
		render_set_uniform("uNormalStrength", shader_uniform_normal_strength)
	}
	
	if (wind != shader_uniform_wind)
	{
		shader_uniform_wind = wind
		render_set_uniform("uWindEnable", shader_uniform_wind)
	}
	
	if (wind_terrain != shader_uniform_wind_terrain)
	{
		shader_uniform_wind_terrain = wind_terrain
		render_set_uniform("uWindTerrain", shader_uniform_wind_terrain)
	}
	
	if (value_inherit[e_value.WIND_INFLUENCE] != shader_uniform_wind_strength)
	{
		shader_uniform_wind_strength = app.background_wind_strength * app.setting_wind_enable * value_inherit[e_value.WIND_INFLUENCE]
		render_set_uniform("uWindStrength", shader_uniform_wind_strength)
		render_set_uniform("uWindDirectionalStrength", shader_uniform_wind_strength * app.background_wind_directional_strength) 
	}
	
	// Subsurface
	if ((value_inherit[e_value.SUBSURFACE] > 0 || shader_uniform_sss))
	{
		shader_uniform_sss_color = value_inherit[e_value.SUBSURFACE_COLOR]
		
		render_set_uniform("uSSS", value_inherit[e_value.SUBSURFACE])
		render_set_uniform_vec3("uSSSRadius", value_inherit[e_value.SUBSURFACE_RADIUS_RED], value_inherit[e_value.SUBSURFACE_RADIUS_GREEN], value_inherit[e_value.SUBSURFACE_RADIUS_BLUE])
		render_set_uniform_color("uSSSColor", shader_uniform_sss_color, 1.0)
		
		shader_uniform_sss = value_inherit[e_value.SUBSURFACE] > 0
	}
	
	// Render
	render_world_tl_obj()
}
