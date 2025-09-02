@tool
extends Button
class_name KeybindButton

## The name of the action in the project settings input map
@export var action: String = "": set = _set_action
@export var primary: bool = true

var menu: Control


func _set_action(value) -> void:
    action = value
    if Engine.is_editor_hint():
        _display_current_key()


func _init() -> void:
    toggle_mode = true


func _ready() -> void:
    set_process_input(false)
    mouse_entered.connect(_on_mouse_entered)


func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        get_viewport().set_input_as_handled()
        var keycode := DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
        if keycode == KEY_ESCAPE: # cancel rebind
            button_pressed = false
            return
        if keycode == KEY_BACKSPACE: # reset key to default
            event = _reset_key_to_default()
        if keycode == KEY_BRACERIGHT: # remap to nothing
            event = null
        _remap_action_to(event)
    elif event is InputEventMouseButton:
        if !event.button_index == MOUSE_BUTTON_LEFT:
            # left click would toggle back to button press without this
            button_pressed = false

## display the key string for 'action' from KBM.input_map. No event shows 'none'
func _display_current_key() -> void:
    var action_events: Array = []
    if Engine.is_editor_hint():
        var actions = ProjectSettings.get_setting("input/%s" % action)
        if actions != null:
            action_events = actions["events"]
    else:
        action_events = KeybindManager.input_map[action]

    assert(action_events != null, "No input map for %s" % action)
    var current_key := ""
    var action_number: int = 0 if primary else 1
    if action_events[action_number] is InputEventJoypadButton:
        current_key = action_events[action_number].as_text()
    else:
        if action_events[action_number] != null:
            var ds_keycode := DisplayServer.keyboard_get_keycode_from_physical(action_events[action_number].physical_keycode)
            var keycode = OS.get_keycode_string(ds_keycode)
            current_key = keycode
            
    if current_key.is_empty():
        current_key = "None"
    text = current_key


func _remap_action_to(event: InputEvent) -> void:
    button_pressed = false
    if !KeybindManager.can_use_key(action):
        return
    var count := 0 if primary else 1
    KeybindManager.input_map[action][count] = event
    _set_events_to_action()
    _display_current_key()


func _set_events_to_action() -> void:
    InputMap.action_erase_events(action)
    for i in KeybindManager.input_map[action].size():
        if KeybindManager.input_map[action][i] == null:
            continue
        InputMap.action_add_event(action, KeybindManager.input_map[action][i])

# reset key to project settings for 'action'
func _reset_key_to_default() -> InputEvent:
    var key = ProjectSettings.get_setting("input/%s" % action)
    if primary:
        return key["events"][0]
    else:
        if key["events"].size() > 1:
            return key["events"][1]
        return null

#NYI
func _is_event_part_of_action(event: InputEvent) -> bool:
    for _action in KeybindManager.input_map:
        for _event in KeybindManager.input_map[_action]:
            if InputMap.action_has_event(_action, event):
                if _action == action:
                    print("event is in action")
                    return false
                print("event is part of action")
                return true
    return false


func _on_toggled(toggled_on: bool) -> void:
    set_process_input(toggled_on)
    if toggled_on:
        menu.pressed_btn = self
        text = "..."
        release_focus()
    else:
        _display_current_key()
        call_deferred("grab_focus")


func _on_mouse_entered() -> void:
    if focus_mode == Control.FOCUS_NONE:
        return
    if !button_pressed:
        call_deferred("grab_focus")
