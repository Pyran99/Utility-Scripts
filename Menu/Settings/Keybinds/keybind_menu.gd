extends Control
class_name KeybindMenu


signal release_pressed_button

const CONTAINER_SCENE: PackedScene = preload("uid://bmk2iqp6ahqnt")
const KEYBOARD_SCENE: PackedScene = preload("uid://dvpm1r2s3uswy")
const GAMEPAD_SCENE: PackedScene = preload("uid://1avrn18owobf")

const APPLIED_NOTIF_PATH: String = "uid://mrk10mkq1bjo"
const RESET_CONFIRM_PATH: String = "uid://bxmtikgmwm817"
const REBIND_ACTIONS_PATH: String = "uid://cs7m4oc78dk0w"
const UNSAVED_CHANGES_PATH: String = "uid://dt57pg6odyhd8"

@export var is_tab_containers: bool = true

var keybind_cache: Dictionary = {}
var to_remap_cache: Dictionary = {}
var applied_notif_window: Control = null
var reset_confirm_window: Control = null
var rebind_action_window: Control = null
var unsaved_changes_window: Control = null
var last_focused: Control = null
var pressed_button: Control = null

@onready var keybind_panel: Panel = %KeybindPanelTabs
@onready var containers: VBoxContainer = %Containers
@onready var back_btn: Button = %BackBtn
@onready var apply_btn: Button = %ApplyBtn
@onready var discard_btn: Button = %DiscardBtn
@onready var reset_btn: Button = %ResetBtn
@onready var keyboard_container: VBoxContainer = %KeyboardContainer
@onready var gamepad_container: VBoxContainer = %GamepadContainer
@onready var tab_container: TabContainer = %TabContainer


func _ready() -> void:
    _connect_signals()
    KeybindManager.keybind_menu = self
    keybind_cache = KeybindManager.keybinds.duplicate()
    tab_container.current_tab = 0
    _add_containers_for_rebind_inputs()
    _set_apply_btn_state()


func _exit_tree() -> void:
    if KeybindManager.is_file_invalid:
        KeybindManager.save_keybind_data()


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_cancel"):
        _on_back_pressed()


func apply_action_event(_action: String, type: KeybindManager.InputType, remapped_actions: Dictionary) -> void:
    var event: InputEvent = remapped_actions[_action].get(type)
    KeybindManager.add_event(_action, event, type)


func _connect_signals() -> void:
    back_btn.pressed.connect(_on_back_pressed)
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
        for action in KeybindManager.DEFAULT_GAMEPAD_KEYBINDS:
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
        reset_confirm_window.tree_exiting.connect(_on_popup_window_closed)
        keybind_panel.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
        last_focused = reset_btn
        add_child(reset_confirm_window)


func _create_rebinds_action_window() -> void:
    if rebind_action_window == null:
        rebind_action_window = load(REBIND_ACTIONS_PATH).instantiate()
        add_child(rebind_action_window)


func _create_unsaved_changed_window() -> void:
    if unsaved_changes_window == null:
        keybind_panel.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
        unsaved_changes_window = load(UNSAVED_CHANGES_PATH).instantiate()
        unsaved_changes_window.tree_exiting.connect(_on_popup_window_closed)
        unsaved_changes_window.menu = self
        add_child(unsaved_changes_window)


func _set_apply_btn_state() -> void:
    apply_btn.disabled = to_remap_cache.size() == 0
    apply_btn.focus_mode = FOCUS_NONE if apply_btn.disabled else FOCUS_ALL


func _on_keybinds_reset_to_default() -> void:
    to_remap_cache.clear()
    _set_apply_btn_state()
    keybind_cache = KeybindManager.keybinds.duplicate()
    _create_applied_notif_window("Keybinds Reset")

## button signal
func _on_action_rebound(action: String, event: InputEvent, type: KeybindManager.InputType) -> void:
    if !to_remap_cache.has(action):
        to_remap_cache[action] = {}
    to_remap_cache[action][type] = event
    _set_apply_btn_state()


func _on_apply_pressed() -> void:
    for action in to_remap_cache: # move_up
        for type: KeybindManager.InputType in to_remap_cache[action]:
            apply_action_event(action, type, to_remap_cache)
    to_remap_cache.clear()
    KeybindManager.save_keybind_data()
    _set_apply_btn_state()
    keybind_cache = KeybindManager.keybinds.duplicate()
    _create_applied_notif_window("Changes Saved")
    release_pressed_button.emit()
    keybind_panel.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
    discard_btn.grab_focus()


func _on_discard_pressed() -> void:
    last_focused = discard_btn
    KeybindManager.keybinds_reset.emit()
    keybind_cache = KeybindManager.keybinds.duplicate()
    release_pressed_button.emit()
    if to_remap_cache.size() > 0:
        _create_applied_notif_window("Changes Discarded")
    to_remap_cache.clear()
    _set_apply_btn_state()


func _on_reset_pressed() -> void:
    _create_reset_confirm_window()
    release_pressed_button.emit()


func _on_rebind_mode_changed(is_rebind: bool, node: Control) -> void:
    if is_rebind:
        last_focused = node
        pressed_button = node
        _create_rebinds_action_window.call_deferred()
        keybind_panel.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
    else:
        pressed_button = null
        _on_popup_window_closed()
        if is_instance_valid(rebind_action_window):
            rebind_action_window.queue_free()
            rebind_action_window = null


func _on_popup_window_closed() -> void:
    keybind_panel.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
    if last_focused and !is_queued_for_deletion():
        last_focused.grab_focus()


func _on_back_pressed() -> void:
    if to_remap_cache.size() > 0:
        _create_unsaved_changed_window()
        return
    queue_free()
