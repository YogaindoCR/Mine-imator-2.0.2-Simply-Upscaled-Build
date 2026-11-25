
/// window_draw_load_assets()

function window_draw_load_assets()
{
    if (!minecraft_assets_load())
    {
        error("errorloadassets")
        game_end()
        return 0
    }

    draw_clear(c_level_top)

    if (load_assets_stage = "done")
    {
        load_assets_stage = "exit"
        return 0
    }
    else if (load_assets_stage = "exit")
    {
        window_taskbar_progress_state_set()
        window_flash()

        window_state = "startup"
        app_startup_interface()

        instance_deactivate_object(obj_deactivate)
        play_audio_from_files(audio_directory + "startup.ogg")

        return 0
    }
    else
        window_taskbar_progress_state_set(e_window_taskbar_state.NORMAL)
		
    var screenwid = 740
    var screenhei = 450

    // var sidebarwid = 0 // 190

    var xoff = floor((window_width / 2) - (screenwid / 2))
    var yoff = floor((window_height / 2) - (screenhei / 2))

    content_x = 28
    content_y = 28
    content_width = window_width - 56
    content_height = window_height - 56
	
	// Background
    draw_box(xoff, yoff, screenwid, screenhei, false, c_level_middle, 1)

    if (load_assets_splash != null)
    {
        var texwid = sprite_get_width(load_assets_splash)
        var texhei = sprite_get_height(load_assets_splash)

        // Scale to cover the entire window.
        // Excess image area is cropped automatically.

        var texsca = max(screenwid / texwid, screenhei / texhei)

        var drawwid = texwid * texsca
        var drawhei = texhei * texsca

        var drawx = xoff + (screenwid - drawwid) / 2
        var drawy = yoff + (screenhei - drawhei) / 2

        draw_sprite_ext(load_assets_splash, 0, drawx, drawy, texsca, texsca, 0, c_white, 1)
    }

    // Left sidebar
    // Dark translucent background
    // draw_box(xoff, yoff, sidebarwid, screenhei - 4, false, c_level_top, 0.92)

    // Accent separator
    // draw_box(xoff + sidebarwid - 2, yoff, 2, screenhei - 4, false, c_accent, 0.8)
	
    // Branding
	draw_gradient(xoff, yoff, screenwid, 128, c_black, 0.5, 0.5, 0.0, 0.0)
    draw_sprite_ext(spr_load_assets, 0, xoff + 62, yoff + 72, 0.5, 0.5, 0, c_white, 1)
    draw_sprite_ext(spr_ave_x, 0, xoff + 30, yoff + 92, 0.07, 0.07, 0, c_white, 1)
    
	var afterlogo = 122
	
	draw_label("Mine-imator " + string(mineimator_version), xoff + afterlogo, yoff + 37, fa_left, fa_bottom, c_text_main, a_text_main, font_heading)
    // draw_label(string(mineimator_version), xoff + 82, yoff + 37, fa_left, fa_bottom,c_text_secondary, a_text_secondary, font_subheading)

    if (mineimator_version_sub != "")
        draw_label(string_upper(mineimator_version_sub), xoff + afterlogo, yoff + 57, fa_left, fa_bottom, c_text_secondary, a_text_secondary, font_subheading)
    
	if (mineimator_version_extra != "")
        draw_label(string_upper(mineimator_version_extra), xoff + afterlogo, yoff + 77, fa_left, fa_bottom, c_text_tertiary, a_text_tertiary, font_subheading)

    // Loading information
	draw_gradient(xoff, yoff + screenhei - 80, screenwid, 80, c_black, 0.0, 0.0, 1.0, 1.0)
    draw_label("LOADING", xoff + 12, yoff + screenhei - 32, fa_left, fa_bottom, c_text_main, a_text_secondary, font_subheading)
    draw_label(text_get("startuploadingassets", app.setting_minecraft_assets_version, floor(load_assets_progress * 100)), xoff + 12, yoff + screenhei - 14, fa_left, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)

    // Description
    if (load_assets_description != "")
    {
        // Subtle dark backing for text readability.
        // draw_box(xoff + sidebarwid + 12, yoff + screenhei - 57, screenwid - sidebarwid - 24, 49, false, c_level_top, 0.7)
        
		draw_label(text_get("startupsplashdescription", load_assets_description),
            xoff + screenwid - 12,
            yoff + screenhei - 32,
            fa_right, fa_bottom,
            c_text_main, a_text_secondary,
            font_caption, 12,
            screenwid - 12
        )

        if (load_assets_credits != "")
        {
            draw_label(text_get("startupsplashauthor", load_assets_credits),
                xoff + screenwid - 12,
                yoff + screenhei - 14,
                fa_right, fa_bottom,
                c_text_secondary, a_text_tertiary,
                font_caption
            )
        }
    }
    else if (load_assets_credits != "")
        draw_label(text_get("startupsplashauthor", load_assets_credits), xoff + screenwid - 18, yoff + screenhei - 22, fa_right, fa_bottom, c_text_secondary, a_text_tertiary, font_caption)
	
	var totalhead = 3
	for(var i = 0; i < sprite_get_number(spr_head); i++)
	{
		draw_sprite_ext(spr_head, i, xoff + screenwid - (totalhead * 20) - 20  + (i * 20) + 10, yoff + 14, 2, 2, 0, c_white, 0.5)
	}

    // Progress bar
    draw_box(xoff, yoff + screenhei - 4, screenwid, 4, false, c_level_top, 1)
    draw_box(xoff, yoff + screenhei - 4, screenwid * clamp(load_assets_progress, 0, 1), 4, false, c_accent, 1)

    // Outline
    draw_outline(xoff, yoff, screenwid, screenhei, 1, c_border, a_border, true)

    current_step++
}
