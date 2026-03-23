/// render_world_tl_obj()
/// @desc Renders the 3D model of the timeline.

function render_world_tl_obj()
{
	if (type != e_tl_type.PARTICLE_SPAWNER)
	{
		matrix_set(matrix_world, matrix_render)
		
		// Reset material textures for other timelines
		if (type != e_tl_type.SCENERY && type != e_tl_type.BLOCK)
		{
			render_set_texture(spr_default_material, "Material")
			render_set_texture(spr_default_normal, "Normal")
			render_set_uniform_int("uMaterialFormat", e_material.FORMAT_NONE)
		}
		
		render_set_uniform_vec2("uTextureOffset", 0, 0)
		
		switch (type)
		{
			case e_tl_type.BODYPART:
			{
				if (model_part = null || render_res_diffuse = null)
					break
				
				render_world_model_part(model_part, render_res_diffuse, temp.model_texture_name_map, model_shape_vbuffer_map, temp.model_color_map, temp.model_shape_hide_list, temp.model_shape_texture_name_map, self)
				break
			}
			
			case e_tl_type.SCENERY:
			case e_tl_type.BLOCK:
			{
				if (type = e_tl_type.BLOCK)
					render_world_block(temp.block_vbuffer, [render_res_diffuse, render_res_material, render_res_normal], true, temp.block_repeat_enable ? temp.block_repeat : vec3(1), temp)
				else if (temp.scenery)
					render_world_scenery(temp.scenery, [render_res_diffuse, render_res_material, render_res_normal], temp.block_repeat_enable, temp.block_repeat)
				break
			}
			
			// case e_tl_type.OBJ:
			
			case e_tl_type.ITEM:
			{
				if (item_vbuffer = null)
					render_world_item(temp.item_vbuffer, temp.item_3d, temp.item_face_camera, temp.item_bounce, temp.item_spin, [item_res, item_material_res, item_normal_res])
				else
					render_world_item(item_vbuffer, temp.item_3d, temp.item_face_camera, temp.item_bounce, temp.item_spin, [item_res, item_material_res, item_normal_res])
				break
			}
			
			case e_tl_type.TEXT:
			{
				var font = value[e_value.TEXT_FONT];
				if (font = null)
					font = temp.text_font
				render_world_text(text_vbuffer, text_texture, temp.text_face_camera, text_res, value[e_value.TEXT_OUTLINE] ? value[e_value.TEXT_OUTLINE_COLOR] : null)
				break
			}
			
			case e_tl_type.MODEL:
			{
				if (temp.model != null)
				{
					var res = value_inherit[e_value.TEXTURE_OBJ];
					if (res = null)
						res = temp.model_tex
					if (res = null || res.block_sheet_texture = null)
						res = mc_res
					render_world_block(temp.model.block_vbuffer, res)
					
					with (temp)
						res = temp_get_model_texobj(other.value_inherit[e_value.TEXTURE_OBJ])
					render_world_block_map(temp.model.model_block_map, res)
				}
				break
			}
			
			case e_tl_type.PATH:
			{
				if (path_vbuffer != null)
				{
					var tex, texmat, texnorm;
					
					if (value_inherit[e_value.TEXTURE_OBJ] = null)
						tex = spr_shape
					else
						tex = value_inherit[e_value.TEXTURE_OBJ].texture
					
					if (value_inherit[e_value.TEXTURE_MATERIAL_OBJ] = null)
					{
						texmat = spr_default_material
						render_set_uniform_int("uMaterialFormat", e_material.FORMAT_NONE)
					}
					else
					{
						texmat = value_inherit[e_value.TEXTURE_MATERIAL_OBJ].texture
						render_set_uniform_int("uMaterialFormat", value_inherit[e_value.TEXTURE_MATERIAL_OBJ].material_format)
					}
					
					if (value_inherit[e_value.TEXTURE_NORMAL_OBJ] = null)
						texnorm = spr_default_normal
					else
						texnorm = value_inherit[e_value.TEXTURE_NORMAL_OBJ].texture
					
					render_set_texture(tex)
					render_set_texture(texmat, "Material")
					render_set_texture(texnorm, "Normal")
					
					vbuffer_render(path_vbuffer)
				}
				else if (render_mode = e_render_mode.CLICK)
				{
					render_set_texture(spr_shape)
					render_set_texture(spr_default_material, "Material")
					render_set_texture(spr_default_normal, "Normal")
					render_set_uniform_int("uMaterialFormat", e_material.FORMAT_NONE)
					
					vbuffer_render(path_select_vbuffer)
				}
				
				break
			}
			
			default: // Shapes
			{
				var tex, matres, texmat, normtex;
				with (temp)
				{
					tex = temp_get_shape_tex(temp_get_shape_texobj(other.value_inherit[e_value.TEXTURE_OBJ]))
					
					matres = temp_get_shape_tex_material_obj(other.value_inherit[e_value.TEXTURE_MATERIAL_OBJ])
					texmat = temp_get_shape_tex(matres, spr_default_material)
					normtex = temp_get_shape_tex(temp_get_shape_tex_normal_obj(other.value_inherit[e_value.TEXTURE_NORMAL_OBJ]), spr_default_normal)
					
					if (matres != null)
						render_set_uniform_int("uMaterialFormat", matres.material_format)
					else
						render_set_uniform_int("uMaterialFormat", e_material.FORMAT_NONE)
				}
				
				render_world_shape(temp.type, temp.shape_vbuffer, temp.shape_face_camera, [tex, texmat, normtex])
				break
			}
		}
	} 
	else if (render_particles) 
	{
		for (var p = 0; p < ds_list_size(particle_list); p++)
			with (particle_list[|p])
				render_world_particle()
	}
	
	matrix_world_reset()
	shader_texture_surface = false
}
