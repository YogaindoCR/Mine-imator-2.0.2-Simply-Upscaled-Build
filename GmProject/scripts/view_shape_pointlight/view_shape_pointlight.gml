/// view_shape_pointlight(timeline)
/// @arg timeline
/// @desc Renders a pointlight shape.

function view_shape_pointlight(tl)
{
	// Bulb
	view_shape_circle(point3D_add(tl.world_pos, vec3(0, 0, 4)), 4)
	
	// Base
	view_shape_box(point3D_add(tl.world_pos, vec3(-1.5, -1.5, -4)), point3D_add(tl.world_pos, vec3(1.5, 1.5, 0)))
	
	// Guide (only visible on selected pointlights)
	if (tl.selected && render_low_drawing < 4)
		view_shape_pointlight_guide(tl)
}

function view_shape_pointlight_guide(tl)
{
	var light_c;
	light_c = tl.value[e_value.LIGHT_COLOR]
	
	draw_set_alpha(.5)
	
	if (setting_overlay_show_guides)
	{
		// Range
		draw_set_color(light_c)
		view_shape_circle(point3D_add(tl.world_pos, vec3(0, 0, 0)), max(0, tl.value[e_value.LIGHT_RANGE]))
	
		// Fade size
		draw_set_color(make_color_hsv(color_get_hue(light_c) + 25, color_get_saturation(light_c), color_get_value(light_c) + 25))
		view_shape_circle(point3D_add(tl.world_pos, vec3(0, 0, 0)), max(0, tl.value[e_value.LIGHT_RANGE]) * clamp((1 - tl.value[e_value.LIGHT_FADE_SIZE]), 0, 1))
	}
	
	// Size
	draw_set_alpha(.8)
	draw_set_color(light_c)
	view_shape_circle(point3D_add(tl.world_pos, vec3(0, 0, 0)), tl.value[e_value.LIGHT_SIZE] / 2)
	
	draw_set_color(c_white)
	draw_set_alpha(1)
}