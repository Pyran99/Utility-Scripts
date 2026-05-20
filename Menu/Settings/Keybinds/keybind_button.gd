extends Button
class_name KeybindButton


signal rebound_action(action: String, event: InputEvent, type: KeybindManager.InputType)
signal rebind_mode_changed(is_rebind: bool, node: Control)

@export var type: KeybindManager.InputType = KeybindManager.InputType.KEYBOARD

var container: KeybindContainer
var is_rebind_mode: bool = false
var action: String = ""
var last_event: String = ""
var last_icon: Texture2D


func _enter_tree() -> void:
    type = KeybindManager.InputType.KEYBOARD


func _ready() -> void:
    toggled.connect(_on_toggled)
    KeybindManager.keybinds_reset.connect(_on_keybinds_reset)
    set_process_input(is_rebind_mode)
    init.call_deferred()


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.double_click:
            event.double_click = false
    if (event is InputEventKey and is_rebind_mode and event.is_pressed()) or event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _handle_rebind_detection(event)


func init() -> void:
    if action.is_empty():
        queue_free()
        return
    var events := InputMap.action_get_events(action)
    if KeybindManager.DEFAULT_KEYBINDS.has(action) and !disabled:
        disabled = !KeybindManager.DEFAULT_KEYBINDS[action]
    if disabled:
        focus_mode = FOCUS_NONE
    set_display(events)


func remap_action_to(event: InputEvent) -> void:
    if event == null:
        rebound_action.emit(action, null, type)
        _set_display_from_type(null)
        _set_rebind_mode(false)
        return
    if !event is InputEventKey: return
    if !KeybindManager.can_use_key(OS.get_keycode_string(event.physical_keycode)): return
    rebound_action.emit(action, event, type)
    _set_display_from_type(event)
    _set_rebind_mode(false)


func set_display(_events: Array[InputEvent]) -> void:
    text = ""
    icon = null
    for event in _events:
        match type:
            KeybindManager.InputType.KEYBOARD:
                if !event is InputEventKey and !event is InputEventMouseButton: continue
                _set_display_from_type(event)
                break
            KeybindManager.InputType.CONTROLLER:
                if !event is InputEventJoypadMotion and !event is InputEventJoypadButton: continue
                _set_display_from_type(event)
                break
            _:
                print("unsupported type: " + str(type))


func _handle_rebind_detection(event: InputEvent) -> void:
    if event.is_action("ui_cancel"):
        _on_rebind_failed()
        return
    if event.is_action("erase_keybind"):
        _erase_keybind()
        return
    # if event is already being remapped to
    if _has_dupe_in_remap(event):
        _on_rebind_failed()
        return
    # if event is already used
    if _has_dupe_in_cache(event):
        _on_rebind_failed()
        return
    remap_action_to(event)


func _set_display_from_type(event: InputEvent) -> void:
    if event == null:
        text = ""
        icon = null
        last_event = text
        last_icon = icon
        return
    match event.get_class():
        "InputEventKey":
            var key := DisplayServer.keyboard_get_label_from_physical(event.physical_keycode)
            text = OS.get_keycode_string(key)
        "InputEventMouseButton":
            _set_icon_from_event(event)
        "InputEventJoypadMotion", "InputEventJoypadButton":
            _set_icon_from_event(event)
        _:
            push_warning("unsupported event type: " + event.get_class())
    last_event = text
    last_icon = icon


func _set_icon_from_event(event: InputEvent) -> void:
    text = ""
    icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    match event.get_class():
        "InputEventJoypadMotion":
            _load_joypad_motion_axis_icon(event)
        "InputEventJoypadButton":
            _load_joypad_button_icon(event)
        "InputEventMouseButton":
            _load_mouse_button_icon(event)
        _:
            push_warning("unsupported icon event type: ", event)

