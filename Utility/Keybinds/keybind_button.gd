@tool
extends Button
class_name KeybindButton

## The name of the action in the project settings input map
@export var action: String = "": set = _set_action
@export var primary: bool = true


func _set_action(value) -> void:
    action = value
    if Engine.is_editor_hint():
        _display_current_key()


func _init() -> void:
    toggle_mode = true


func _ready() -> void:
    set_process_input(false)


func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        get_viewport().set_input_as_handled()
        var keycode := DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
        if keycode == KEY_ESCAPE:
            button_pressed = false
            return
        if keycode == KEY_BACKSPACE:
            event = _reset_key_to_default()
        _remap_action_to(event)
    elif event is InputEventMouseButton:
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
        var action_number: int = 0
        if !primary and action_events.size() > 1:
            action_number = 1
        if action_events[action_number] is InputEventJoypadButton:
            current_key = action_events[action_number].as_text()
        else:
            var ds_keycode := DisplayServer.keyboard_get_keycode_from_physical(action_events[action_number].physical_keycode)
            var keycode = OS.get_keycode_string(ds_keycode)
            current_key = keycode
    
    if current_key.is_empty() or (!primary and action_events.size() == 1):
        current_key = "None"
    
    text = current_key


func _remap_action_to(event: InputEvent) -> void:
    button_pressed = false
    if !KeybindManager.can_use_key(action):
        return
    var new_event = InputEventKey.new()
    if event != null:
        new_event.physical_keycode = event.physical_keycode

    var count: int = 0 if primary else 1
    # KeybindManager.input_map[action][count] = new_event #TODO testing
    SavingManager.settings_dict[Strings.KEYBINDS][action][count] = new_event
    var keycodes := KeybindManager._get_keycodes_from_input_map()
    if keycodes[action].size() == 1:
        keycodes[action].append(null)
    if new_event != null:
        keycodes[action][count] = new_event.physical_keycode

    InputMap.action_erase_events(action)
    # for i in KeybindManager.input_map[action]: #TODO testing
    for i in SavingManager.settings_dict[Strings.KEYBINDS][action]:
        if i == null:
            continue
        InputMap.action_add_event(action, i)

    _display_current_key()


func _reset_key_to_default() -> InputEvent:
    var key = ProjectSettings.get_setting("input/%s" % action)
    if primary:
        return key["events"][0]
    else:
        if key["events"].size() > 1:
            return key["events"][1]
        return null


func _on_toggled(toggled_on: bool) -> void:
    set_process_input(toggled_on)
    if toggled_on:
        text = "..."
        release_focus()
    else:
        _display_current_key()
        grab_focus()
