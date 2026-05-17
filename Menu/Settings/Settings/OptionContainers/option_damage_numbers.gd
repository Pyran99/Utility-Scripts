extends CheckboxElement


func _apply_settings() -> void:
    print("applied " + id + " with value: ", str(current_value))
    parent_section.cache_setting(id, current_value)
    # if FloatingDamageNumber.instance == null: return
    # FloatingDamageNumber.instance.is_showing = current_value
