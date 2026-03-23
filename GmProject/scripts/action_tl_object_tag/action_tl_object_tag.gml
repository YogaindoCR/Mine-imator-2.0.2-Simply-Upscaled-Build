/// action_tl_object_tag(text)
/// @arg text

function action_tl_object_tag(text)
{
	if (history_undo)
	{
		with (history_data)
		{
			for (var t = 0; t < save_var_amount; t++)
			{
				with (save_id_find(save_var_save_id[t]))
				{
					object_tag = other.save_var_old_value[t]
					object_tag_int = string_hash_to_int(other.save_var_old_value[t])
				}
			}
		}
	}
	else if (history_redo)
	{
		with (history_data)
		{
			for (var t = 0; t < save_var_amount; t++)
			{
				with (save_id_find(save_var_save_id[t]))
				{
					object_tag = other.save_var_new_value[t]
					object_tag_int = string_hash_to_int(other.save_var_new_value[t])
				}
			}
		}
	}
	else
	{
		var hobj = history_save_var_start(action_tl_object_tag, false);
		
		with (obj_timeline)
		{
			if (!selected && !parent_is_selected)
				continue
			
			with (hobj)
				history_save_var(other.id, other.object_tag, text)
			
			object_tag = text
			object_tag_int = string_hash_to_int(text)
		}
	}
}