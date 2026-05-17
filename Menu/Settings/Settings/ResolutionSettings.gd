extends RefCounted
class_name ResolutionSettings


var owner: SettingsMenu

func _init(_owner: SettingsMenu) -> void:
    owner = _owner


func set_resolution(new_value: Vector2i) -> bool:
    var mode: int = DisplayServer.window_get_mode()
    match mode:
        DisplayServer.WINDOW_MODE_MAXIMIZED, \
        DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, \
        DisplayServer.WINDOW_MODE_FULLSCREEN:
            return false
    if DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
        return false
    var window := owner.get_window()
    var current_size := window.get_size()
    if current_size == new_value: return false
    window.set_size(new_value)
    owner.get_viewport().set_size(new_value)
    window.move_to_center()
    return true
