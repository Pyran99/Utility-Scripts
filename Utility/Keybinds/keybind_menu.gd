extends Control

#-------------------------#
# Requires KeybindManager
# Requires KeybindActionContainer
# Containers are created from KeybindManager DEFAULT_KEY_MAP
#-------------------------#


const KEYBIND_CONTAINER: PackedScene = preload("res://Utility/Keybinds/keybind_action_container.tscn")

var previous_menu
var keybind_containers: Array[KeybindActionContainer]

@onready var controls: VBoxContainer = %Controls
@onready var reset_confirm_container: PanelContainer = %ResetConfirm
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
    var test = controls.get_children()
    for i in test:
        if i is KeybindActionContainer:
            keybind_containers.append(i)

    # var all_containers = controls.find_children("*", "KeybindActionContainer", false)
    # print(all_containers) # not getting children
    # for i in all_containers:
    #     keybind_containers.append(i)


func _close_menu() -> void:
    KeybindManager.save_input_map()
    hide()
    if previous_menu:
        previous_menu.show()


func _create_actions_list() -> void:
    # for input_action: String in KeybindManager.input_map.keys():
    for input_action: String in SavingManager.settings_dict[Strings.KEYBINDS].keys():
        var new_text: String = input_action.capitalize()
        var container: KeybindActionContainer = KEYBIND_CONTAINER.instantiate()
        controls.add_child(container)
        container.label_name = new_text
        container.action_name = input_action
        var separator = HSeparator.new()
        controls.add_child(separator)


func _on_reset_btn_pressed() -> void:
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
        keybind_containers[0].get_buttons()[0].call_deferred("grab_focus")
        set_process_unhandled_key_input(true)
    else:
        set_process_unhandled_key_input(false)
