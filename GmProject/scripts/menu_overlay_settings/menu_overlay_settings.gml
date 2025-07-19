/// menu_overlay_settings()

function menu_overlay_settings()
{
	draw_set_font(font_label)
	var switchwid;
	switchwid = text_max_width("viewoverlayslight", "viewoverlaysparticle", "viewoverlayspath") + 28 + 16 + 24
	
	tab_control_switch()
	draw_switch("viewoverlayslight", dx, dy, setting_overlay_show_light, action_setting_overlay_show_light)
	tab_next()
	
	tab_control_switch()
	draw_switch("viewoverlaysparticle", dx, dy, setting_overlay_show_particle, action_setting_overlay_show_particle)
	tab_next()
	
	tab_control_switch()
	draw_switch("viewoverlayspath", dx, dy, setting_overlay_show_path, action_setting_overlay_show_path)
	tab_next()
	
	tab_control_switch()
	draw_switch("viewoverlaysguides", dx, dy, setting_overlay_show_guides, action_setting_overlay_show_guides)
	tab_next()
	
	settings_menu_w = (max(switchwid) + 24)
}
