/// shader_high_indirect_blur_set

function shader_bilateral_blur_set() {
	texture_set_stage(sampler_map[?"uIndirectTex"], surface_get_texture(render_surface_hdr[0]));
	texture_set_stage(sampler_map[?"uDepthBuffer"], surface_get_texture(render_surface_depth));
	texture_set_stage(sampler_map[?"uNormalBuffer"], surface_get_texture(render_surface_normal));
	
	gpu_set_texrepeat_ext(sampler_map[?"uIndirectTex"], false);
	gpu_set_texrepeat_ext(sampler_map[?"uDepthBuffer"], false);
	gpu_set_texrepeat_ext(sampler_map[?"uNormalBuffer"], false);

	render_set_uniform("uDepthSigma", 120.0);
	render_set_uniform("uNormalSigma", 32.0);
	render_set_uniform("uBilateralRadius", app.project_render_indirect_denoiser_strength * 2.0);
	render_set_uniform("uNormalBufferScale", is_cpp() ? normal_buffer_scale : 1);
	render_set_uniform_vec2("uScreenSize", render_width, render_height);
}