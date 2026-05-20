extends KeybindButton


func _enter_tree() -> void:
    type = KeybindManager.InputType.CONTROLLER


func _input(event: InputEvent) -> void:
    if (event is InputEventJoypadButton and is_rebind_mode) or event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _handle_rebind_detection(event)


func init() -> void:
    var events := InputMap.action_get_events(action)
    if KeybindManager.DEFAULT_GAMEPAD_KEYBINDS.has(action) and !disabled:
        disabled = !KeybindManager.DEFAULT_GAMEPAD_KEYBINDS[action]
    if disabled:
        focus_mode = FOCUS_NONE
    set_display(events)


func remap_action_to(event: InputEvent) -> void:
    if event == null:
        rebound_action.emit(action, null, type)
        _set_display_from_type(null)
        _set_rebind_mode(false)
        return
    if !event is InputEventJoypadButton: return
    if !KeybindManager.can_use_gamepad_key(str(event.button_index)): return
    rebound_action.emit(action, event, type)
    _set_display_from_type(event)
    _set_rebind_mode(false)
