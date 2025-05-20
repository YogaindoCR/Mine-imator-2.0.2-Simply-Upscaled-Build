/// render_high()
/// @desc Renders the scene in high quality with all applicable effects.

function render_high()
{
	var start_time = current_time;
	render_surface_time = 0;

	// Prepare sampling
	render_update_samples();
	render_alpha_hash = project_render_alpha_mode;

	var sample_start, sample_end;

	if (render_samples_done)
	{
		sample_start = 0;
		sample_end = 0;
	}
	else
	{
		sample_start = render_samples - 1;
		sample_end = render_samples;
	}

	// Main rendering loop
	for (var s = sample_start; s < sample_end; s++)
	{
		render_sample_current = s;
		random_set_seed(s); // consistent sample noise

		render_high_update_taa();
		render_high_passes();

		if (render_shadows)
			render_high_shadows();

		if (render_indirect)
			render_high_indirect();

		if (render_ssao)
			render_high_ssao();

		// Scene composition
		var final_surf = render_high_scene();

		if (render_reflections)
			render_high_reflections(final_surf);

		final_surf = render_high_tonemap(final_surf);

		if (background_fog_show)
			render_high_fog(final_surf);

		// Post-scene effects (Glow, DoF, etc.)
		render_refresh_effects(true, false);
		final_surf = render_post(final_surf, true, false);

		// Final render output
		render_target = surface_require(render_target, render_width, render_height);
		surface_set_target(render_target);
		{
			draw_clear_alpha(c_black, render_pass ? 1 : 0);
			draw_surface_exists(render_pass ? render_pass_surf : final_surf, 0, 0);
		}
		surface_reset_target();

		render_high_samples_add();
	}

	// Combine multi-sample render result
	render_high_samples_unpack();

	// Final post-processing (Bloom, LUT, etc.)
	if (!render_pass)
	{
		var main_surf = surface_require(render_surface[0], render_width, render_height);

		// Copy target to working surface
		gpu_set_blendmode_ext(bm_one, bm_zero);
		surface_set_target(main_surf);
		{
			draw_clear_alpha(c_black, 0);
			draw_surface_exists(render_target, 0, 0);
		}
		surface_reset_target();

		// Apply final post-processing effects
		gpu_set_blendmode(bm_normal);
		render_refresh_effects(false, true);
		main_surf = render_post(main_surf, false, true);

		// Copy final result back to render target
		gpu_set_blendmode_ext(bm_one, bm_zero);
		surface_set_target(render_target);
		{
			draw_clear_alpha(c_black, 0);
			draw_surface_exists(main_surf, 0, 0);
		}
		surface_reset_target();
		gpu_set_blendmode(bm_normal);
	}

	// Cleanup and state reset
	taa_matrix = MAT_IDENTITY;
	render_samples_clear = false;
	render_alpha_hash = false;

	render_time = current_time - start_time - render_surface_time;
}
