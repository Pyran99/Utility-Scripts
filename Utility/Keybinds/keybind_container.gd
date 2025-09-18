@tool
extends HBoxContainer
class_name KeybindContainer

##-------------------------
## icon.path & icon.force_type are used by addon
## gamepad_texture would be used to show controller icon instead of
##  button name
##-------------------------


## Player facing display name. Autoset from action name
@export_placeholder("Move Forward") var label_name: String: set = _set_label
## Input map name
@export_placeholder("move_forward") var action_name: String: set = _set_action

@onready var label: Label = $InputName
@onready var key_btn: KeybindButton = $KeyboardBtn
@onready var controller_btn: KeybindButton = $ControllerBtn
# @onready var controller_texture: TextureRect = $GamepadIcon

var menu: Control = null

func _set_label(value):
    label_name = value
    if !is_node_ready():
        await ready
    label.text = value


func _set_action(value):
    action_name = value
    label_name = action_name.capitalize()
    if !is_node_ready():
        await ready

    key_btn.action = action_name
    controller_btn.action = action_name
    key_btn.icon = ControllerIconTexture.new()
    controller_btn.icon = ControllerIconTexture.new()
    # gamepad_texture.texture = ControllerIconTexture.new()
    if action_name != null:
        if KeybindManager.DEFAULT_KEY_MAP.has(action_name):
            key_btn.disabled = !KeybindManager.DEFAULT_KEY_MAP[action_name]
        _set_addon_icon_details()

    if Engine.is_editor_hint():
        update_configuration_warnings()


func _ready():
    if Engine.is_editor_hint():
        action_name = action_name
    _setup_btns()


func _setup_btns() -> void:
    var input_map = ProjectSettings.get_setting("input/%s" % action_name)
    assert(input_map != null, "%s: No input map for %s" % [name, action_name])
    var value: bool = KeybindManager.DEFAULT_KEY_MAP[action_name]
    for i in get_buttons():
        i.menu = menu
    key_btn.disabled = !value
    if key_btn.disabled:
        key_btn.focus_mode = Control.FOCUS_NONE
    else:
        key_btn.focus_mode = Control.FOCUS_ALL
    controller_btn.disabled = true
    controller_btn.focus_mode = Control.FOCUS_NONE


func _set_addon_icon_details() -> void:
    if menu == null: return
    if !menu.is_using_addon: return
    key_btn.icon.path = action_name
    key_btn.icon.force_type = 1
    controller_btn.icon.path = action_name
    controller_btn.icon.force_type = 2
    # gamepad_texture.texture.path = action_name
    # gamepad_texture.texture.force_type = 2


func get_buttons() -> Array[KeybindButton]:
    return [key_btn, controller_btn]


func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    var actions = ProjectSettings.get_setting("input/%s" % action_name)
    if actions == null:
        warnings.append("No input map for %s" % action_name)
    return warnings
