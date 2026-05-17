@abstract
extends SettingsOption
class_name OptionElement
## Option button category of settings

@export var default_value: String

var option_list
var selected_idx: int

@abstract
func _apply_settings() -> void


func _ready():
    super._ready()
    option_list.make_read_only()
    btn.item_selected.connect(_on_option_selected)


func init_element() -> void:
    btn.clear()
    add_option_items()


func get_valid_values() -> Dictionary:
    if !option_list.has(default_value):
        push_error("Invalid default value for element '" + id + "'.")
        if option_list is Dictionary:
            default_value = option_list.keys().back()
        else:
            default_value = option_list[option_list.size() - 1]
    var _data: Dictionary = {
        "default_value": default_value,
        "valid_options": option_list
    }
    return _data


func add_option_items() -> void:
    var idx: int = 0
    var item_count: int = btn.item_count
    for key in option_list:
        if item_count == 0:
            btn.add_item(key)
        if key == current_value:
            btn.select(idx)
            selected_idx = idx
        idx += 1


func _on_option_selected(idx: int) -> void:
    if parent_section.settings_cache.size() == 0:
        printerr("Settings cache is empty for '" + section + "' on element '" + id + "'")
        return
    var text: String = btn.get_item_text(idx)
    parent_section.settings_changed(id, text)
    if update_immediately and parent_section.settings_menu.update_immediately:
        parent_section.apply_stored_changes()
