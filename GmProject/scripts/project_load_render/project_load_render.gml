/// project_load_render(map)

function project_load_render(map)
{
	if (!ds_map_valid(map))
		return 0
	
	project_render_engine = value_get_real(map[?"render_engine"], project_render_engine)
	project_render_samples = value_get_real(map[?"render_samples"], project_render_samples)
	project_render_distance = value_get_real(map[?"render_distance"], project_render_distance)
	
	project_render_ssao = value_get_real(map[?"render_ssao"], project_render_ssao)
	project_render_ssao_samples = value_get_real(map[?"render_ssao_samples"], project_render_ssao_samples)
	project_render_ssao_radius = value_get_real(map[?"render_ssao_radius"], project_render_ssao_radius)
	project_render_ssao_power = value_get_real(map[?"render_ssao_power"], project_render_ssao_power)
	project_render_ssao_color = value_get_color(map[?"render_ssao_color"], project_render_ssao_color)
	project_render_ssao_ratio = value_get_real(map[?"render_ssao_ratio"], project_render_ssao_ratio)
	project_render_ssao_ratio_balance = value_get_real(map[?"render_ssao_ratio_balance"], project_render_ssao_ratio_balance)
	
	project_render_shadows = value_get_real(map[?"render_shadows"], project_render_shadows)
	project_render_shadows_sun_buffer_size = value_get_real(map[?"render_shadows_sun_buffer_size"], project_render_shadows_sun_buffer_size)
	project_render_shadows_spot_buffer_size = value_get_real(map[?"render_shadows_spot_buffer_size"], project_render_shadows_spot_buffer_size)
	project_render_shadows_point_buffer_size = value_get_real(map[?"render_shadows_point_buffer_size"], project_render_shadows_point_buffer_size)
	project_render_shadows_transparent = value_get_real(map[?"render_shadows_transparent"], project_render_shadows_transparent)
	project_render_shadows_blur_sample = value_get_real(map[?"render_shadows_blur_sample"], project_render_shadows_blur_sample)
	project_render_shadows_blur = value_get_real(map[?"render_shadows_blur"], project_render_shadows_blur)
	
	project_render_subsurface_quality = value_get_real(map[?"render_subsurface_quality"], project_render_subsurface_quality)
	project_render_subsurface_samples = value_get_real(map[?"render_subsurface_samples"], project_render_subsurface_samples)
	project_render_subsurface_strength = value_get_real(map[?"render_subsurface_strength"], project_render_subsurface_strength)
	project_render_subsurface_sharpness = value_get_real(map[?"render_subsurface_sharpness"], project_render_subsurface_sharpness)
	project_render_subsurface_absorption = value_get_real(map[?"render_subsurface_absorption"], project_render_subsurface_absorption)
	project_render_subsurface_desaturation = value_get_real(map[?"render_subsurface_desaturation"], project_render_subsurface_desaturation)
	project_render_subsurface_colorthreshold = value_get_real(map[?"render_subsurface_colorthreshold"], project_render_subsurface_colorthreshold)
	project_render_subsurface_highlight = value_get_real(map[?"render_subsurface_highlight"], project_render_subsurface_highlight)
	project_render_subsurface_highlight_strength = value_get_real(map[?"render_subsurface_highlight_strength"], project_render_subsurface_highlight_strength)
	project_render_subsurface_highlight_sharpness = value_get_real(map[?"render_subsurface_highlight_sharpness"], project_render_subsurface_highlight_sharpness)
	project_render_subsurface_highlight_colorthreshold = value_get_real(map[?"render_subsurface_highlight_colorthreshold"], project_render_subsurface_highlight_colorthreshold)
	project_render_subsurface_highlight_desaturation = value_get_real(map[?"render_subsurface_highlight_desaturation"], project_render_subsurface_highlight_desaturation)
	
	project_render_indirect = value_get_real(map[?"render_indirect"], project_render_indirect)
	project_render_indirect_blur_radius = value_get_real(map[?"render_indirect_blur_radius"], project_render_indirect_blur_radius)
	project_render_indirect_blur_radius_gi = value_get_real(map[?"render_indirect_blur_radius_gi"], project_render_indirect_blur_radius_gi)
	project_render_indirect_precision = value_get_real(map[?"render_indirect_precision"], project_render_indirect_precision)
	project_render_indirect_strength = value_get_real(map[?"render_indirect_strength"], project_render_indirect_strength)
	project_render_indirect_raystep = value_get_real(map[?"render_indirect_raystep"], project_render_indirect_raystep)
	project_render_indirect_denoiser = value_get_real(map[?"render_indirect_denoiser"], project_render_indirect_denoiser)
	project_render_indirect_denoiser_strength = value_get_real(map[?"render_indirect_denoiser_strength"], project_render_indirect_denoiser_strength)
	
	project_render_reflections = value_get_real(map[?"render_reflections"], project_render_reflections)
	project_render_reflections_precision = value_get_real(map[?"render_reflections_precision"], project_render_reflections_precision)
	project_render_reflections_thickness = value_get_real(map[?"render_reflections_thickness"], project_render_reflections_thickness)
	project_render_reflections_fade_amount = value_get_real(map[?"render_reflections_fade_amount"], project_render_reflections_fade_amount)
	
	project_render_glow = value_get_real(map[?"render_glow"], project_render_glow)
	project_render_glow_radius = value_get_real(map[?"render_glow_radius"], project_render_glow_radius)
	project_render_glow_intensity = value_get_real(map[?"render_glow_intensity"], project_render_glow_intensity)
	project_render_glow_falloff = value_get_real(map[?"render_glow_falloff"], project_render_glow_falloff)
	project_render_glow_falloff_radius = value_get_real(map[?"render_glow_falloff_radius"], project_render_glow_falloff_radius)
	project_render_glow_falloff_intensity = value_get_real(map[?"render_glow_falloff_intensity"], project_render_glow_falloff_intensity)
	
	project_render_aa = value_get_real(map[?"render_aa"], project_render_aa)
	project_render_aa_power = value_get_real(map[?"render_aa_power"], project_render_aa_power)
	
	project_render_dof_sample = value_get_real(map[?"render_dof_sample"], project_render_dof_sample)
	project_render_dof_ghostingfix = value_get_real(map[?"render_dof_ghostingfix"], project_render_dof_ghostingfix)
	project_render_dof_ghostingfix_threshold = value_get_real(map[?"render_dof_ghostingfix_threshold"], project_render_dof_ghostingfix_threshold)
	
	project_render_motionblur = value_get_real(map[?"render_motionblur"], project_render_motionblur)
	project_render_motionblur_power = value_get_real(map[?"render_motionblur_power"], project_render_motionblur_power)
	
	project_render_buffer_scale = value_get_real(map[?"render_buffer_scale"], project_render_buffer_scale)
	
	project_bend_style = value_get_string(map[?"bend_style"], project_bend_style)
	project_render_opaque_leaves = value_get_real(map[?"opaque_leaves"], project_render_opaque_leaves)
	project_render_liquid_animation = value_get_real(map[?"liquid_animation"], project_render_liquid_animation)
	project_render_water_reflections = value_get_real(map[?"water_reflections"], project_render_water_reflections)
	
	project_render_block_emissive = value_get_real(map[?"block_emissive"], project_render_block_emissive)
	project_render_block_subsurface = value_get_real(map[?"block_subsurface"], project_render_block_subsurface)
	
	project_render_glint_speed = value_get_real(map[?"glint_speed"], project_render_glint_speed)
	project_render_glint_strength = value_get_real(map[?"glint_strength"], project_render_glint_strength)
	
	project_render_texture_filtering = value_get_real(map[?"texture_filtering"], project_render_texture_filtering)
	project_render_transparent_block_texture_filtering = value_get_real(map[?"transparent_block_texture_filtering"], project_render_transparent_block_texture_filtering)
	project_render_texture_filtering_level = value_get_real(map[?"texture_filtering_level"], project_render_texture_filtering_level)
	
	project_render_alpha_mode = value_get_real(map[?"render_alpha_mode"], project_render_alpha_mode)
	project_render_tonemapper = value_get_real(map[?"tonemapper"], project_render_tonemapper)
	project_render_exposure = value_get_real(map[?"exposure"], project_render_exposure)
	project_render_gamma = value_get_real(map[?"gamma"], project_render_gamma)
	project_render_material_maps = value_get_real(map[?"material_maps"], project_render_material_maps)
}