## if this event is in the remap cache
func _has_dupe_in_remap(event: InputEvent) -> bool:
    var cache: Dictionary = container.menu.to_remap_cache
    if cache.is_empty(): return false
    for _action in cache: # move_up
        for _type: KeybindManager.InputType in cache[_action]:
            if _has_remap_check_failed(_action, _type, event, cache[_action][_type]):
                return true
    return false

## if this event is in the keybind cache
func _has_dupe_in_cache(event: InputEvent) -> bool:
    var menu: KeybindMenu = container.menu
    for _action in menu.keybind_cache:
        # if the action is being rebound
        if menu.to_remap_cache.has(_action):
            if menu.to_remap_cache[_action].has(type):
                continue
        if InputMap.action_has_event(_action, event):
            return true
    return false


func _has_remap_check_failed(_action: String, _type: KeybindManager.InputType, event: InputEvent, cached_event: InputEvent) -> bool:
    if (event is InputEventKey and cached_event is InputEventKey):
        if event.physical_keycode == cached_event.physical_keycode:
            return true
    elif (event is InputEventJoypadButton and cached_event is InputEventJoypadButton):
        if event.button_index == cached_event.button_index:
            return true
    return false


func _erase_keybind() -> void:
    remap_action_to(null)


func _set_rebind_mode(value: bool) -> void:
    is_rebind_mode = value
    rebind_mode_changed.emit(value, self )
    set_process_input(value)
    set_pressed_no_signal(value)
    if value:
        _toggle_icon_theme_color(false)
        text = "..."
    else:
        _toggle_icon_theme_color(true)
        text = last_event
        icon = last_icon


func _toggle_icon_theme_color(_is_visible: bool) -> void:
    icon = last_icon if _is_visible else null
    # if _is_visible:
    #     remove_theme_color_override("icon_pressed_color")
    # else:
    #     add_theme_color_override("icon_pressed_color", Color.TRANSPARENT)


func release_pressed_button() -> void:
    last_event = text
    last_icon = icon
    if is_rebind_mode:
        _set_rebind_mode(false)


func _load_joypad_motion_axis_icon(event: InputEventJoypadMotion) -> void:
    var axis := event.axis
    match axis:
        0, 1: # left stick x/y
            icon = load(KeybindManager.CONTROLLER_INDEX_NAMES["left_stick"])
        2, 3: # right stick x/y
            icon = load(KeybindManager.CONTROLLER_INDEX_NAMES["right_stick"])
        4: # left trigger
            icon = load(KeybindManager.CONTROLLER_INDEX_NAMES["left_trigger"])
        5: # right trigger
            icon = load(KeybindManager.CONTROLLER_INDEX_NAMES["right_trigger"])


func _load_joypad_button_icon(event: InputEventJoypadButton) -> void:
    icon = null
    if !KeybindManager.CONTROLLER_INDEX_NAMES.has(event.button_index):
        printerr("no controller button map for action: ", event.button_index)
        return
    if KeybindManager.CONTROLLER_INDEX_NAMES[event.button_index].is_absolute_path():
        icon = load(KeybindManager.CONTROLLER_INDEX_NAMES[event.button_index])
        icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    else:
        text = str(KeybindManager.CONTROLLER_INDEX_NAMES[event.button_index])
        icon = null


func _load_mouse_button_icon(event: InputEventMouseButton) -> void:
    if !KeybindManager.MOUSE_INDEX_NAMES.has(event.button_index):
        printerr("no mouse button map for action: ", event.button_index)
        return
    if KeybindManager.MOUSE_INDEX_NAMES[event.button_index].is_absolute_path():
        icon = load(KeybindManager.MOUSE_INDEX_NAMES[event.button_index])
    else:
        text = event.as_text()
        icon = null


func _on_rebind_failed() -> void:
    _set_rebind_mode(false)


func _on_toggled(value: bool) -> void:
    _set_rebind_mode(value)


func _on_keybinds_reset() -> void:
    _set_rebind_mode(false)
    set_display(InputMap.action_get_events(action))
