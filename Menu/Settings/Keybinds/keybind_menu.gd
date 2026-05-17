extends Control
class_name KeybindMenu


enum InputType {
    KEYBOARD,
    GAMEPAD,
    MOUSE,
}

const CONTAINER_SCENE: PackedScene = preload("uid://bmk2iqp6ahqnt")
const KEYBOARD_SCENE: PackedScene = preload("uid://dvpm1r2s3uswy")
const GAMEPAD_SCENE: PackedScene = preload("uid://1avrn18owobf")

const APPLIED_NOTIF_PATH: String = "uid://mrk10mkq1bjo"
const RESET_CONFIRM_PATH: String = "uid://bxmtikgmwm817"
const REBIND_ACTIONS_PATH: String = "uid://cs7m4oc78dk0w"
const TYPE_KEYBOARD_NAME: String = "keyboard"
const TYPE_GAMEPAD_NAME: String = "gamepad"

@export var is_tab_containers: bool = true

var keybind_cache: Dictionary = {}
var to_remap_cache: Dictionary = {}
var applied_notif_window: Control = null
var reset_confirm_window: Control = null
var rebind_action_window: Control = null

@onready var keybind_panel: Panel = %KeybindPanel
@onready var containers: VBoxContainer = %Containers
@onready var apply_btn: Button = %ApplyBtn
@onready var discard_btn: Button = %DiscardBtn
@onready var reset_btn: Button = %ResetBtn
@onready var keyboard_container: VBoxContainer = %KeyboardContainer
@onready var gamepad_container: VBoxContainer = %GamepadContainer


func _ready() -> void:
    _connect_signals()
    KeybindManager.keybind_menu = self
    keybind_cache = KeybindManager.keybinds.duplicate()
    _add_containers_for_rebind_inputs()
    _set_apply_btn_state()


func _exit_tree() -> void:
    if KeybindManager.is_file_invalid:
        KeybindManager.save_keybind_data()


func update_action_events(_action: String, type: String, remapped_actions: Dictionary) -> void:
    var event: InputEvent = remapped_actions[_action].get(type)
    if event == null:
        for _event in InputMap.action_get_events(_action):
            match type:
                KeybindMenu.TYPE_KEYBOARD_NAME:
                    if _event is InputEventKey:
                        InputMap.action_erase_event(_action, _event)
                        KeybindManager.replace_keybind_event(_action, null, type)
                KeybindMenu.TYPE_GAMEPAD_NAME:
                    if _event is InputEventJoypadButton:
                        InputMap.action_erase_event(_action, _event)
                        KeybindManager.replace_keybind_event(_action, null, type)
        return
    match event.get_class():
        "InputEventKey":
            KeybindManager.add_event(_action, event)
        "InputEventJoypadButton":
            KeybindManager.add_event(_action, event)
        _:
            printerr("unsupported event type '%s' : '%s'" % [type, event.get_class()])


func _connect_signals() -> void:
    apply_btn.pressed.connect(_on_apply_pressed)
    discard_btn.pressed.connect(_on_discard_pressed)
    reset_btn.pressed.connect(_on_reset_pressed)


func _add_containers_for_rebind_inputs() -> void:
    var container_children: Array = containers.get_children()
    container_children.append_array(keyboard_container.get_children())
    container_children.append_array(gamepad_container.get_children())
    for i in container_children:
        i.queue_free()
    if is_tab_containers:
        for action in KeybindManager.DEFAULT_KEYBINDS:
            _create_keybind_container_tab(action)
        for action in KeybindManager.CONTROLLER_BUTTON_REMAP:
            if action.begins_with("move_"):
                if action != "move_up":
                    continue
            _create_gamepad_keybind_container_tab(action)
    else:
        for action in KeybindManager.DEFAULT_KEYBINDS:
            _create_keybind_container(action)


func _create_keybind_container(_action: String) -> void:
    var scene: HBoxContainer = CONTAINER_SCENE.instantiate()
    scene.name = _action
    scene.action_name = _action
    scene.menu = self
    scene.action_rebound.connect(_on_action_rebound)
    containers.add_child(scene)


