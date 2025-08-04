extends Button
class_name KeybindButton

## The name of the action in the project settings input map
@export var action: String = ""
@export var primary: bool = true

var remap_mode: bool = false


func _ready():
    display_current_key()


func display_current_key():
    # InputMap.load_from_project_settings()
    # accept_event()
    var action_events = InputMap.action_get_events(action)
    var current_key = ""
    if primary and action_events.size() > 0:
        current_key = action_events[0].as_text()
    elif !primary and action_events.size() > 1:
        current_key = action_events[1].as_text()
    text = current_key


func remap_action_to(event):
    var action_events = InputMap.action_get_events(action)
    InputMap.action_erase_events(action)
    var events = []
    if primary:
        events.append(event)
        if action_events.size() > 1:
            events.append(action_events[1])
    else:
        events.append(action_events[0])
        events.append(event)
    for e in events:
        InputMap.action_add_event(action, e)
    KeybindManager.keymaps[action] = events
    KeybindManager.save_keymap_encoded()
    text = event.as_text()
    grab_focus()


func _on_toggled(toggled_on: bool) -> void:
    remap_mode = toggled_on
    if remap_mode:
        text = "..."
        release_focus()
    else:
        display_current_key()


func _input(event: InputEvent) -> void:
    if remap_mode:
        if event is InputEventKey or event is InputEventMouseButton:
            if event.keycode == KEY_ESCAPE:
                get_viewport().set_input_as_handled()
                button_pressed = false
                return
            remap_action_to(event)
            if event is InputEventKey or !event.button_index == MOUSE_BUTTON_LEFT:
                # left click would toggle back to button press without this
                button_pressed = false
