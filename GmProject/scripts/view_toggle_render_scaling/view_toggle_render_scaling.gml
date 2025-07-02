/// view_toggle_render_scaling()

function view_toggle_render_scaling()
{
	if (view_second.show)
	{
		setting_view_second_scaling = !setting_view_second_scaling 
		view_second.scaling = !setting_view_second_scaling 
	} else {
		setting_view_main_scaling = !setting_view_main_scaling 
		view_main.scaling = setting_view_main_scaling
	}
	render_low_drawing = 0
}
