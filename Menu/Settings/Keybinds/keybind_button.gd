extends Button
class_name KeybindButton


signal rebound_action(action: String, event: InputEvent, type: KeybindMenu.InputType)
signal rebind_mode_changed(is_rebind: bool)

@export var type: KeybindMenu.InputType = KeybindMenu.InputType.KEYBOARD

var container: KeybindContainer
var is_rebind_mode: bool = false
var action: String = ""
var last_event: String = ""
var last_icon: Texture2D


func _enter_tree() -> void:
    type = KeybindMenu.InputType.KEYBOARD


func _ready() -> void:
    toggled.connect(_on_toggled)
    KeybindManager.keybinds_reset.connect(_on_keybinds_reset)
    set_process_input(is_rebind_mode)
    init.call_deferred()


func _input(event: InputEvent) -> void:
    # if event is InputEventMouseButton and event.double_click:
    #         event.double_click = false
    get_viewport().set_input_as_handled()
    if event is InputEventKey and is_rebind_mode and event.is_pressed():
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
            KeybindMenu.InputType.KEYBOARD:
                if !event is InputEventKey and !event is InputEventMouseButton: continue
                _set_display_from_type(event)
                break
            KeybindMenu.InputType.GAMEPAD:
                if !event is InputEventJoypadMotion and !event is InputEventJoypadButton: continue
                _set_display_from_type(event)
                break
            _:
                print("unsupported type: " + str(type))


func _handle_rebind_detection(event: InputEvent) -> void:
    if event.is_action("ui_cancel"):
        print("cancelled remap")
        _on_rebind_failed()
        return
    # if event is already being remapped to
    if event.is_action("erase_keybind"):
        _erase_keybind()
        return
    if _has_dupe_in_remap(event):
        print("event in remap")
        _on_rebind_failed()
        return
    # if event is already used
    if _has_dupe_in_cache(event):
        print("event in cache")
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
            text = str(event.button_index)
        "InputEventJoypadMotion":
            _set_gamepad_icon(event)
        "InputEventJoypadButton":
            _set_gamepad_icon(event)
        _:
            push_warning("unsupported event type: " + event.get_class())
    last_event = text
    last_icon = icon


func _set_gamepad_icon(event: InputEvent) -> void:
    text = ""
    match event.get_class():
        "InputEventJoypadMotion":
            icon = load("res://Assets/GamepadIcons/l_stick.png")
            icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        "InputEventJoypadButton":
            icon = null
            if !KeybindManager.CONTROLLER_INDEX_NAMES.has(event.button_index):
                printerr("no controller button map for action: " + event.button_index)
                return
            if (KeybindManager.CONTROLLER_INDEX_NAMES[event.button_index] as String).is_absolute_path():
                icon = load(KeybindManager.CONTROLLER_INDEX_NAMES[event.button_index])
                icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
            else:
                text = str(KeybindManager.CONTROLLER_INDEX_NAMES[event.button_index])
                icon = null
        _:
            push_warning("unsupported event type: " + event.get_class())


## if this event is in the remap cache
func _has_dupe_in_remap(event: InputEvent) -> bool:
    var cache: Dictionary = container.menu.to_remap_cache
    if cache.is_empty(): return false
    for _action in cache: # move_up
        for _type in cache[_action]: # keyboard, gamepad
            if _has_remap_check_failed(_action, _type, event, cache[_action][_type]):
                return true
    return false

## if this event is in the keybind cache cache
func _has_dupe_in_cache(event: InputEvent) -> bool:
    var menu: KeybindMenu = container.menu
    for _action in menu.keybind_cache:
        if menu.to_remap_cache.has(_action):
            match type:
                KeybindMenu.InputType.KEYBOARD:
                    if menu.to_remap_cache[_action].has(KeybindMenu.TYPE_KEYBOARD_NAME):
                        continue
                KeybindMenu.InputType.GAMEPAD:
                    if menu.to_remap_cache[_action].has(KeybindMenu.TYPE_GAMEPAD_NAME):
                        continue
        if InputMap.action_has_event(_action, event):
            return true
    return false


func _has_remap_check_failed(_action: String, _type: String, event: InputEvent, cached_event: InputEvent) -> bool:
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
    rebind_mode_changed.emit(value)
    set_process_input(value)
    set_pressed_no_signal(value)


func _toggle_icon_theme_color(_is_visible: bool) -> void:
    if _is_visible:
        remove_theme_color_override("icon_pressed_color")
        remove_theme_color_override("icon_focus_color")
        remove_theme_color_override("icon_hovor_color")
        remove_theme_color_override("icon_hover_pressed_color")
        remove_theme_color_override("icon_normal_color")
    else:
        add_theme_color_override("icon_pressed_color", Color(1, 1, 1, 0))
        add_theme_color_override("icon_focus_color", Color(1, 1, 1, 0))
        add_theme_color_override("icon_hovor_color", Color(1, 1, 1, 0))
        add_theme_color_override("icon_hover_pressed_color", Color(1, 1, 1, 0))
        add_theme_color_override("icon_normal_color", Color(1, 1, 1, 0))


func _on_rebind_failed() -> void:
    text = last_event
    icon = last_icon
    _set_rebind_mode(false)


func _on_toggled(value: bool) -> void:
    _set_rebind_mode(value)
    if value:
        _toggle_icon_theme_color(false)
        text = "..."
    else:
        _toggle_icon_theme_color(true)
        set_display(InputMap.action_get_events(action))


func _on_keybinds_reset() -> void:
    _set_rebind_mode(false)
    set_display(InputMap.action_get_events(action))
