##@experimental
extends RefCounted
class_name VideoSettings
## may not need

var owner: SettingsMenu

func _init(_owner: SettingsMenu) -> void:
    owner = _owner


func set_fullscreen(value: bool) -> void:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED)
