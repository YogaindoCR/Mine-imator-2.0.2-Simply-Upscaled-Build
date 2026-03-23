/// tl_update_matrix([paths, updateik, updatepose])
/// @arg [paths
/// @arg updateik
/// @arg updatepose]
/// @desc Updates matrixes and positions.

function tl_update_matrix(usepaths = false, updateik = true, updatepose = false, updatecopy = false, updatemodifier = true)
{
	var start, curtl, tlamount, bend, pos, rot, sca, par, matrixnoscale, hasik, lasttex, ikblend, posebend;
	var inhalpha, inhcolor, inhglowcolor, inhvis, inhbend, inhtex, inhsurf, inhsubsurf, inhmodifierframeskip;
	tlamount = ds_list_size(app.project_timeline_list)
	posebend = [0, 0, 0]
	
	if (object_index = obj_timeline)
		start = ds_list_find_index(app.project_timeline_list, id)
	else
		start = 0
	
	if (start = -1)
		return 0
		
	for (var i = start; i < tlamount; i++)
	{
		curtl = app.project_timeline_list[|i]
		
		if (!instance_exists(curtl))
			continue
		
		if (app.setting_viewport_optimization && (curtl.hide || (!curtl.value_inherit[e_value.VISIBLE] && !curtl.value[e_value.VISIBLE])) && !curtl.selected)
			continue
		
		// Update children
		if (updateik && !updatepose && (curtl.type = e_tl_type.CHARACTER || curtl.type = e_tl_type.SPECIAL_BLOCK || curtl.type = e_tl_type.MODEL))
			for (var t = 0; t < ds_list_size(curtl.tree_list); t++)
				if (curtl.tree_list[|t].inherit_pose)
					array_add(app.project_inherit_pose_array, curtl.tree_list[|t])
					
		if (curtl.value[e_value.ROT_TARGET] != null|| curtl.value[e_value.LOOK_AT_TARGET] != null || curtl.value[e_value.POS_TARGET] != null || curtl.value[e_value.SCALE_TARGET] != null)
		{	
			if (updateik && !updatecopy)
			{
				array_add(app.project_copy_obj_array, curtl)
				for (var t = 0; t < ds_list_size(curtl.tree_list); t++)
					array_add(app.project_copy_obj_array, curtl.tree_list[|t])
			}
		}
			
		// Force update for shake modifier check
		if (curtl.value[e_value.MODIFIER_SHAKE] && curtl.modifier_shake_update) {
			curtl.update_matrix = true
			curtl.modifier_shake_update = false // Updated in app_update_animate
		}
		
		
		if (!curtl.update_matrix)
			continue
		
		// Delay timeline update if we inherit pose
		if (updateik && !updatepose && (array_length(app.project_inherit_pose_array) > 0) && array_contains(app.project_inherit_pose_array, curtl))
		{
			curtl.update_matrix = false
			continue
		}
		
		if (usepaths && (curtl.type = e_tl_type.PATH || curtl.type = e_tl_type.PATH_POINT))
		{
			curtl.update_matrix = false
			continue
		}
		
		// Frame Skip modifier check
		curtl.modifier_frameskipped = false
		if (((curtl.value[e_value.MODIFIER_FRAMESKIP]) || curtl.value_inherit[e_value.MODIFIER_FRAMESKIP]) && (!curtl.selected && !curtl.parent_is_selected)) {
			//Inherit Frame Skip
			if (curtl.value_inherit[e_value.MODIFIER_FRAMESKIP] && curtl.inherit_modifier_frameskip) {
				if (curtl.value_inherit[e_value.MODIFIER_FRAMESKIP_VALUE] > 0) {
					curtl.frameskip_before = round(curtl.frameskip_before / curtl.value_inherit[e_value.MODIFIER_FRAMESKIP_VALUE])
				
					if (round(app.timeline_marker / curtl.value_inherit[e_value.MODIFIER_FRAMESKIP_VALUE]) == curtl.frameskip_before)
						curtl.modifier_frameskipped = true
					
					curtl.frameskip_before = app.timeline_marker
				}
			}
			else
			{
				if (curtl.value[e_value.MODIFIER_FRAMESKIP_VALUE] > 0) {
					curtl.frameskip_before = round(curtl.frameskip_before / curtl.value[e_value.MODIFIER_FRAMESKIP_VALUE])
				
					if (round(app.timeline_marker / curtl.value[e_value.MODIFIER_FRAMESKIP_VALUE]) == curtl.frameskip_before)
						curtl.modifier_frameskipped = true
					
					curtl.frameskip_before = app.timeline_marker
				}
			}
		}
		
		
		with (curtl)
		{
			// Get parent matrix
			if (parent != app)
			{
				if (inherit_rot_point)
					matrix_parent = array_copy_1d(parent.matrix_render)
				else
					matrix_parent = array_copy_1d(parent.matrix)
				
				// Parent is a body part and we're locked to bended half
				if (parent.type = e_tl_type.BODYPART && lock_bend && parent.model_part != null && parent.model_part.bend_part != null)
				{
					bend = vec3(parent.value_inherit[e_value.BEND_ANGLE_X], parent.value_inherit[e_value.BEND_ANGLE_Y], parent.value_inherit[e_value.BEND_ANGLE_Z]);
					matrix_parent = matrix_multiply(model_part_get_bend_matrix(parent.model_part, bend, point3D(0, 0, 0)), matrix_parent)
				}
			}
			else
				matrix_parent = MAT_IDENTITY
			
			// Orient to path object
			if (usepaths)
			{
				var path = value[e_value.PATH_OBJ];
				if (path != null && array_length(path.path_table) > 0)
				{
					var offset, angle, curpos, mat;
					offset = value[e_value.PATH_OFFSET]
					angle = 0
				
					// Get current position
					curpos = tl_path_offset_get_position(path, offset)
				
					// Make rotation matrix and add path position
					var n, t;
					n = vec3_normalize([curpos[PATH_NORMAL_X], curpos[PATH_NORMAL_Y], curpos[PATH_NORMAL_Z]])
					t = vec3_normalize([curpos[PATH_TANGENT_X], curpos[PATH_TANGENT_Y], curpos[PATH_TANGENT_Z]])
				
					mat = matrix_create_rotate_to(t, n)
				
					// If path is closed, check if object is before/after ends
					if (!path.path_closed)
					{
						if (value[e_value.PATH_OFFSET] <= 0)
							curpos = tl_path_offset_get_position(path, 0)
						else if (value[e_value.PATH_OFFSET] >= path.path_length)
							curpos = tl_path_offset_get_position(path, path.path_length)
					}
				
					mat = matrix_multiply(mat, matrix_create(curpos, vec3(0), vec3(1)))
				
					matrix_parent = matrix_multiply(matrix_parent, mat)
				
					if (is_array(path.matrix))
						matrix_parent = matrix_multiply(matrix_parent, path.matrix)
				}
			}
			
			// Add body part position and rotation
			if (type = e_tl_type.BODYPART && model_part != null)
			{
				if (part_of != null)
					matrix_parent = matrix_multiply(matrix_create(model_part.position, model_part.rotation, vec3(1)), matrix_parent)
				else
					matrix_parent = matrix_multiply(matrix_create(point3D(0, 0, 0), model_part.rotation, vec3(1)), matrix_parent)
			}
		
			// Create modifier value
			if (updatemodifier) // Avoid creating multiple value
				tl_update_modifier()
			
			// Create main matrix
			if (!modifier_frameskipped) {
				pos = point3D(value[e_value.POS_X] + modifier_shake_pos[0], value[e_value.POS_Y] + modifier_shake_pos[1], value[e_value.POS_Z] + modifier_shake_pos[2])
				rot = vec3(value[e_value.ROT_X] + modifier_shake_rot[0], value[e_value.ROT_Y] + modifier_shake_rot[1], value[e_value.ROT_Z] + modifier_shake_rot[2])
				sca = vec3(value[e_value.SCA_X], value[e_value.SCA_Y], value[e_value.SCA_Z])
				pos_prev = pos
				rot_prev = rot
				sca_prev = sca
			} else {
				pos = pos_prev
				rot = rot_prev
				sca = sca_prev
			}
			
			/*
			else
			{
			    pos = point3D(pos_prev[0], pos_prev[1], pos_prev[2]);
			    rot = rot_prev;
			    sca = sca_prev;
			}
			
			// ----------------------------------------
			// PHYSICS
			// ----------------------------------------
			var physc = vec2(0);

			for (var i = 0; i <= 2; i++)
			{
			    // Reset temporary pos vector
			    pos = vec3(0);

			    physc = physics_value_generate(
			        pos_prev[i],
			        modifier_physc_pos[i],
			        value[e_value.POS_X + i], 2, 0.6);

			    pos_prev[i]           = physc[0];
			    modifier_physc_pos[i] = physc[1];
			}

			pos = point3D(pos_prev[0], pos_prev[1], pos_prev[2]);
			*/
			
			matrix_local = matrix_create(pos, rot, sca)
			matrix = matrix_multiply(matrix_local, matrix_parent)
			
			hasik = (array_length(part_joints_matrix) > 0 && value[e_value.IK_TARGET] != null)
			
			// Remove old rotation and re-add own
			if (!inherit_rotation)
			{
				matrix_remove_rotation(matrix)
				matrix = matrix_multiply(matrix_create(point3D(0, 0, 0), vec3(value[e_value.ROT_X], value[e_value.ROT_Y], value[e_value.ROT_Z]), vec3(1)), matrix)
			}
			
			// Get current matrix for IK
			matrix_parent_pre_ik = array_copy_1d(matrix)
			
			// Add IK orientation
			if (hasik)
				matrix = matrix_multiply(part_joints_matrix[0], matrix)
			
			// Check body part model timeline is "Inherit pose" is enabled, look at parent of root model and search for matching body parts to inherit from
			posebend = [0, 0, 0]
			
			if (updatepose && part_of != null && part_of.inherit_pose && part_of.parent != app)
			{
				var posetl = null;
				with (part_of.parent)
					posetl = tl_part_find(other.model_part_name);
				
				if (posetl != null)
				{
					// Local orientation
					matrix = matrix_multiply(posetl.matrix_local, matrix)
					
					// Bend
					for (var j = X; j <= Z; j++)
						posebend[j] = posetl.value_inherit[e_value.BEND_ANGLE_X + j]
					
					// IK
					if (array_length(posetl.part_joints_matrix) > 0 && posetl.value[e_value.IK_TARGET] != null)
						matrix = matrix_multiply(posetl.part_joints_matrix[0], matrix)
				}
			}
			
			// No scale or "resize" mode
			if (scale_resize || !inherit_scale || type = e_tl_type.PARTICLE_SPAWNER)
			{
				// Get actual scale
				tl = id
				
				while (true)
				{
					par = tl.parent;
					if (!tl.inherit_scale || par = app)
						break
					sca = vec3_mul(sca, vec3(par.value[e_value.SCA_X], par.value[e_value.SCA_Y], par.value[e_value.SCA_Z]))
					tl = par
				}
				
				// Remove scale
				var parmat;
				
				matrix_remove_scale(matrix_parent)
				parmat = array_copy_1d(matrix_parent)
				
				// Remove rotation
				if (!inherit_rotation)
					matrix_remove_rotation(parmat)
				
				matrixnoscale = matrix_multiply(matrix_create(pos, rot, vec3(1)), parmat);
				
				if (hasik)
					matrixnoscale = matrix_multiply(part_joints_matrix[0], matrixnoscale)
				
				for (var p = 0; p < 11; p++)
					matrix[p] = matrixnoscale[p]
				
				// Re-add calculated or own scale
				if (inherit_scale)
					matrix = matrix_multiply(matrix_create(point3D(0, 0, 0), vec3(0), sca), matrix)
				else
					matrix = matrix_multiply(matrix_create(point3D(0, 0, 0), vec3(0), vec3(value[e_value.SCA_X], value[e_value.SCA_Y], value[e_value.SCA_Z])), matrix) 
			}
			
			// Replace position
			if (!inherit_position)
			{
				matrix_remove_rotation(matrix_parent)
				matrix[MAT_X] = value[e_value.POS_X]
				matrix[MAT_Y] = value[e_value.POS_Y]
				matrix[MAT_Z] = value[e_value.POS_Z]
			}
			
			if (updatecopy)
			{
				if (value[e_value.ROT_TARGET] != null && instance_exists(value[e_value.ROT_TARGET]))
				{
					var target_rot_mat = array_copy_1d(value[e_value.ROT_TARGET].matrix)
					var par = value[e_value.ROT_TARGET];
					var mat = array_copy_1d(matrix)
					matrix_remove_scale(target_rot_mat)
					matrix_remove_scale(mat)
					//BENT Half
					if (par.type = e_tl_type.BODYPART && value[e_value.COPY_ROT_BEND] && par.model_part != null && par.model_part.bend_part != null)
					{
						var bendangle = vec3(par.value_inherit[e_value.BEND_ANGLE_X], par.value_inherit[e_value.BEND_ANGLE_Y], par.value_inherit[e_value.BEND_ANGLE_Z]);
						target_rot_mat = matrix_multiply(model_part_get_bend_matrix(par.model_part, bendangle, point3D(0, 0, 0), vec3(1), par.id), target_rot_mat)
					}
					
					target_rot_mat = matrix_multiply(matrix_create(vec3(0), vec3(value[e_value.COPY_ROT_OFFSET_X], value[e_value.COPY_ROT_OFFSET_Y], value[e_value.COPY_ROT_OFFSET_Z]), vec3(1)), target_rot_mat);
					var prevmatrix = matrix_rotation(matrix)
					matrix_remove_rotation(matrix)
					
					var target_rotation = matrix_rotation(target_rot_mat);
					//var target_rotation = to_euler(value[e_value.ROT_TARGET].world_rot);
					
					target_rotation[X] = (value[e_value.COPY_ROT_X] ? target_rotation[X] : prevmatrix[X])
					target_rotation[Y] = (value[e_value.COPY_ROT_Y] ? target_rotation[Y] : prevmatrix[Y])
					target_rotation[Z] = (value[e_value.COPY_ROT_Z] ? target_rotation[Z] : prevmatrix[Z])
					
		
					matrix = matrix_multiply(matrix_create(vec3(0), point_lerp(matrix_rotation(mat),target_rotation, value[e_value.COPY_ROT_BLEND]), vec3(1)),matrix);

				}
				
				if (value[e_value.POS_TARGET] != null && instance_exists(value[e_value.POS_TARGET]))
				{
					if (value[e_value.COPY_POS_CHILD])
					{
						var pos = vec3(0);
						
						pos[X] = value[e_value.POS_X] + value[e_value.COPY_POS_OFFSET_X]
						pos[Y] = value[e_value.POS_Y] + value[e_value.COPY_POS_OFFSET_Y]
						pos[Z] = value[e_value.POS_Z] + value[e_value.COPY_POS_OFFSET_Z] 
						
						var par = value[e_value.POS_TARGET];
						var mat = array_copy_1d(par.matrix);
						
						//BENT Half
						if (par.type = e_tl_type.BODYPART && value[e_value.COPY_POS_BEND] && par.model_part != null && par.model_part.bend_part != null)
						{
							var bendangle = vec3(par.value_inherit[e_value.BEND_ANGLE_X], par.value_inherit[e_value.BEND_ANGLE_Y], par.value_inherit[e_value.BEND_ANGLE_Z]);
							mat = matrix_multiply(model_part_get_bend_matrix(par.model_part, bendangle, point3D(0, 0, 0), vec3(1), par.id), mat)
						}
						
						mat = matrix_multiply(matrix_create(pos, vec3(0), vec3(1)), mat);
						
						if (value[e_value.COPY_POS_X])
							matrix[MAT_X] = lerp(matrix[MAT_X], mat[MAT_X], value[e_value.COPY_POS_BLEND])
						
						if (value[e_value.COPY_POS_Y])
							matrix[MAT_Y] = lerp(matrix[MAT_Y], mat[MAT_Y], value[e_value.COPY_POS_BLEND])
						
						if (value[e_value.COPY_POS_Z])
							matrix[MAT_Z] = lerp(matrix[MAT_Z], mat[MAT_Z], value[e_value.COPY_POS_BLEND])
					}
					else
					{
						// NOT IS CHILD
						matrix_remove_rotation(matrix_parent)
						
						matrix[MAT_X] = lerp(matrix[MAT_X], value[e_value.POS_X] + value[e_value.POS_TARGET].matrix[MAT_X] + value[e_value.COPY_POS_OFFSET_X], value[e_value.COPY_POS_BLEND] * value[e_value.COPY_POS_X]);
						matrix[MAT_Y] = lerp(matrix[MAT_Y], value[e_value.POS_Y] + value[e_value.POS_TARGET].matrix[MAT_Y] + value[e_value.COPY_POS_OFFSET_Y], value[e_value.COPY_POS_BLEND] * value[e_value.COPY_POS_Y]);
						matrix[MAT_Z] = lerp(matrix[MAT_Z], value[e_value.POS_Z] + value[e_value.POS_TARGET].matrix[MAT_Z] + value[e_value.COPY_POS_OFFSET_Z], value[e_value.COPY_POS_BLEND] * value[e_value.COPY_POS_Z]);
					}
				}
				
				// THIS IS AS CLEAN AS AN UNWIPE BUTT CRACK!!!
				if (value[e_value.LOOK_AT_TARGET] != null && instance_exists(value[e_value.LOOK_AT_TARGET]))
				{
 					var mat = array_copy_1d(matrix);
					var mat2 = matrix_create(vec3(0), vec3(0), vec3(1));
					matrix_remove_scale(mat)
					matrix_remove_scale(mat2)
	
					var lookat_position = vec3(value[e_value.LOOK_AT_TARGET].matrix[MAT_X],value[e_value.LOOK_AT_TARGET].matrix[MAT_Y],value[e_value.LOOK_AT_TARGET].matrix[MAT_Z]);
					
					var angle = point_direction_3d(vec3(matrix[MAT_X], matrix[MAT_Y], matrix[MAT_Z]), lookat_position);
					var angle2 = vec3(value[e_value.LOOK_AT_OFFSET_X], value[e_value.LOOK_AT_OFFSET_Y], value[e_value.LOOK_AT_OFFSET_Z])
					
					mat2 = matrix_multiply(matrix_create(vec3(0),angle, vec3(1)), mat2);
					mat2 = matrix_multiply(matrix_create(vec3(0),angle2, vec3(1)), mat2);
					
					matrix_remove_rotation(matrix);
					matrix = matrix_multiply(matrix_create(vec3(0), point_lerp(matrix_rotation(mat), matrix_rotation(mat2), value[e_value.LOOK_AT_BLEND]), vec3(1)), matrix)
					
				}
			
				if (value[e_value.SCALE_TARGET] != null && instance_exists(value[e_value.SCALE_TARGET]))
				{
					matrix_remove_scale(matrix_parent)
					var scale = vec3(1);
					scale[X] = lerp(value[e_value.SCA_X], value[e_value.SCALE_TARGET].value[e_value.SCA_X], value[e_value.COPY_SCALE_BLEND] *value[e_value.COPY_SCALE_X]);
					scale[Y] = lerp(value[e_value.SCA_Y], value[e_value.SCALE_TARGET].value[e_value.SCA_Y], value[e_value.COPY_SCALE_BLEND] *value[e_value.COPY_SCALE_Y]);
					scale[Z] = lerp(value[e_value.SCA_Z], value[e_value.SCALE_TARGET].value[e_value.SCA_Z], value[e_value.COPY_SCALE_BLEND] *value[e_value.COPY_SCALE_Z]);
					matrix = matrix_multiply(matrix_create(vec3(0), vec3(0), scale), matrix);
				}
			}
			
			// Create rotation point
			if (type = e_tl_type.CAMERA && value[e_value.CAM_ROTATE])
			{
				world_pos_rotate = point3D(matrix[MAT_X], matrix[MAT_Y], matrix[MAT_Z])
				matrix[MAT_X] += lengthdir_x(value[e_value.CAM_ROTATE_DISTANCE], value[e_value.CAM_ROTATE_ANGLE_XY] + 90) * lengthdir_x(1, value[e_value.CAM_ROTATE_ANGLE_Z])
				matrix[MAT_Y] += lengthdir_y(value[e_value.CAM_ROTATE_DISTANCE], value[e_value.CAM_ROTATE_ANGLE_XY] + 90) * lengthdir_x(1, value[e_value.CAM_ROTATE_ANGLE_Z])
				matrix[MAT_Z] += lengthdir_z(value[e_value.CAM_ROTATE_DISTANCE], value[e_value.CAM_ROTATE_ANGLE_Z])
			}
			
			// Set world position
			world_pos = point3D(matrix[MAT_X], matrix[MAT_Y], matrix[MAT_Z])
			
			// Add rotation point
			matrix_render = matrix_multiply(matrix_create(point3D_mul(rot_point_render, -1), vec3(0), vec3(1)), matrix)
			
			// Scale for position controls
			value_inherit[e_value.SCA_X] = 1
			value_inherit[e_value.SCA_Y] = 1
			value_inherit[e_value.SCA_Z] = 1
			tl = id
			
			while (1)
			{
				par = tl.parent
				if (par = app)
					break
			
				value_inherit[e_value.SCA_X] *= par.value[e_value.SCA_X]
				value_inherit[e_value.SCA_Y] *= par.value[e_value.SCA_Y]
				value_inherit[e_value.SCA_Z] *= par.value[e_value.SCA_Z]
				
				if (!par.inherit_scale)
					break
				tl = par
			}
			
			if (modifier_frameskipped)
				continue
			
			// Inherit
			lasttex = value_inherit[e_value.TEXTURE_OBJ]
			ikblend = value[e_value.IK_BLEND] * hasik
			value_inherit[e_value.ALPHA] = value[e_value.ALPHA] // Multiplied
			value_inherit[e_value.RGB_ADD] = value[e_value.RGB_ADD] // Added
			value_inherit[e_value.RGB_SUB] = value[e_value.RGB_SUB] // Added
			value_inherit[e_value.RGB_MUL] = value[e_value.RGB_MUL] // Multiplied
			value_inherit[e_value.HSB_ADD] = value[e_value.HSB_ADD] // Added
			value_inherit[e_value.HSB_SUB] = value[e_value.HSB_SUB] // Added
			value_inherit[e_value.HSB_MUL] = value[e_value.HSB_MUL] // Multiplied
			value_inherit[e_value.MIX_COLOR] = value[e_value.MIX_COLOR] // Added
			value_inherit[e_value.GLOW_COLOR] = value[e_value.GLOW_COLOR] // Multiplied
			value_inherit[e_value.MIX_PERCENT] = value[e_value.MIX_PERCENT] // Added
			value_inherit[e_value.EMISSIVE] = value[e_value.EMISSIVE] // Added
			value_inherit[e_value.METALLIC] = value[e_value.METALLIC] // Added
			value_inherit[e_value.ROUGHNESS] = value[e_value.ROUGHNESS] // Added
			value_inherit[e_value.NORMAL_STRENGTH] = value[e_value.NORMAL_STRENGTH] // Added
			value_inherit[e_value.SUBSURFACE] = value[e_value.SUBSURFACE] // Added
			value_inherit[e_value.SUBSURFACE_RADIUS_RED] = value[e_value.SUBSURFACE_RADIUS_RED] // Multiplied
			value_inherit[e_value.SUBSURFACE_RADIUS_GREEN] = value[e_value.SUBSURFACE_RADIUS_GREEN] // Multiplied
			value_inherit[e_value.SUBSURFACE_RADIUS_BLUE] = value[e_value.SUBSURFACE_RADIUS_BLUE] // Multiplied
			value_inherit[e_value.SUBSURFACE_COLOR] = value[e_value.SUBSURFACE_COLOR] // Multiplied
			value_inherit[e_value.WIND_INFLUENCE] = value[e_value.WIND_INFLUENCE] // Multiplied
			value_inherit[e_value.VISIBLE] = value[e_value.VISIBLE]
			value_inherit[e_value.BEND_ANGLE_X] = value[e_value.BEND_ANGLE_X] * (1 - ikblend) // Added
			value_inherit[e_value.BEND_ANGLE_Y] = value[e_value.BEND_ANGLE_Y] * (1 - ikblend) // Added
			value_inherit[e_value.BEND_ANGLE_Z] = value[e_value.BEND_ANGLE_Z] * (1 - ikblend) // Added
			value_inherit[e_value.TEXTURE_OBJ] = value[e_value.TEXTURE_OBJ] // Overwritten
			value_inherit[e_value.TEXTURE_MATERIAL_OBJ] = value[e_value.TEXTURE_MATERIAL_OBJ] // Overwritten
			value_inherit[e_value.TEXTURE_NORMAL_OBJ] = value[e_value.TEXTURE_NORMAL_OBJ] // Overwritten
			value_inherit[e_value.MODIFIER_FRAMESKIP] = value[e_value.MODIFIER_FRAMESKIP] // Overwritten
			value_inherit[e_value.MODIFIER_FRAMESKIP_VALUE] = value[e_value.MODIFIER_FRAMESKIP_VALUE] // Overwritten
			
			inhalpha = true
			inhcolor = true
			inhglowcolor = true
			inhvis = true
			inhbend = true
			inhtex = true
			inhsurf = true
			inhsubsurf = true
			inhmodifierframeskip = true
			tl = id
			
			for (var j = X; j <= Z; j++)
				value_inherit[e_value.BEND_ANGLE_X + j] += posebend[j] + modifier_shake_bend[j]
			
			while (true)
			{
				par = tl.parent;
				if (par = app)
					break
				
				if (!tl.inherit_alpha)
					inhalpha = false
				
				if (!tl.inherit_color)
					inhcolor = false
				
				if (!tl.inherit_glow_color)
					inhglowcolor = false
				
				if (!tl.inherit_visibility)
					inhvis = false
				
				if (!tl.inherit_bend)
					inhbend = false
				
				if (!tl.inherit_texture || tl.value[e_value.TEXTURE_OBJ] > 0)
					inhtex = false
				
				if (!tl.inherit_surface || tl.value[e_value.TEXTURE_MATERIAL_OBJ] > 0)
					inhsurf = false
				
				if (!tl.inherit_subsurface)
					inhsubsurf = false
				
				if (!tl.inherit_modifier_frameskip)
					inhmodifierframeskip = false
				
				if (inhalpha)
					value_inherit[e_value.ALPHA] *= par.value[e_value.ALPHA]
				
				if (inhcolor)
				{
					if (par.value[e_value.RGB_ADD] != c_black)
						value_inherit[e_value.RGB_ADD] = color_add(value_inherit[e_value.RGB_ADD], par.value[e_value.RGB_ADD])
					
					if (par.value[e_value.RGB_SUB] != c_black)
						value_inherit[e_value.RGB_SUB] = color_add(value_inherit[e_value.RGB_SUB], par.value[e_value.RGB_SUB])
					
					if (par.value[e_value.RGB_MUL] != c_white)
						value_inherit[e_value.RGB_MUL] = color_multiply(value_inherit[e_value.RGB_MUL], par.value[e_value.RGB_MUL])
					
					if (par.value[e_value.HSB_ADD] != c_black)
						value_inherit[e_value.HSB_ADD] = color_add(value_inherit[e_value.HSB_ADD], par.value[e_value.HSB_ADD])
					
					if (par.value[e_value.HSB_SUB] != c_black)
						value_inherit[e_value.HSB_SUB] = color_add(value_inherit[e_value.HSB_SUB], par.value[e_value.HSB_SUB])
					
					if (par.value[e_value.HSB_MUL] != c_white)
						value_inherit[e_value.HSB_MUL] = color_multiply(value_inherit[e_value.HSB_MUL], par.value[e_value.HSB_MUL])
					
					if (par.value[e_value.MIX_COLOR] != c_black)
						value_inherit[e_value.MIX_COLOR] = color_add(value_inherit[e_value.MIX_COLOR], par.value[e_value.MIX_COLOR])
					
					value_inherit[e_value.MIX_PERCENT] = clamp(value_inherit[e_value.MIX_PERCENT] + par.value[e_value.MIX_PERCENT], 0, 1)
				}
				
				if (inhsurf)
				{
					value_inherit[e_value.TEXTURE_MATERIAL_OBJ] = par.value[e_value.TEXTURE_MATERIAL_OBJ]
					value_inherit[e_value.TEXTURE_NORMAL_OBJ] = par.value[e_value.TEXTURE_NORMAL_OBJ]
					value_inherit[e_value.METALLIC] = clamp(value_inherit[e_value.METALLIC] + par.value[e_value.METALLIC], 0, 1)
					value_inherit[e_value.ROUGHNESS] = clamp(value_inherit[e_value.ROUGHNESS] * par.value[e_value.ROUGHNESS], 0, 1)
					value_inherit[e_value.EMISSIVE] = (value_inherit[e_value.EMISSIVE] + par.value[e_value.EMISSIVE])
					value_inherit[e_value.NORMAL_STRENGTH] = (value_inherit[e_value.NORMAL_STRENGTH] * par.value[e_value.NORMAL_STRENGTH])
				}
				
				if (inhsubsurf)
				{
					value_inherit[e_value.SUBSURFACE] = value_inherit[e_value.SUBSURFACE] + par.value[e_value.SUBSURFACE]
					value_inherit[e_value.SUBSURFACE_RADIUS_RED] = clamp(value_inherit[e_value.SUBSURFACE_RADIUS_RED] * par.value[e_value.SUBSURFACE_RADIUS_RED], 0, 1)
					value_inherit[e_value.SUBSURFACE_RADIUS_GREEN] = clamp(value_inherit[e_value.SUBSURFACE_RADIUS_GREEN] * par.value[e_value.SUBSURFACE_RADIUS_GREEN], 0, 1)
					value_inherit[e_value.SUBSURFACE_RADIUS_BLUE] = clamp(value_inherit[e_value.SUBSURFACE_RADIUS_BLUE] * par.value[e_value.SUBSURFACE_RADIUS_BLUE], 0, 1)
					
					if (par.value[e_value.SUBSURFACE_COLOR] != c_white)
						value_inherit[e_value.SUBSURFACE_COLOR] = color_multiply(value_inherit[e_value.SUBSURFACE_COLOR], par.value[e_value.SUBSURFACE_COLOR])
				}
				
				if (inhglowcolor && (par.value[e_value.GLOW_COLOR] != c_white))
					value_inherit[e_value.GLOW_COLOR] = color_multiply(value_inherit[e_value.GLOW_COLOR], par.value[e_value.GLOW_COLOR])
				
				if (inhvis)
					value_inherit[e_value.VISIBLE] *= par.value[e_value.VISIBLE]
					
				if (inhbend)
				{
					value_inherit[e_value.BEND_ANGLE_X] += par.value[e_value.BEND_ANGLE_X]
					value_inherit[e_value.BEND_ANGLE_Y] += par.value[e_value.BEND_ANGLE_Y]
					value_inherit[e_value.BEND_ANGLE_Z] += par.value[e_value.BEND_ANGLE_Z]
				}
				
				if (inhtex)
					value_inherit[e_value.TEXTURE_OBJ] = par.value[e_value.TEXTURE_OBJ]
				
				value_inherit[e_value.WIND_INFLUENCE] *= par.value[e_value.WIND_INFLUENCE]
				
				if (inhmodifierframeskip)
				{
					value_inherit[e_value.MODIFIER_FRAMESKIP] = par.value[e_value.MODIFIER_FRAMESKIP]
					value_inherit[e_value.MODIFIER_FRAMESKIP_VALUE] = par.value[e_value.MODIFIER_FRAMESKIP_VALUE]
				}
				
				tl = par
			}
			
			colors_ext = (value_inherit[e_value.ALPHA] < 1 ||
						  value_inherit[e_value.RGB_ADD] - value_inherit[e_value.RGB_SUB] != c_black ||
						  value_inherit[e_value.HSB_ADD] - value_inherit[e_value.HSB_SUB] != c_black ||
						  value_inherit[e_value.HSB_MUL] < c_white ||
						  value_inherit[e_value.MIX_PERCENT] > 0 ||
						  part_mixing_shapes)
			
			// Add bend angle from IK
			if (hasik)
				value_inherit[e_value.BEND_ANGLE_X] += (part_joint_bend_angle + ((value[e_value.IK_TARGET_OFFSET]) ? value[e_value.BEND_ANGLE_X] : 0)) * ikblend
			
			if ((value_inherit[e_value.ALPHA] * 1000) != 0)
			{
				// Update 3D planes if texture changed
				if (lasttex != value_inherit[e_value.TEXTURE_OBJ] && model_part != null && model_part.has_3d_plane)
					tl_update_model_shape()
				else
				// Update bend if angle changed
					tl_update_model_shape_bend()
			}
			
			// Update objects following this path
			if (type = e_tl_type.PATH)
			{
				with (obj_timeline)
				{
					if (value[e_value.PATH_OBJ] = other.id)
						update_matrix = true
				}
			}
			
			// Update path
			if (type = e_tl_type.PATH_POINT && parent != app && parent.type = e_tl_type.PATH)
				parent.path_update = true
			
			if (update_matrix)
			{
				// Update children
				for (var t = 0; t < ds_list_size(tree_list); t++)
					tree_list[|t].update_matrix = true
			}
			
			// Update render resource
			if (lasttex != value_inherit[e_value.TEXTURE_OBJ] && tl_get_visible())
				render_update_tl_resource()
			
			update_matrix = false
		}
	}
	
	update_matrix = false
	
	if (updateik)
	{
		if (app.project_ik_part_array = null)
		{
			app.project_ik_part_array = []
			with (obj_timeline)
				if (tl_supports_ik())
					array_add(app.project_ik_part_array, id)
		}
		
		tl_update_ik(app.project_ik_part_array)
	}
	
	// Update models with "inherit pose"
	if (updateik && !updatepose && array_length(app.project_inherit_pose_array) > 0)
	{
		for (var i = 0; i < array_length(app.project_inherit_pose_array); i++)
			app.project_inherit_pose_array[i].update_matrix = true
		
		with (app)
			tl_update_matrix(false, false, true, false, false)
		
		app.project_inherit_pose_array = []
	}
	
	// Update models with copy position
	if (updateik && !updatecopy && array_length(app.project_copy_obj_array) > 0)
	{
		for (var i = 0; i < array_length(app.project_copy_obj_array); i++)
			app.project_copy_obj_array[i].update_matrix = true
		
		with (app)
			tl_update_matrix(false, true, false, true, false)
		
		app.project_copy_obj_array = []
	}
}
