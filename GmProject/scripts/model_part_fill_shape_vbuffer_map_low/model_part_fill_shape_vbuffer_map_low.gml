/// model_part_fill_shape_vbuffer_map_low(part, vbuffermap, alphamap, bend)
/// @arg part
/// @arg vbuffermap
/// @arg alphamap
/// @arg bend
/// @desc Clears and fills the given map with vbuffers for the 3D shapes, bent by a rotation vector.

function model_part_fill_shape_vbuffer_map_low(part, vbufmap, alphamap, bend, vbufmapcache)
{
	// Clamp
	for (var i = X; i <= Z; i++)
		bend[X + i] = clamp(bend[X + i], part.bend_direction_min[i], part.bend_direction_max[i])
	
	if (part.shape_list = null)
		return 0
	
	var isbent = !vec3_equals(bend, vec3(0));
	for (var s = 0; s < ds_list_size(part.shape_list); s++)
	{
		with (part.shape_list[|s])
		{
			var cacheid = string(round(bend[0] * 4) / 4) + "_" + string(round(bend[1] * 4) / 4) + "_" + string(round(bend[2] * 4) / 4) + string(s);
			
			if (ds_map_exists(vbufmapcache, cacheid) && !vbuffer_is_empty(vbufmapcache[? cacheid]))
			{
			    vbufmap[? id] = vbufmapcache[? cacheid];
			    continue;
			}

			var vbuf = vbuffer_default;

			if (type == "block" && bend_shape && isbent)
			    vbuf = model_shape_generate_block(bend);
			else if (type == "plane")
			{
			    if (is3d)
			    {
			        if (ds_map_valid(alphamap))
			            vbuf = model_shape_generate_plane_3d(bend, alphamap[? id]);
			    }
			    else if (isbent && bend_shape)
			        vbuf = model_shape_generate_plane(bend);
			}
			
			if (vbuf != vbuffer_default)
			{
				vbufmap[? id] = vbuf;
				vbufmapcache[? cacheid] = vbuf;
			}
			else
				vbufmap[? id] = vbuffer_default
		}
	}
}
