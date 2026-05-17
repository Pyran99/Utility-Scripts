extends SliderElement


func _apply_settings() -> void:
    current_value = clampf(current_value, min_value, max_value)
    print("applied " + id + " with value: ", str(current_value))
    parent_section.cache_setting(id, current_value)
    # for 0-100%, sharpness is 0-2
    get_viewport().set_fsr_sharpness((max_value - current_value) * 2.0)
