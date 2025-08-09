@tool
extends HBoxContainer
class_name KeybindActionContainer

## Player facing display name
@export_placeholder("Move Forward") var label_name: String: set = _set_label
## Input map name
@export_placeholder("move_forward") var action_name: String: set = _set_action


@onready var label: Label = $Label
@onready var primary_btn: Button = %PrimaryBtn
@onready var secondary_btn: Button = %SecondaryBtn


func _set_label(value):
    label_name = value
    if !is_node_ready():
        await ready
    label.text = value


func _set_action(value):
    action_name = value
    if !is_node_ready():
        await ready
    primary_btn.action = value
    secondary_btn.action = value


func _ready():
    var input_map = ProjectSettings.get_setting("input/%s" % action_name)
    assert(input_map != null, "%s: No input map for %s" % [name, action_name])


func get_buttons() -> Array[KeybindButton]:
    return [primary_btn, secondary_btn]
