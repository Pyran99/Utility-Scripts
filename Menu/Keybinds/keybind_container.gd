@tool
extends HBoxContainer
class_name KeybindContainer


## Player facing display name
@export_placeholder("Move Forward") var label_name: String: set = _set_label
## Input map name
@export_placeholder("move_forward") var action_name: String: set = _set_action

@export var label: Label
@export var key_btn: KeybindButton
# @export var gamepad_texture: TextureRect
@export var controller_btn: KeybindButton

var menu: Control

func _set_label(value):
    label_name = value
    if !is_node_ready():
        await ready
    label.text = tr(value)


func _set_action(value):
    action_name = value
    label_name = action_name.to_upper()
    # if !is_inside_tree():
    #     return
    if !is_node_ready():
        await ready
    if menu == null: return

    key_btn.action = action_name
    controller_btn.action = action_name
    if menu.is_using_addon:
        key_btn.icon = ControllerIconTexture.new()
        controller_btn.icon = ControllerIconTexture.new()
        # gamepad_texture.texture = ControllerIconTexture.new()
        if action_name != null:
            key_btn.icon.path = action_name
            key_btn.icon.force_type = 1
            # gamepad_texture.texture.path = action_name
            # gamepad_texture.texture.force_type = 2
            controller_btn.icon.path = action_name
            controller_btn.icon.force_type = 2
    else:
        key_btn.icon = null
        controller_btn.icon = null
        key_btn.display_current_key() # for not addon
        controller_btn.display_current_key()

    if action_name != null:
        if KeybindManager.DEFAULT_KEY_MAP.has(action_name):
            key_btn.disabled = !KeybindManager.DEFAULT_KEY_MAP[action_name]
    if Engine.is_editor_hint():
        update_configuration_warnings()


func _ready():
    if Engine.is_editor_hint():
        action_name = action_name
    _setup_btns()


func _setup_btns() -> void:
    var input_map = ProjectSettings.get_setting("input/%s" % action_name)
    assert(input_map != null, "%s: No input map for %s" % [name, action_name])
    for i in get_buttons():
        i.menu = menu
        if KeybindManager.DEFAULT_KEY_MAP.get(action_name) == null:
            break
        var value: bool = KeybindManager.DEFAULT_KEY_MAP[action_name]
        if value == false:
            i.disabled = true
            i.focus_mode = Control.FOCUS_NONE

    # key_btn.menu = menu
    # controller_btn.menu = menu
    # if KeybindManager.DEFAULT_KEY_MAP.get(action_name) == null:
    #     return
    # var value: bool = KeybindManager.DEFAULT_KEY_MAP[action_name]
    # if value == false:
    #     key_btn.disabled = true
    #     key_btn.focus_mode = Control.FOCUS_NONE
    #     controller_btn.disabled = true
    #     controller_btn.focus_mode = Control.FOCUS_NONE


func get_button() -> KeybindButton:
    return key_btn


func get_buttons() -> Array[KeybindButton]:
    return [key_btn, controller_btn]


func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    var actions = ProjectSettings.get_setting("input/%s" % action_name)
    if actions == null:
        warnings.append("No input map for %s" % action_name)
    return warnings


func _notification(what: int) -> void:
    if what == NOTIFICATION_TRANSLATION_CHANGED:
        if label == null: return
        label.text = tr(label_name)
