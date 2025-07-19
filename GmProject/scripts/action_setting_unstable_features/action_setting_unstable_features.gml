/// action_setting_unstable_features(value)
/// @arg value

function action_setting_unstable_features(val)
{
	if (val)
	{
		if (!question(text_get("questionunstablefeatures")))
			return 0
	}
	setting_unstable_features = val
}
