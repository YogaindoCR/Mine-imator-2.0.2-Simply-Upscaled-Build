/// generate_shake_value(step, strength, offset)
/// @arg step
/// @arg strength
/// @arg offset

function generate_shake_value(step, shakestrength, shakeoffset){
	var shake
	shake = vec3(
					simplex_lib(step, 0, shakeoffset) * shakestrength,
					simplex_lib(step, 1000, shakeoffset) * shakestrength,
					simplex_lib(step, 2000, shakeoffset) * shakestrength,
				);
	return shake;
}