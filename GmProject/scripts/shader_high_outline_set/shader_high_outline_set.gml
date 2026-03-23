/// shader_high_outline_set()

function shader_high_outline_set()
{
	texture_set_stage(sampler_map[?"uDepthBuffer"], surface_get_texture(render_surface_depth))
	texture_set_stage(sampler_map[?"uNormalBuffer"], surface_get_texture(render_surface_normal))
	texture_set_stage(sampler_map[?"uEmissiveBuffer"], surface_get_texture(render_surface_emissive))
	
	gpu_set_texrepeat_ext(sampler_map[?"uDepthBuffer"], false)
	gpu_set_texrepeat_ext(sampler_map[?"uNormalBuffer"], false)
	gpu_set_texrepeat_ext(sampler_map[?"uEmissiveBuffer"], false)
	
	render_set_uniform("uNormalBufferScale", is_cpp() ? normal_buffer_scale : 1)
	render_set_uniform("uNear", clip_near)
	render_set_uniform("uFar", depth_far)
	render_set_uniform("uProjMatrixInv", matrix_inverse(proj_matrix))
	render_set_uniform_vec2("uScreenSize", render_width, render_height)
	
	render_set_uniform("uRadius", render_camera.value[e_value.CAM_OUTLINE_RADIUS])
	render_set_uniform("uPower", render_camera.value[e_value.CAM_OUTLINE_STRENGTH] * 2)
	render_set_uniform("uThresholdDepth", render_camera.value[e_value.CAM_OUTLINE_DEPTH_THRESHOLD] / 10)
	render_set_uniform("uThresholdDepthFade", render_camera.value[e_value.CAM_OUTLINE_DEPTH_THRESHOLD_FADE])
	render_set_uniform("uThresholdNormal", render_camera.value[e_value.CAM_OUTLINE_NORMAL_THRESHOLD])
	render_set_uniform("uThresholdNormalFade", render_camera.value[e_value.CAM_OUTLINE_NORMAL_THRESHOLD_FADE])
	render_set_uniform("uOutlineNormal", render_camera.value[e_value.CAM_OUTLINE_NORMAL])
	render_set_uniform_int("uBlendMode", ds_list_find_index(blend_mode_list_ex, render_camera.value[e_value.CAM_OUTLINE_BLEND_MODE]))
	
	render_set_uniform_color("uColor", render_camera.value[e_value.CAM_OUTLINE_COLOR], 1)
}
