extends Control

##-------------------------
## Requires KeybindManager
## Requires KeybindButton
## Requires KeybindContainer
## Requires SettingsManager
## For new actions, add action to InputMap, add to DEFAULT_KEY_MAP
##-------------------------

const KEYBIND_CONTAINER: PackedScene = preload("res://Utility/Keybinds/keybind_container.tscn")

@export var previous_menu: Control
@export var is_using_addon: bool = false

var original_binds: Dictionary = {}
var keybind_containers: Array
var active_btn: KeybindButton

@onready var scroll_container: ScrollContainer = %ControlsScrollContainer
@onready var rebind_tooltip: PanelContainer = %RebindTooltip
@onready var controls: VBoxContainer = %Controls
@onready var reset_confirm: Control = %ResetMenu
@onready var confirm_reset: Button = %ConfirmReset
@onready var cancel_reset: Button = %CancelReset
@onready var reset_btn: Button = %ResetBtn
@onready var back_btn: Button = %BackBtn


func _ready():
    set_process_unhandled_key_input(false)
    _connect_signals()
    reset_confirm.hide()

    for i in controls.get_children():
        if i is KeybindContainer:
            controls.remove_child(i)
            i.queue_free()

    _create_actions_list()
    _store_all_action_containers()
    Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _connect_signals() -> void:
    if !reset_btn.pressed.is_connected(_on_reset_btn_pressed):
        reset_btn.pressed.connect(_on_reset_btn_pressed)
    if !confirm_reset.pressed.is_connected(_confirm_reset_pressed):
        confirm_reset.pressed.connect(_confirm_reset_pressed)
    if !cancel_reset.pressed.is_connected(_cancel_reset_pressed):
        cancel_reset.pressed.connect(_cancel_reset_pressed)
    if !back_btn.pressed.is_connected(_on_back_btn_pressed):
        back_btn.pressed.connect(_on_back_btn_pressed)


# func _process(delta: float) -> void:
#     SettingsManager.keybind_manager._t += delta


##TODO this would be used to notify when a different input type is used. send global signal other scenes can use to change visuals
# func _input(event: InputEvent):
#     var joypad_deadzone: float = 0.2
# # 	var input_type = _last_input_type
# # 	var controller = _last_controller
#     match event.get_class():
#         "InputEventKey", "InputEventMouseButton":
#             # input_type = InputType.KEYBOARD_MOUSE
#             if event.is_pressed():
#                 SettingsManager.keybind_manager.input_scheme = KeybindManager.INPUT_SCHEMES.KEYBOARD
#                 print("keyboard")
#         "InputEventMouseMotion":
#             if SettingsManager.keybind_manager.allow_mouse_remap and SettingsManager.keybind_manager._test_mouse_velocity(event.relative):
#                 SettingsManager.keybind_manager.input_scheme = KeybindManager.INPUT_SCHEMES.KEYBOARD
#                 print("mouse motion")
#         "InputEventJoypadButton":
#             if event.is_pressed():
#                 SettingsManager.keybind_manager.input_scheme = KeybindManager.INPUT_SCHEMES.CONTROLLER
#                 # controller = event.device
#                 print("controller button")
#         "InputEventJoypadMotion":
#             if abs(event.axis_value) > joypad_deadzone:
#                 SettingsManager.keybind_manager.input_scheme = KeybindManager.INPUT_SCHEMES.CONTROLLER
#                 # controller = event.device
#                 print("controller motion")
# # 	if input_type != _last_input_type or controller != _last_controller:
# # 		_set_last_input_type(input_type, controller)


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _close_menu()


func set_previous_menu(menu: Control) -> void:
    previous_menu = menu


func _close_menu() -> void:
    if original_binds.hash() != SettingsManager.keybind_manager.input_map.hash():
        SettingsManager.keybind_manager.save_input_map()
    if previous_menu != null:
        previous_menu.show()

    original_binds.clear()
    previous_menu = null
    reset_confirm.hide()
    hide()


func _store_all_action_containers() -> void:
    var containers = controls.get_children()
    for i in containers:
        if i is KeybindContainer:
            keybind_containers.append(i)
            for j in i.get_buttons():
                _connect_btn_signals(j)

## Create a keybind container for every action in DEFAULT_KEY_MAP
func _create_actions_list() -> void:
    for input_action: String in KeybindManager.DEFAULT_KEY_MAP.keys():
        if !InputMap.has_action(input_action):
            push_warning("%s: Action '%s' not found in InputMap" % [name, input_action])
            continue
        var container: KeybindContainer = KEYBIND_CONTAINER.instantiate()
        container.menu = self
        container.name = "InputContainer_%s" % input_action
        container.action_name = input_action
        controls.add_child(container)
        # var separator = HSeparator.new()
        # controls.add_child(separator)


func _unpress_active_btn() -> void:
    if active_btn != null:
        active_btn.emit_signal("toggled", false)
        active_btn = null


func _hide_reset_window() -> void:
    _unpress_active_btn()
    reset_confirm.hide()
    reset_btn.call_deferred("grab_focus")


func _connect_btn_signals(btn: KeybindButton) -> void:
    btn.rebind_mode.connect(_btn_rebind_mode)


func _on_reset_btn_pressed() -> void:
    reset_confirm.show()
    cancel_reset.call_deferred("grab_focus")
    _unpress_active_btn()


func _on_back_btn_pressed() -> void:
    _unpress_active_btn()
    _close_menu()


func _confirm_reset_pressed() -> void:
    SettingsManager.keybind_manager.reset_input_map()
    if is_using_addon:
        ControllerIcons.refresh() # for addon
        pass
    for container in keybind_containers:
        for btn in container.get_buttons():
            btn.set_current_event()
    _hide_reset_window()


func _cancel_reset_pressed() -> void:
    _hide_reset_window()


func _on_visibility_changed() -> void:
    set_process_unhandled_key_input(visible)
    if !is_node_ready():
        await ready
    if visible:
        scroll_container.set_deferred("scroll_vertical", 0)
        original_binds = SettingsManager.keybind_manager.input_map.duplicate(true)
        if keybind_containers.size() > 0:
            for i in keybind_containers.size():
                var first_btn: KeybindButton = keybind_containers[i].get_buttons()[0]
                if !first_btn.disabled:
                    first_btn.grab_focus()
                    break


func _btn_rebind_mode(value: bool) -> void:
    if value:
        rebind_tooltip.show()
    else:
        rebind_tooltip.hide()


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
    if connected:
        print("Joystick connected: %s" % Input.get_joy_name(device_id))
