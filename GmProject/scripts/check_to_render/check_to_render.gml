///Check if Mine-imator Should render or not
///render_low_drawing < 4 for checking, render_low_drawing++ was put on view_update_surface
///@arg view

function check_to_render(view){
		if (setting_viewport_optimization){
			if (string(view) == string(view_main)) {
			    // Check if camera matrix has changed
			    if (render_low_Before == 0)
			    {
					render_low_drawing = 0
			    }
			    else if (window_busy != "" && window_busy != "contextmenu" 
						&& window_busy != "tabmove" && window_busy != "menu" 
						&& window_busy != "settingsmenu" && window_busy != "timelineselect"
						&& window_busy != "timelineselectkeyframes"){
					render_low_drawing = 0
				}
			    else if (timeline_playing || history_resource_update || recent_add_wait > 0){
					render_low_drawing = 0
				}
			    else if (app.template_editor.show){
					render_low_drawing = 0
				}
			    //else if (render_mode == e_render_mode.SELECT){
			    //    camera_changed = true;
				//	render_low_drawing = 0
				//}
			    else if (render_low_Before3 != history_pos){
					render_low_drawing = 0
				}
			    else if (render_low_Before2 != render_ratio){
					render_low_drawing = 0
				}
			    else if (textbox_isediting){
					render_low_drawing = 0
				}
			    else if (render_low_Before4 != tl_edit){
					render_low_drawing = 0
				}
			    else if (render_low_Before5 != timeline_marker) {
					render_low_drawing = 0
				}
				else if (render_low_Before != cam_work_zoom)
			    {
					render_low_drawing = 0
				}
				else if (mouse_left && window_busy != "timelineselect"
						&& window_busy != "timelineselectkeyframes")
			    {
					render_low_drawing = -1
				}
			        // Direct matrix comparison
			        //for (var i = 0; i < 3; i++)
			        //{
			        //    if (abs(render_low_Before[i] - cam_work_from[i]) > 0.0001)
			        //    {
					//		render_low_drawing = 0
			        //        break;
					//	}
			        //}
			    //}
			    //Recapture For Before Data
			    render_low_Before = cam_work_zoom;
			    render_low_Before2 = render_ratio;
			    render_low_Before3 = history_pos;
			    render_low_Before4 = tl_edit;
			    render_low_Before5 = timeline_marker;
	
			    //render_low_Before4 = e_render_mode.CLICK;
				//  || abs((render_low_Before4[i] - cam_up[i])) > 0.0001
			}
		render_low_drawing = clamp(render_low_drawing, -90, 90)
	} else {
		render_low_drawing = -1
	}
}