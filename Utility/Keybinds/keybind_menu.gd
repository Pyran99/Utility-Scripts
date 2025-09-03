extends Control

#-------------------------#
# Requires KeybindManager
# Requires KeybindActionContainer
# Requires SettingsManager
# Containers are created from KeybindManager DEFAULT_KEY_MAP
#-------------------------#


const KEYBIND_CONTAINER: PackedScene = preload("res://Utility/Keybinds/keybind_action_container.tscn")

var previous_menu
var keybind_containers: Array[KeybindActionContainer]
var original_binds: Dictionary = {}
var pressed_btn: KeybindButton

@onready var controls: VBoxContainer = %Controls
@onready var reset_confirm_container: ColorRect = %ResetConfirm
@onready var reset_btn: Button = %ResetBtn
@onready var cancel_reset: Button = %CancelReset


func _ready():
    for i in controls.get_children():
        if i is KeybindActionContainer:
            controls.remove_child(i)
            i.queue_free()

    _create_actions_list()
    store_all_action_containers()
    reset_confirm_container.hide()
    hide()


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _close_menu()


func store_all_action_containers() -> void:
    var containers = controls.get_children()
    for i in containers:
        if i is KeybindActionContainer:
            keybind_containers.append(i)

    # var all_containers = controls.find_children("*", "KeybindActionContainer", false)
    # print(all_containers) # not getting children
    # for i in all_containers:
    #     keybind_containers.append(i)


func _close_menu() -> void:
    # if original_binds.hash() != SettingsManager.settings[Strings.KEYBINDS].hash():
    if original_binds.hash() != KeybindManager.input_map.hash():
        KeybindManager.save_input_map()
    original_binds.clear()
    hide()
    if previous_menu:
        previous_menu.show()


func _create_actions_list() -> void:
    for input_action: String in KeybindManager.DEFAULT_KEY_MAP.keys():
        var new_text: String = input_action.capitalize()
        var container: KeybindActionContainer = KEYBIND_CONTAINER.instantiate()
        container.menu = self
        controls.add_child(container)
        container.label_name = new_text
        container.action_name = input_action
        var separator = HSeparator.new()
        controls.add_child(separator)


func _unpress_active_btn() -> void:
    if pressed_btn != null:
        pressed_btn.button_pressed = false
        pressed_btn.emit_signal("toggled", false)
        pressed_btn = null


func _on_reset_btn_pressed() -> void:
    _unpress_active_btn()
    reset_confirm_container.show()
    cancel_reset.call_deferred("grab_focus")


func _on_back_btn_pressed() -> void:
    _close_menu()


func _on_confirm_reset_pressed() -> void:
    KeybindManager.reset_input_map()
    for container in keybind_containers:
        for btn in container.get_buttons():
            btn._display_current_key()
    reset_confirm_container.hide()
    reset_btn.call_deferred("grab_focus")


func _on_cancel_reset_pressed() -> void:
    reset_confirm_container.hide()
    reset_btn.call_deferred("grab_focus")


func _on_visibility_changed() -> void:
    if visible:
        original_binds = KeybindManager.input_map.duplicate(true)
        if keybind_containers.size() > 0:
            keybind_containers[0].get_buttons()[0].call_deferred("grab_focus")
        set_process_unhandled_key_input(true)
    else:
        set_process_unhandled_key_input(false)
        _unpress_active_btn()
