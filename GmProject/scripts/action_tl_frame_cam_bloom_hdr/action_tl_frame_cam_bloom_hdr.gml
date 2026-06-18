/// action_tl_frame_cam_bloom_hdr(enable)
/// @arg enable

function action_tl_frame_cam_bloom_hdr(enable)
{
	tl_value_set_start(action_tl_frame_cam_bloom_hdr, false)
	tl_value_set(e_value.CAM_BLOOM_HDR, enable, false)
	tl_value_set_done()
}
