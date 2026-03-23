/// render_world_tl()
/// @desc Renders the 3D model of the timeline instance.

function render_world_tl()
{
	// No 3D representation?
	if (type = e_tl_type.CHARACTER ||
		type = e_tl_type.SPECIAL_BLOCK ||
		type = e_tl_type.FOLDER ||
		type = e_tl_type.BACKGROUND ||
		type = e_tl_type.AUDIO ||
		type = e_tl_type.PATH_POINT)
		return 0
	
	if (type = e_tl_type.MODEL && (temp.model = null || temp.model.model_format = e_model_format.MIMODEL))
		return 0
	
	if (!app.place_tl_render && (placed || parent_is_placed))
		return 0
	
	// Invisible?
	if (!render_visible)
		return 0
	
	// Only render glow effect?
	if ((glow && only_render_glow) && render_mode != e_render_mode.COLOR_GLOW)
		return 0
		
	/*
	var shadowdepthpass = (render_mode = e_render_mode.HIGH_LIGHT_SUN_DEPTH ||
		 render_mode = e_render_mode.HIGH_LIGHT_SPOT_DEPTH ||
		 render_mode = e_render_mode.HIGH_LIGHT_POINT_DEPTH)
	*/
	
	// Not registered on shadow depth testing?
	if (!shadows && (render_mode = e_render_mode.HIGH_LIGHT_SUN_DEPTH ||
		 render_mode = e_render_mode.HIGH_LIGHT_SPOT_DEPTH ||
		 render_mode = e_render_mode.HIGH_LIGHT_POINT_DEPTH))
		return 0
	
	/*
	if (app.project_render_performance_mode && (render_mode = e_render_mode.HIGH_LIGHT_POINT_DEPTH || render_mode = e_render_mode.HIGH_LIGHT_SPOT_DEPTH) && point3D_distance(render_light_from, world_pos) > render_light_far + (16 * max(value[e_value.SCA_X], value[e_value.SCA_Y], value[e_value.SCA_Z])) + app.project_render_performance_mode_light_occlusion_distance && type != e_tl_type.SCENERY)
		return 0
	*/
		
	// Click mode
	if (render_mode = e_render_mode.CLICK)
	{
		if (selected || lock || !tl_update_list_filter(id)) // Already selected when clicking?
			return 0
		
		render_set_uniform_color("uReplaceColor", id, 1)
	}
	
	if (render_mode = e_render_mode.SCENE_TEST || render_mode = e_render_mode.WOLVIZA)
	{
		render_set_uniform_color("uReplaceColor", c_white, 1)
	}
	
	// Outlined?
	else if (render_mode = e_render_mode.SELECT && !parent_is_selected && !selected)
		return 0
		
	else if (render_mode = e_render_mode.PLACE && !parent_is_placed && !placed)
		return 0
	
	// Box for clicking
	if (type = e_tl_type.PARTICLE_SPAWNER ||
		type = e_tl_type.SPOT_LIGHT ||
		type = e_tl_type.POINT_LIGHT ||
		type = e_tl_type.CAMERA)
	{
		if (render_mode = e_render_mode.CLICK)
		{
			render_set_texture(shape_texture)
			vbuffer_render(render_click_box, world_pos)
		}
		
		if (type != e_tl_type.PARTICLE_SPAWNER) // Only proceed with rendering for particles
			return 0
	}
	
	if ((value_inherit[e_value.ALPHA] * 1000) = 0)
		return 0
	
	if (depth_ignore && render_mode != e_render_mode.COLOR &&
		 render_mode != e_render_mode.COLOR_FOG &&
		 render_mode != e_render_mode.COLOR_FOG_LIGHTS &&
		 render_mode != e_render_mode.CLICK &&
		 render_mode != e_render_mode.COLOR_GLOW &&
		 render_mode != e_render_mode.SELECT)
		return 0
	
	/*
	var shadowpass = (render_mode = e_render_mode.HIGH_LIGHT_SPOT ||
	     render_mode = e_render_mode.HIGH_LIGHT_POINT||
		 render_mode = e_render_mode.HIGH_LIGHT_SPOT_EX ||
	     render_mode = e_render_mode.HIGH_LIGHT_POINT_EX||
	     render_mode = e_render_mode.HIGH_LIGHT_POINT_SHADOWLESS)
	*/
	
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
	/*
	if ( shadowpass && 
		 string(render_light_tl.object_tag) != "Main" && 
		 string(object_tag) != string(render_light_tl.object_tag))
		render_set_uniform("uIgnore", true)
	else
		render_set_uniform("uIgnore", false)
	*/
	
	if (shader_blend_color != value_inherit[e_value.RGB_MUL] || shader_blend_color != value_inherit[e_value.ALPHA])
	{
		shader_blend_color = value_inherit[e_value.RGB_MUL]
		shader_blend_alpha = value_inherit[e_value.ALPHA]
		render_set_uniform_color("uBlendColor", shader_blend_color, shader_blend_alpha)
	}
	
	if (render_mode = e_render_mode.AO_MASK)
	{
		render_set_uniform_color("uReplaceColor", ssao ? merge_color(c_black, c_white, shader_blend_alpha) : c_black, 1)
	}
		
	if (colors_ext || shader_uniform_color_ext)
	{
		render_set_uniform_int("uColorsExt", colors_ext)
		render_set_uniform_color("uRGBAdd", value_inherit[e_value.RGB_ADD], 1)
		render_set_uniform_color("uHSBAdd", value_inherit[e_value.HSB_ADD], 1)
		render_set_uniform_color("uRGBSub", value_inherit[e_value.RGB_SUB], 1)
		render_set_uniform_color("uHSBSub", value_inherit[e_value.HSB_SUB], 1)
		render_set_uniform_color("uHSBMul", value_inherit[e_value.HSB_MUL], 1)
		render_set_uniform_color("uMixColor", value_inherit[e_value.MIX_COLOR], value_inherit[e_value.MIX_PERCENT])
		shader_uniform_color_ext = colors_ext
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
	
	if ((app.background_fog_show && fog) != shader_uniform_fog)
	{
		shader_uniform_fog = (app.background_fog_show && fog)
		render_set_uniform_int("uFogShow", shader_uniform_fog)
	}
	
	if (value_inherit[e_value.WIND_INFLUENCE] != shader_uniform_wind_strength)
	{
		shader_uniform_wind_strength = app.background_wind_strength * app.setting_wind_enable * value_inherit[e_value.WIND_INFLUENCE]
		render_set_uniform("uWindStrength", shader_uniform_wind_strength)
		render_set_uniform("uWindDirectionalStrength", shader_uniform_wind_strength * app.background_wind_directional_strength) 
	}
	
	if (app.project_render_legacy_rendering || render_mode = e_render_mode.SUBSURFACE)
	{
		// Subsurface
		if ((value_inherit[e_value.SUBSURFACE] > 0 || shader_uniform_sss))
		{
			shader_uniform_sss_color = value_inherit[e_value.SUBSURFACE_COLOR]
		
			render_set_uniform("uSSS", value_inherit[e_value.SUBSURFACE])
			render_set_uniform_vec3("uSSSRadius", value_inherit[e_value.SUBSURFACE_RADIUS_RED], value_inherit[e_value.SUBSURFACE_RADIUS_GREEN], value_inherit[e_value.SUBSURFACE_RADIUS_BLUE])
			render_set_uniform_color("uSSSColor", shader_uniform_sss_color, 1.0)
		
			shader_uniform_sss = value_inherit[e_value.SUBSURFACE] > 0
		}
	}
	
	if (object_tag_int != shader_uniform_ignore_int)
	{
		shader_uniform_ignore_int = object_tag_int
		render_set_uniform_int("uIgnoreInt", shader_uniform_ignore_int)
	}
	
	var prevblend = null;
	
	// Object blend mode
	if (blend_mode != "normal" && (render_mode = e_render_mode.COLOR || render_mode = e_render_mode.COLOR_FOG || render_mode = e_render_mode.COLOR_FOG_LIGHTS || render_mode = e_render_mode.ALPHA_FIX))
	{
		if (render_mode = e_render_mode.ALPHA_FIX)
			return 0
			
		prevblend = gpu_get_blendmode()
		
		var blend = blend_mode_map[? blend_mode];
		if (is_array(blend))
			gpu_set_blendmode_ext(blend[0], blend[1])
		else
			gpu_set_blendmode(blend)
	}
	
	// Glow
	if (glow != shader_uniform_glow ||
		glow_texture != shader_uniform_glow_texture ||
		value_inherit[e_value.GLOW_COLOR] != shader_uniform_glow_color)
	{
		shader_uniform_glow = glow
		shader_uniform_glow_texture = glow_texture
		shader_uniform_glow_color = value_inherit[e_value.GLOW_COLOR]
		
		if (shader_uniform_glow)
		{
			render_set_uniform_int("uGlow", 1)
			render_set_uniform_int("uGlowTexture", glow_texture)
			render_set_uniform_color("uGlowColor", shader_uniform_glow_color, 1)
			
			if (only_render_glow)
			{
				//if (render_mode != e_render_mode.WOLVIZA) {
					prevblend = gpu_get_blendmode()
					gpu_set_blendmode(bm_add)
				//} else {
				//	render_set_uniform_int("uGlowOnly", 1)
				//}
			} //else {
				//render_set_uniform_int("uGlowOnly", 0)
			//}
		}
		else
		{
			render_set_uniform_int("uGlow", 0)
			render_set_uniform_int("uGlowTexture", 0)
			render_set_uniform_color("uGlowColor", c_black, 0)
			//render_set_uniform_int("uGlowOnly", 0)
		}
	}
	
	// Glint mode
	if (render_shader_obj.uniform_map[?"uGlintEnabled"] > -1 && glint_mode != e_glint.NONE)
	{
		var tex, spd;
		if (glint_tex.texture)
			tex = glint_tex.texture
		else
			tex = (glint_mode = e_glint.ITEM ? glint_tex.glint_item_texture : glint_tex.glint_armor_texture)
		
		texture_set_stage(render_shader_obj.sampler_map[?"uGlintTexture"], sprite_get_texture(tex, 0))
	
		spd = app.background_time * glint_speed * app.project_render_glint_speed
		render_set_uniform_int("uGlintEnabled", glint_mode = e_glint.NONE ? 0 : 1)
		render_set_uniform_vec2("uGlintOffset", spd * (0.000625), spd * (0.00125))
		render_set_uniform("uGlintStrength", app.project_render_glint_strength * glint_strength)
		render_set_uniform_vec2("uGlintSize", sprite_get_width(tex) * 2 * glint_scale, sprite_get_height(tex) * 2 * glint_scale)
	} else {
		render_set_uniform_int("uGlintEnabled", 0)
	}
	// Volume Rendering
	// render_set_uniform_int("uVolumeEnabled", volume_mode ? 1 : 0)
	
	// Render
	render_world_tl_obj()
	
	if (prevblend != null)
		gpu_set_blendmode(prevblend)
}
