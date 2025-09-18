@tool
extends Button
class_name KeybindButton

## The name of the action in the project settings input map
@export var action: String = ""

var menu: Control
var is_rebind_mode: bool = false


func _ready():
    # display_current_key()
    _connect_signals()
    set_process_input(false)


func _connect_signals() -> void:
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
        remap_action_to(event)
        button_pressed = false
    elif event is InputEventMouseButton:
        if !event.button_index == MOUSE_BUTTON_LEFT:
            button_pressed = false

## For text display when not using controller addon
func display_current_key():
    # var action_events = InputMap.action_get_events(action)
    # var current_key = ""
    # for i in action_events.size():
    #     if action_events[i] is InputEventKey:
    #         current_key = action_events[i].as_text()
    #         break
    # text = current_key
    pass


func remap_action_to(event: InputEventKey) -> void:
    if event == null:
        grab_focus()
        return
    var action_events = InputMap.action_get_events(action)
    InputMap.action_erase_events(action)
    var events = []
    for i in action_events.size():
        if action_events[i] is InputEventKey:
            events.append(event)
            continue
        events.append(action_events[i])
    for e in events:
        InputMap.action_add_event(action, e)
        
    SettingsManager.keybind_manager.input_map[action] = events
    SettingsManager.keybind_manager.save_input_map()
    # text = event.as_text()
    grab_focus()
    ControllerIcons.refresh()


func _on_toggled(toggled_on: bool) -> void:
    set_process_input(toggled_on)
    is_rebind_mode = toggled_on
    if toggled_on:
        text = "..."
        release_focus()
        if menu != null:
            menu.active_btn = self
    else:
        text = ""
        display_current_key()
        button_pressed = false


func _reset_key_to_default() -> void:
    var default_events = ProjectSettings.get_setting("input/%s" % action)
    var default_action: InputEvent = null
    for i in default_events.size():
        if default_events["events"][i] is InputEventKey:
            default_action = default_events["events"][i]
    remap_action_to(default_action)


func _on_mouse_entered() -> void:
    if disabled: return
    if !is_rebind_mode:
        grab_focus()


func _on_visibility_changed() -> void:
    if visible:
        # display_current_key()
        pass
    else:
        _on_toggled(false)
