extends SliderElement


func _apply_settings() -> void:
    current_value = clampf(current_value, min_value, max_value)
    print("applied " + id + " with value: ", str(current_value))
    parent_section.cache_setting(id, current_value)
    get_viewport().set_scaling_3d_scale(current_value)