func _create_keybind_container_tab(_action: String) -> void:
    var scene: HBoxContainer = KEYBOARD_SCENE.instantiate()
    scene.name = _action
    scene.action_name = _action
    scene.menu = self
    scene.action_rebound.connect(_on_action_rebound)
    keyboard_container.add_child(scene)


func _create_gamepad_keybind_container_tab(_action: String) -> void:
    var scene: HBoxContainer = GAMEPAD_SCENE.instantiate()
    scene.name = _action
    scene.action_name = _action
    scene.menu = self
    scene.action_rebound.connect(_on_action_rebound)
    gamepad_container.add_child(scene)


func _create_applied_notif_window(notif_text: String) -> void:
    if applied_notif_window == null:
        applied_notif_window = load(APPLIED_NOTIF_PATH).instantiate()
        applied_notif_window.set_text.call_deferred(notif_text)
        add_child(applied_notif_window)
    else:
        applied_notif_window.set_text.call_deferred(notif_text)
        applied_notif_window.reset_tween()


func _create_reset_confirm_window() -> void:
    if reset_confirm_window == null:
        reset_confirm_window = load(RESET_CONFIRM_PATH).instantiate()
        reset_confirm_window.keybinds_reset.connect(_on_keybinds_reset_to_default)
        reset_confirm_window.tree_exiting.connect(func(): keybind_panel.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED)
        keybind_panel.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
        add_child(reset_confirm_window)


func _create_rebinds_action_window() -> void:
    if rebind_action_window == null:
        rebind_action_window = load(REBIND_ACTIONS_PATH).instantiate()
        add_child(rebind_action_window)


func _on_keybinds_reset_to_default() -> void:
    to_remap_cache.clear()
    _set_apply_btn_state()
    keybind_cache = KeybindManager.keybinds.duplicate()
    _create_applied_notif_window("Keybinds Reset")


func _set_apply_btn_state() -> void:
    apply_btn.disabled = to_remap_cache.size() == 0
    apply_btn.focus_mode = FOCUS_NONE if apply_btn.disabled else FOCUS_ALL

# from button
func _on_action_rebound(action: String, event: InputEvent, type: KeybindMenu.InputType) -> void:
    if !to_remap_cache.has(action):
        to_remap_cache[action] = {}
    match type:
        KeybindMenu.InputType.KEYBOARD:
            to_remap_cache[action][KeybindMenu.TYPE_KEYBOARD_NAME] = event
        KeybindMenu.InputType.GAMEPAD:
            to_remap_cache[action][KeybindMenu.TYPE_GAMEPAD_NAME] = event
    _set_apply_btn_state()


func _on_apply_pressed() -> void:
    print(to_remap_cache)
    for action in to_remap_cache: # move_up
        for type in to_remap_cache[action]: # keyboard, gamepad
            update_action_events(action, type, to_remap_cache)
    to_remap_cache.clear()
    KeybindManager.save_keybind_data()
    _set_apply_btn_state()
    keybind_cache = KeybindManager.keybinds.duplicate()
    _create_applied_notif_window("Changes Saved")


func _on_discard_pressed() -> void:
    KeybindManager.keybinds_reset.emit()
    keybind_cache = KeybindManager.keybinds.duplicate()
    if to_remap_cache.size() > 0:
        _create_applied_notif_window("Changes Discarded")
    to_remap_cache.clear()
    _set_apply_btn_state()


func _on_reset_pressed() -> void:
    _create_reset_confirm_window()


func _on_rebind_mode_changed(is_rebind: bool) -> void:
    if !is_rebind:
        if is_instance_valid(rebind_action_window):
            rebind_action_window.queue_free()
            rebind_action_window = null
    else:
        _create_rebinds_action_window.call_deferred()


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("move_up"):
        print("move up")


func test_move() -> void:
    Input.get_axis("move_left", "move_right")
    pass
