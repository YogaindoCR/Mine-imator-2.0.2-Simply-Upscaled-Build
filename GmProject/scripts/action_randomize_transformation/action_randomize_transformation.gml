/// action_randomize_transformation

function action_randomize_transformation(){
    range_sca = 0.5;
    range_pos = 40;
    range_rot = 30;
    randomize();
    var selected_list = [];

    with (obj_timeline)
    {
        if (selected) // Store selected object
		{
            array_add(selected_list, id);
			selected = false // Deselect them
		}
    }
	
	for (var i = 0; i < array_length(selected_list); i++)
	{
        var tl = selected_list[i];

        with (tl)
            selected = true; // Only select this object and continue

        if (context_menu_group = e_context_group.POSITION)
		{
            var rx = random_range(tl.value[e_value.POS_X] - range_pos,
                                  tl.value[e_value.POS_X] + range_pos);

            var ry = random_range(tl.value[e_value.POS_Y] - range_pos,
                                  tl.value[e_value.POS_Y] + range_pos);

            var rz = random_range(tl.value[e_value.POS_Z] - range_pos,
                                  tl.value[e_value.POS_Z] + range_pos);

            tl_value_set_start(action_randomize_transformation, true);
            tl_value_set(e_value.POS_X, rx, false);
            tl_value_set(e_value.POS_Y, ry, false);
            tl_value_set(e_value.POS_Z, rz, false);
            tl_value_set_done();
        }
		else if (context_menu_group = e_context_group.ROTATION)
		{
            var rx = random_range(tl.value[e_value.ROT_X] - range_rot,
                                  tl.value[e_value.ROT_X] + range_rot);

            var ry = random_range(tl.value[e_value.ROT_Y] - range_rot,
                                  tl.value[e_value.ROT_Y] + range_rot);

            var rz = random_range(tl.value[e_value.ROT_Z] - range_rot,
                                  tl.value[e_value.ROT_Z] + range_rot);

            tl_value_set_start(action_randomize_transformation, true);
            tl_value_set(e_value.ROT_X, rx, false);
            tl_value_set(e_value.ROT_Y, ry, false);
            tl_value_set(e_value.ROT_Z, rz, false);
            tl_value_set_done();
        } 
		else if (context_menu_group = e_context_group.SCALE)
		{
            var rx = random_range(tl.value[e_value.SCA_X] - range_sca,
                                  tl.value[e_value.SCA_X] + range_sca);

            var ry = random_range(tl.value[e_value.SCA_Y] - range_sca,
                                  tl.value[e_value.SCA_Y] + range_sca);

            var rz = random_range(tl.value[e_value.SCA_Z] - range_sca,
                                  tl.value[e_value.SCA_Z] + range_sca);

            tl_value_set_start(action_randomize_transformation, true);
            tl_value_set(e_value.SCA_X, rx, false);
            tl_value_set(e_value.SCA_Y, ry, false);
            tl_value_set(e_value.SCA_Z, rz, false);
            tl_value_set_done();
        }
		
        with (tl)
            selected = false; // Deselect for next object
    }
	
    for (var i = 0; i < array_length(selected_list); i++)
        with (selected_list[i])
            selected = true // reselect object
} 
