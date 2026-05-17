extends OptionElement


func _init() -> void:
    option_list = {
        "Ultra Quality": 0.77,
        "Quality": 0.67,
        "Balanced": 0.59,
        "Performance": 0.5,
    }


func _apply_settings() -> void:
    print("applied " + id + " with value: ", str(current_value))
    parent_section.cache_setting(id, current_value)
    get_viewport().set_scaling_3d_scale(option_list[current_value])
