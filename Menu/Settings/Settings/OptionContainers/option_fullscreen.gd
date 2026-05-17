extends CheckboxElement

signal toggled_fullscreen(is_fullscreen: bool)

func _apply_settings() -> void:
    print("applied " + id + " with value: ", str(current_value))
    # parent_section.settings_menu.video_settings.set_fullscreen(current_value)
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if current_value else DisplayServer.WINDOW_MODE_WINDOWED)
    toggled_fullscreen.emit(current_value)
    parent_section.cache_setting(id, current_value)
    
    # apply last resolution when false
    # if current_value == false:
    #     if parent_section.option_elements.has("RESOLUTION"):
    #         adjust_resolution(0.8)
    #         return
    #     if !parent_section.cached_changes.has("RESOLUTION"):
    #         # Resolution change has to be delayed by at least 2 frames.
    #         # Otherwise height of the window will be off by a bit.
    #         await get_tree().process_frame
    #         await get_tree().process_frame
    #         parent_section.option_elements["RESOLUTION"]._apply_settings()


func adjust_resolution(_scale: float = 1.0) -> void:
    var display_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()) * _scale
    get_window().set_size(display_size)
    get_viewport().set_size(display_size)
    get_window().move_to_center()
