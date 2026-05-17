extends SliderElement


func _apply_settings() -> void:
    current_value = clampf(current_value, min_value, max_value)
    parent_section.cache_setting(id, current_value)
    # set brightness for environment nodes to load on ready
    if GameManager.get("brightness") != null:
        GameManager.brightness = current_value
    if GameManager.get("environment_res") != null:
        GameManager.environment_res.adjustment_brightness = current_value
