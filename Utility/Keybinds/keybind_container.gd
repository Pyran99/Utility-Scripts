@tool
extends HBoxContainer
class_name KeybindContainer


## Player facing display name
@export_placeholder("Move Forward") var label_name: String: set = _set_label
## Input map name
@export_placeholder("move_forward") var action_name: String: set = _set_action

var menu: Control

@onready var label: Label = $Label
@onready var key_btn: Button = $KeyboardBtn
@onready var controller_btn: Button = $ControllerBtn


func _set_label(value):
    label_name = value
    if !is_node_ready():
        await ready
    label.text = value


func _set_action(value):
    action_name = value
    # if !is_inside_tree():
    #     return
    if !is_node_ready():
        await ready

    key_btn.action = action_name
    controller_btn.action = action_name
    key_btn.icon = ControllerIconTexture.new()
    controller_btn.icon = ControllerIconTexture.new()
    if action_name != null:
        key_btn.icon.path = action_name
        controller_btn.icon.path = action_name
        key_btn.icon.force_type = 1
        controller_btn.icon.force_type = 2
        if KeybindManager.DEFAULT_KEY_MAP.has(action_name):
            key_btn.disabled = !KeybindManager.DEFAULT_KEY_MAP[action_name]
    # key_btn.display_current_key() # for not addon
    if Engine.is_editor_hint():
        update_configuration_warnings()


func _ready():
    action_name = action_name
    call_deferred("_deferred_setup")


func _deferred_setup() -> void:
    var input_map = ProjectSettings.get_setting("input/%s" % action_name)
    assert(input_map != null, "%s: No input map for %s" % [name, action_name])
    # key_btn.menu = menu
    if KeybindManager.DEFAULT_KEY_MAP.get(action_name) == null:
        return
    var value = KeybindManager.DEFAULT_KEY_MAP[action_name]
    if value == false:
        key_btn.disabled = true
        key_btn.focus_mode = Control.FOCUS_NONE


func get_button() -> KeybindButton:
    return key_btn


func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    var actions = ProjectSettings.get_setting("input/%s" % action_name)
    if actions == null:
        warnings.append("No input map for %s" % action_name)
    return warnings
