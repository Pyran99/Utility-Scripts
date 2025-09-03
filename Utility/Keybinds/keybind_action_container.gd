@tool
extends HBoxContainer
class_name KeybindActionContainer

## Player facing display name
@export_placeholder("Move Forward") var label_name: String: set = _set_label
## Input map name
@export_placeholder("move_forward") var action_name: String: set = _set_action

var menu: Control

@onready var label: Label = $Label
@onready var primary_btn: KeybindButton = %PrimaryBtn
@onready var secondary_btn: KeybindButton = %SecondaryBtn


func _set_label(value):
    label_name = value
    if !is_node_ready():
        await ready
    label.text = value


func _set_action(value):
    action_name = value
    if !is_inside_tree():
        return
    if !is_node_ready():
        await ready
    primary_btn.action = value
    primary_btn._display_current_key()
    secondary_btn.action = value
    secondary_btn._display_current_key()
    if Engine.is_editor_hint():
        update_configuration_warnings()


func _ready():
    call_deferred("_deferred_setup")


## Returns primary & secondary button
func get_buttons() -> Array[KeybindButton]:
    var btns: Array[KeybindButton] = []
    if primary_btn:
        btns.append(primary_btn)
    if secondary_btn:
        btns.append(secondary_btn)
    return btns


func _deferred_setup() -> void:
    var input_map = ProjectSettings.get_setting("input/%s" % action_name)
    assert(input_map != null, "%s: No input map for %s" % [name, action_name])
    primary_btn.menu = menu
    secondary_btn.menu = menu
    if KeybindManager.DEFAULT_KEY_MAP.get(action_name) != null:
        var value = KeybindManager.DEFAULT_KEY_MAP[action_name]
        if value == false:
            secondary_btn.queue_free()
            primary_btn.disabled = true
            primary_btn.focus_mode = Control.FOCUS_NONE
            var control = Control.new()
            control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            add_child(control)


func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    var actions = ProjectSettings.get_setting("input/%s" % action_name)
    if actions == null:
        warnings.append("No input map for %s" % action_name)
    return warnings
