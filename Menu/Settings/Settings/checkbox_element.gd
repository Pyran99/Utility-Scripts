@abstract
extends SettingsOption
class_name CheckboxElement

@export var default_value: bool

@abstract
func _apply_settings() -> void


func _connect_signals() -> void:
    super._connect_signals()
    btn.toggled.connect(_on_check_toggled)


func init_element() -> void:
    btn.button_pressed = current_value


func get_valid_values() -> Dictionary:
    var _data: Dictionary = {
        "default_value": default_value,
        "valid_options": {true: true, false: false},
    }
    return _data


func _on_check_toggled(pressed: bool) -> void:
    if parent_section.settings_cache.size() == 0:
        printerr("Settings cache is empty for '" + section + "' on element '" + id + "'")
        return
    parent_section.settings_changed(id, pressed)
    if update_immediately and parent_section.settings_menu.update_immediately:
        parent_section.apply_stored_changes()
