extends SliderElement


@export var AUDIO_BUS: String


func _apply_settings() -> void:
    current_value = clampf(current_value, min_value, max_value)
    print("applied " + id + " with value: ", str(current_value))
    parent_section.cache_setting(id, current_value)
    var bus_idx: int = AudioServer.get_bus_index(AUDIO_BUS)
    parent_section.settings_menu.audio_settings.set_volume_for(bus_idx, current_value, AUDIO_BUS == "Sfx")
