/// shader_high_wolviza_set()

function shader_high_wolviza_set()
{
	render_set_uniform("uNormalBufferScale", is_cpp() ? normal_buffer_scale : 1)
	render_set_uniform("uNear", depth_near)
	render_set_uniform("uFar", depth_far_custom)
}
