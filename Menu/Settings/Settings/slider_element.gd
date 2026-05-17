@abstract
extends SettingsOption
class_name SliderElement


@export var value_display: Control
@export var default_value: float = 0.5
@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var step: float = 0.1
@export var display_as_percent: bool = false
@export var value_suffix: String = ""


@abstract
func _apply_settings() -> void


func init_element() -> void:
    init_slider(100 if display_as_percent else 1)


func init_slider(factor: float) -> void:
    current_value = clampf(current_value, min_value, max_value)
    btn.min_value = min_value
    btn.max_value = max_value
    btn.step = step
    btn.value = current_value
    if !btn.value_changed.is_connected(_on_slider_changed):
        btn.value_changed.connect(_on_slider_changed.bind(factor))
    if value_display is SpinBox:
        pass
    elif value_display is Label:
        if display_as_percent:
            value_display.text = str(snappedi(current_value * factor, 1)) + value_suffix
        else:
            value_display.text = str(current_value)


func get_valid_values() -> Dictionary:
    if default_value > max_value or default_value < min_value:
        default_value = clampf(default_value, min_value, max_value)
    return {
        "default_value": default_value,
        "min_value": min_value,
        "max_value": max_value,
    }


func editable_slider(is_editable) -> void:
    btn.editable = is_editable


func _on_slider_changed(value: float, factor: float) -> void:
    if parent_section.settings_cache.size() == 0: return
    if value_display is SpinBox:
        pass
    elif value_display is Label:
        if display_as_percent:
            value_display.text = str(snappedi(value * factor, 1)) + value_suffix
        else:
            value_display.text = str(value)
    parent_section.settings_changed(id, value)
    if update_immediately and parent_section.settings_menu.update_immediately:
        parent_section.apply_stored_changes()
