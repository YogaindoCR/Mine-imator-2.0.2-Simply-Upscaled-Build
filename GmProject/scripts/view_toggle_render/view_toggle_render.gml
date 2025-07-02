/// view_toggle_render()

function view_toggle_render()
{
	if (view_second.show)
	{
		if (view_second.quality = e_view_mode.RENDER)
		{
			view_second.quality = view_second.before
			render_free()
			
			return 0
		}
		else
			view_second.before = view_second.quality
			view_second.quality = e_view_mode.RENDER
		
		if (view_main.quality = e_view_mode.RENDER)
			view_main.quality = view_main.before
	}
	else
	{
		if (view_main.quality = e_view_mode.RENDER)
		{
			view_main.quality = view_main.before
			render_free()
			
			return 0
		}
		else
			view_main.before = view_main.quality
			view_main.quality = e_view_mode.RENDER
	}
	render_low_drawing = 0
}
