/// menu_scaling_settings()

function menu_scaling_settings()
{
	draw_set_font(font_label)
	var draggerwid;
	draggerwid = text_max_width("viewrenderscalingdrag") + 16 + dragger_width
	
	tab_control_dragger()
	draw_dragger("viewrenderscalingdrag", dx, dy, dragger_width, setting_view_scaling_value, 0.001, 0.500, 1.000, 1, snap_min, tbx_setting_view_scaling, action_setting_scaling)
	tab_next()
	
	settings_menu_w = (max(draggerwid) + 24)
}
