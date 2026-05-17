extends CheckboxElement

# alternate option button
    # "Disabled": DisplayServer.VSYNC_DISABLED,
    # "Enabled": DisplayServer.VSYNC_ENABLED,
    # "Adaptive": DisplayServer.VSYNC_ADAPTIVE

func _apply_settings() -> void:
    print("applied " + id + " with value: ", str(current_value))
    parent_section.cache_setting(id, current_value)
    # parent_section.settings_menu.video_settings.set_vsync(current_value)
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if current_value else DisplayServer.VSYNC_DISABLED)
