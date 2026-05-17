extends OptionElement


func _init() -> void:
    option_list = {
        "30": 30,
        "60": 60,
        "120": 120,
        "144": 144,
        "Unlimited": 0,
}


func _apply_settings() -> void:
    print("applied " + id + " with value: ", str(current_value))
    parent_section.cache_setting(id, current_value)
    Engine.max_fps = option_list[current_value]
