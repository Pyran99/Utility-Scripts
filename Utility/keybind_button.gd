@tool
extends Button
class_name KeybindButton

## The name of the action in the project settings input map
@export var action: String = "": set = _set_action
@export var primary: bool = true


func _set_action(value) -> void:
    action = value
    _display_current_key()


func _init() -> void:
    toggle_mode = true


func _ready() -> void:
    set_process_input(false)
    _display_current_key()


func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.keycode == KEY_ESCAPE:
            get_viewport().set_input_as_handled()
            button_pressed = false
            return
        _remap_action_to(event)
        return

    if event is InputEventMouseButton:
        if !event.button_index == MOUSE_BUTTON_LEFT:
            # left click would toggle back to button press without this
            button_pressed = false


func _display_current_key() -> void:
    var action_events: Array = []
    if Engine.is_editor_hint():
        var actions = ProjectSettings.get_setting("input/%s" % action)
        if actions != null:
            action_events = actions["events"]
    else:
        action_events = InputMap.action_get_events(action)

    var current_key = ""
    if !action_events.is_empty():
        if primary:
            current_key = action_events[0].as_text()
        elif !primary and action_events.size() > 1:
            current_key = action_events[1].as_text()
    text = current_key
    if current_key.is_empty():
        text = "None"


func _remap_action_to(event: InputEvent) -> void:
    button_pressed = false
    InputMap.action_erase_events(action)
    InputMap.action_add_event(action, event)
    text = event.as_text()
    grab_focus()
    if primary:
        KeybindManager.keymaps[action][0] = event
        print_debug(KeybindManager.keymaps[action])
    else:
        KeybindManager.keymaps[action][1] = event
        print_debug(KeybindManager.keymaps[action])

    # var action_events = InputMap.action_get_events(action)
    # var events = []
    # if primary:
    #     events.append(event)
    #     if action_events.size() > 1:
    #         events.append(action_events[1])
    # else:
    #     events.append(action_events[0])
    #     events.append(event)

    # for e in events:
    #     InputMap.action_add_event(action, e)
    # KeybindManager.keymaps[action] = events
    # text = event.as_text()
    # grab_focus()


func _on_toggled(toggled_on: bool) -> void:
    set_process_input(toggled_on)
    if toggled_on:
        text = "..."
        release_focus()
    else:
        _display_current_key()
        grab_focus()
