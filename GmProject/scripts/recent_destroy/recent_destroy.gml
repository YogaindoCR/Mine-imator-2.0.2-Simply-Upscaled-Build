/// recent_destroy()

function recent_destroy()
{
	with (obj_recent)
	{
		texture_free(thumbnail)
		instance_destroy()
	}
}
