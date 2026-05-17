extends OptionElement

## Toggle window resizing by the user.
@export var resizable: bool = false


func _init() -> void:
    option_list = {
        "3840x2160": Vector2i(3840, 2160),
        "2560x1440": Vector2i(2560, 1440),
        "1920x1080": Vector2i(1920, 1080),
        "1600x900": Vector2i(1600, 900),
        "1440x900": Vector2i(1440, 900),
        "1366x768": Vector2i(1366, 768),
        "1280x1024": Vector2i(1280, 1024),
        "1280x720": Vector2i(1280, 720),
        "960x540": Vector2i(960, 540),
        "800x600": Vector2i(800, 600),
    }
    var max_screen_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
    var dupe: Dictionary = option_list.duplicate(true)
    for key in dupe:
        if dupe[key] > max_screen_size:
            option_list.erase(key)


func _ready() -> void:
    super._ready()
    if Engine.is_editor_hint(): return
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, !resizable)
    get_tree().root.size_changed.connect(_on_window_size_changed)
    if parent_section.option_elements.has("FULLSCREEN"):
        parent_section.option_elements["FULLSCREEN"].connect("toggled_fullscreen", _on_fullscreen_toggled)


func _apply_settings() -> void:
    if _reset_selected_if_fullscreen(): return
    print("applied " + id + " with value: ", str(current_value))
    var last_value = ""
    if parent_section.settings_cache.has(id):
        last_value = parent_section.settings_cache[id]
    var success: bool = parent_section.settings_menu.resolution_settings.set_resolution(option_list[current_value])
    if !success:
        for key in option_list:
            if key != last_value: continue
            current_value = key
            btn.selected = option_list.keys().find(key)
            break
    parent_section.cache_setting(id, current_value)


func _reset_selected_if_fullscreen() -> bool:
    if !parent_section.cached_changes.has("FULLSCREEN") or !parent_section.settings_cache.has("FULLSCREEN"):
        return false
    var fullscreen: SettingsOption = parent_section.option_elements.get("FULLSCREEN")
    if fullscreen:
        if fullscreen.current_value == true or parent_section.cached_changes["FULLSCREEN"] == true:
            current_value = parent_section.settings_cache[id]
            (btn as OptionButton).selected = option_list.keys().find(current_value)
            return true
    return false


func _on_window_size_changed() -> void:
    var mode := DisplayServer.window_get_mode()
    btn.disabled = mode == DisplayServer.WINDOW_MODE_MAXIMIZED


func _on_fullscreen_toggled(is_fullscreen: bool) -> void:
    if is_fullscreen:
        btn.disabled = true
        return
    var mode := DisplayServer.window_get_mode()
    if mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
        btn.disabled = true
        return
    btn.disabled = false
