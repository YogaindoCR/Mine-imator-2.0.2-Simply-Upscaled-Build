/// tab_settings_filepath()

function tab_settings_filepath()
{
	draw_button_label("settingsfilepathproject", dx, dy, dw, icons.FOLDER, e_button.SECONDARY, action_filepath_project)
	tab_next()
	
	draw_button_label("settingsfilepathmineimator", dx, dy, dw, icons.FOLDER, e_button.SECONDARY, action_filepath_mineimator)
	tab_next()
	
	draw_button_label("settingsfilepathlanguage", dx, dy, dw, icons.FOLDER, e_button.SECONDARY, action_filepath_language)
	tab_next()
	
	draw_button_label("settingsfilepathmctemp", dx, dy, dw, icons.FOLDER, e_button.SECONDARY, action_filepath_mctemp)
	tab_next()
}
