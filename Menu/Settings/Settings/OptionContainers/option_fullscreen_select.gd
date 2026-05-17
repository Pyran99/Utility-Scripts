##@experimental
extends OptionElement


func _init() -> void:
    option_list = {
        "Fullscreen": DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
        "Windowed": DisplayServer.WINDOW_MODE_WINDOWED,
        "Borderless": DisplayServer.WINDOW_MODE_WINDOWED,
    }


func load_settings(apply_values: bool) -> void:
    super.load_settings(apply_values)
    check_resolution.call_deferred()


func _on_option_selected(idx: int) -> void:
    super._on_option_selected(idx)
    check_resolution()


func _apply_settings() -> void:
    print("applied " + id + " with value: ", str(current_value))
    set_fullscreen_select()


func set_fullscreen_select() -> void:
    DisplayServer.window_set_mode(option_list[current_value])
    if current_value == "Borderless":
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
        adjust_resolution()
    else:
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
    if current_value == "Windowed":
        if !parent_section.option_elements.has("RESOLUTION"):
            # Set the resolution to 80% if the resolution setting doesnt exist
            # covers most of the screen
            adjust_resolution(0.8)
            return
        # Apply the selected resolution manually if it has not been changed
        if !parent_section.cached_changes.has("RESOLUTION"):
            # Resolution change has to be delayed by at least 2 frames.
            # Otherwise height of the window will be off by a bit.
            await get_tree().process_frame
            await get_tree().process_frame
            parent_section.option_elements["RESOLUTION"]._apply_settings()

## Check if the resolution element should be disabled
func check_resolution() -> void:
    if !parent_section.option_elements.has("RESOLUTION"):
        return
    var res: SettingsOption = parent_section.option_elements["RESOLUTION"]
    if current_value != "Windowed":
        res.btn.disabled = true
    else:
        res.btn.disabled = false

## Scale the resolution to the provided percentage
func adjust_resolution(_scale: float = 1.0) -> void:
    var display_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()) * _scale
    get_window().set_size(display_size)
    get_viewport().set_size(display_size)
    get_window().move_to_center()
