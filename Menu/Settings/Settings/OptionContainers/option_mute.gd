extends CheckboxElement


func _apply_settings() -> void:
    print("applied " + id + " with value: ", str(current_value))
    parent_section.cache_setting(id, current_value)
    parent_section.settings_menu.audio_settings.set_mute(current_value)
