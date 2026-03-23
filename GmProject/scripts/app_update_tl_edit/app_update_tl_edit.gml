/// app_update_tl_edit()

function app_update_tl_edit()
{
	render_low_drawing = 0
	app_update_tl_edit_tabs()
	app_update_tl_edit_select()
	tl_update_matrix()
	
	if (!instance_exists(temp_edit))
	{
		tab_close(template_editor)
		return 0
	}
}