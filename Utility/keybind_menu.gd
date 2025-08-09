extends Control

#-------------------------
# Requires KeybindManager 
# Requires Utils          
# Requires KeybindButton  
# For new actions, dupe an hboxcontainer, set action, set default values to KeybindManager
#-------------------------


var previous_menu
var keybind_containers: Array[KeybindActionContainer]

@onready var controls: VBoxContainer = %Controls
@onready var reset_confirm_container: PanelContainer = %ResetConfirm
# @onready var first_btn: Button = %PrimaryBtn
@onready var reset_btn: Button = %ResetBtn
@onready var cancel_reset: Button = %CancelReset


func _ready():
    store_all_action_containers()
    reset_confirm_container.hide()
    hide()


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _close_menu()


func store_all_action_containers() -> void:
    var all_containers = controls.find_children("*", "KeybindActionContainer")
    for i in all_containers:
        keybind_containers.append(i)


func _close_menu() -> void:
    KeybindManager.save_keymap_encoded()
    hide()
    if previous_menu:
        previous_menu.show()


func _on_reset_btn_pressed() -> void:
    reset_confirm_container.show()
    cancel_reset.call_deferred("grab_focus")


func _on_back_btn_pressed() -> void:
    _close_menu()


func _on_confirm_reset_pressed() -> void:
    KeybindManager.reset_keymap()
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
        await get_tree().process_frame
        keybind_containers[0].get_buttons()[0].call_deferred("grab_focus")
        set_process_unhandled_key_input(true)
    else:
        set_process_unhandled_key_input(false)
