@tool
extends Button
class_name KeybindButton

signal rebind_mode(value: bool)
signal keybind_changed(action: String, event: InputEvent)

## The name of the action in the project settings input map
@export var action: String = "": set = _set_action
@export var type: KeybindManager.INPUT_SCHEMES = KeybindManager.INPUT_SCHEMES.KEYBOARD

var menu: Control = null
var is_rebind_mode: bool = false
var current_event: InputEvent
var shader: ShaderMaterial


func _set_action(value: String) -> void:
    action = value
    set_current_event()


func _ready():
    shader = material
    if shader != null:
        shader.set_shader_parameter("speed", 0)
    set_process_input(false)
    _connect_signals()


func _connect_signals() -> void:
    if !mouse_entered.is_connected(_on_mouse_entered):
        mouse_entered.connect(_on_mouse_entered)
    if !visibility_changed.is_connected(_on_visibility_changed):
        visibility_changed.connect(_on_visibility_changed)
    if !toggled.is_connected(_on_toggled):
        toggled.connect(_on_toggled)


func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        get_viewport().set_input_as_handled()
        if event.keycode == KEY_ESCAPE:
            button_pressed = false
            return
        elif event.keycode == KEY_BACKSPACE:
            button_pressed = false
            _reset_key_to_default()
            return
        elif event.keycode == KEY_BRACKETRIGHT:
            event = null
        remap_action_to(event)
        button_pressed = false
    elif event is InputEventMouseButton:
        if !event.button_index == MOUSE_BUTTON_LEFT:
            button_pressed = false


func remap_action_to(event: InputEvent) -> void:
    button_pressed = false
    # if !SettingsManager.keybind_manager.can_use_key(action):
    #     return

    match type:
        KeybindManager.INPUT_SCHEMES.KEYBOARD:
            if event == null or event is InputEventKey:
                SettingsManager.keybind_manager.input_map[action][0] = event
                pass
        KeybindManager.INPUT_SCHEMES.CONTROLLER:
            if event == null or event is InputEventJoypadButton or event is InputEventJoypadMotion:
                SettingsManager.keybind_manager.input_map[action][1] = event
                pass

    if InputMap.has_action(action):
        if current_event != null:
            InputMap.action_erase_event(action, current_event)
        if event != null:
            InputMap.action_add_event(action, event)
            
    keybind_changed.emit(action, event)
    set_current_event()
    _grab_focus_if_able()
    ControllerIcons.refresh()


func set_current_event() -> void:
    current_event = null
    if action == "":
        return
    match type:
        KeybindManager.INPUT_SCHEMES.KEYBOARD:
            for i in InputMap.action_get_events(action):
                if i is InputEventKey:
                    current_event = i
                    break
        KeybindManager.INPUT_SCHEMES.CONTROLLER:
            disabled = true
            for i in InputMap.action_get_events(action):
                if i is InputEventJoypadButton or i is InputEventJoypadMotion:
                    current_event = i
                    break
        KeybindManager.INPUT_SCHEMES.TOUCH:
            disabled = true
            current_event = null
    
    display_current_key()

## display the key string for 'action' from KBM.input_map. No event shows ''
func display_current_key() -> void:
    if menu != null:
        if menu.is_using_addon:
            text = ""
            return
    var events: Array
    if Engine.is_editor_hint():
        var project_events = ProjectSettings.get_setting("input/%s" % action)
        if project_events == null:
            text = ""
            return
        events = project_events["events"]
    else:
        events = InputMap.action_get_events(action)
    var current_key: String = ""
    match type:
        KeybindManager.INPUT_SCHEMES.KEYBOARD:
            for i in events.size():
                if events[i] is InputEventKey:
                    current_key = _display_keyboard_key(events[i])
                    current_event = events[i]
                    break
        KeybindManager.INPUT_SCHEMES.CONTROLLER:
            for i in events.size():
                if events[i] is InputEventJoypadButton:
                    current_key = _display_gamepad_key(events[i])
                    current_event = events[i]
                    break
                elif events[i] is InputEventJoypadMotion:
                    current_key = _display_gamepad_motion(events[i])
                    current_event = events[i]
                    break

    text = current_key


func _display_keyboard_key(event: InputEventKey) -> String:
    var ds_keycode := DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
    var keycode = OS.get_keycode_string(ds_keycode)
    return keycode


func _display_gamepad_key(event: InputEventJoypadButton) -> String:
    var key = event.as_text().split(" (")[1]
    var test = key.split(", ")
    # if key in joypad_map:
    #     return joypad_map[key]
    return test[0]


func _display_gamepad_motion(event: InputEventJoypadMotion) -> String:
    return "Axis: %s\nValue: %+0.1f" % [event.axis, event.axis_value]


func _set_events_to_action() -> void:
    InputMap.action_erase_events(action)
    for i in SettingsManager.keybind_manager.input_map[action].size():
        if SettingsManager.keybind_manager.input_map[action][i] != null:
            InputMap.action_add_event(action, SettingsManager.keybind_manager.input_map[action][i])

    
func _on_toggled(toggled_on: bool) -> void:
    set_process_input(toggled_on)
    is_rebind_mode = toggled_on
    rebind_mode.emit(toggled_on)
    if toggled_on:
        if shader != null:
            shader.set_shader_parameter("speed", 1)
        # text = "..."
        release_focus()
        if menu != null:
            menu.active_btn = self
    else:
        if shader != null:
            shader.set_shader_parameter("speed", 0)
        text = ""
        display_current_key()
        button_pressed = false


func _reset_key_to_default() -> void:
    var default_events = ProjectSettings.get_setting("input/%s" % action)
    var default_action: InputEvent = null
    var action_key: String = "events"
    for i in default_events.size():
        match type:
            KeybindManager.INPUT_SCHEMES.KEYBOARD:
                if default_events[action_key][i] is InputEventKey:
                    default_action = default_events[action_key][i]
                break
            KeybindManager.INPUT_SCHEMES.CONTROLLER:
                if default_events[action_key][i] is InputEventJoypadButton or default_events[action_key][i] is InputEventJoypadMotion:
                    default_action = default_events[action_key][i]
                break
                
    remap_action_to(default_action)


func _grab_focus_if_able() -> void:
    if disabled or focus_mode == Control.FOCUS_NONE: return
    if !is_rebind_mode:
        call_deferred("grab_focus")


func _on_mouse_entered() -> void:
    _grab_focus_if_able()


func _on_visibility_changed() -> void:
    if visible:
        # display_current_key()
        pass
    else:
        _on_toggled(false)
