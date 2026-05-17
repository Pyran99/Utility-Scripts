@abstract
extends Control
class_name SettingsOption
## Base class for settings options

@export var btn: Control
## The name of this option
@export var id: String
## Shows border around container when hovered/focused
@export var use_border: bool = true
##@experimental
## If this settings needs something in game to modifiy. The setting should not show unless in a game menu or the value it changes is on a Manager
@export var needs_in_game: bool = false
@export var update_immediately: bool = true

var parent_section: SettingsSection
var section: String
var current_value: Variant

var is_multi_element: bool = false
var is_sub_element: bool = false

@onready var border: Panel = %Border
@onready var texture: TextureRect = %TextureRect
@onready var lbl: Label = %Label


@abstract
func init_element() -> void

@abstract
func _apply_settings() -> void

@abstract
func get_valid_values() -> Dictionary


func _enter_tree() -> void:
    if Engine.is_editor_hint(): return
    if !is_multi_element:
        parent_section = owner
        section = parent_section.id


func _ready() -> void:
    if Engine.is_editor_hint(): return
    _connect_signals()
    if !is_sub_element:
        parent_section.option_elements[id] = self
    border.hide()
    lbl.text = tr(id)


func _connect_signals() -> void:
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    SettingsManager.retrieve_settings.connect(load_settings)
    btn.mouse_entered.connect(_on_mouse_entered)
    btn.mouse_exited.connect(_on_mouse_exited)
    btn.focus_entered.connect(_on_mouse_entered)
    btn.focus_exited.connect(_on_mouse_exited)


func load_settings(apply_values: bool) -> void:
    var values: Dictionary = get_valid_values()
    values.make_read_only()
    if SettingsManager.no_save_file:
        current_value = values.get("default_value")
        SettingsManager.update_setting_for(section, id, current_value)
    else:
        if verify_settings_data(values):
            current_value = SettingsManager.get_setting_from(section, id)
        else:
            current_value = values.get("default_value")
            SettingsManager.update_setting_for(section, id, current_value)
            SettingsManager.invalid_save_file = true
    init_element()
    if apply_values == false: return
    if parent_section.settings_menu.is_in_game_menu == needs_in_game or !is_sub_element:
        _apply_settings.call_deferred()


func _on_mouse_entered() -> void:
    btn.grab_focus()
    if !use_border: return
    border.show()


func _on_mouse_exited() -> void:
    # if btn.has_focus(): return
    btn.release_focus()
    if !use_border: return
    border.hide()


#region validate data

func verify_settings_data(_values: Dictionary) -> bool:
    if not entry_exists():
        return false
    var retrieved_value = SettingsManager.settings_data[section][id]
    if not is_valid_type(_values, retrieved_value):
        return false
    if not is_valid_value(_values, retrieved_value):
        return false
    return true


func entry_exists() -> bool:
    if not SettingsManager.settings_data.has(section):
        push_error("Settings section missing: ", section)
        return false
    if not SettingsManager.settings_data[section].has(id):
        # push_warning("Settings element is missing: ", id)
        return false
    return true


func is_valid_type(_values: Dictionary, _retrieved_value) -> bool:
    if typeof(_retrieved_value) != typeof(_values["default_value"]):
        push_warning("Invalid value type of '" + type_string(typeof(_retrieved_value)) + "' for element '" + id + "' expected value type of '" + type_string(typeof(_values["default_value"])) + "'")
        return false
    return true


func is_valid_value(_values: Dictionary, _retrieved_value) -> bool:
    match typeof(_values["default_value"]):
        TYPE_STRING, TYPE_BOOL:
            if not _values["valid_options"].has(_retrieved_value):
                push_warning("Invalid value '" + str(_retrieved_value) + "' for element '" + id + "' expected values: " + str(_values["valid_options"]))
                return false
        TYPE_INT, TYPE_FLOAT:
            if (_retrieved_value < _values["min_value"]
                or _retrieved_value > _values["max_value"]
            ):
                # Special check if max fps is set to 0 (unlimited)
                if id == "max_fps" and _retrieved_value == 0:
                    return true
                push_warning("Invalid value " + str(_retrieved_value) + " for element '" + id + "' expected values between " + str(_values["min_value"]) + " and " + str(_values["max_value"]))
                return false

    return true

#endregion
