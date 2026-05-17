extends KeybindButton


func _enter_tree() -> void:
    type = KeybindMenu.InputType.GAMEPAD


func _input(event: InputEvent) -> void:
    get_viewport().set_input_as_handled()
    if event.is_action_pressed("ui_cancel"):
        _on_toggled(false)
        return
    if event is InputEventJoypadButton and is_rebind_mode:
        _handle_rebind_detection(event)


func init() -> void:
    var events := InputMap.action_get_events(action)
    if KeybindManager.CONTROLLER_BUTTON_REMAP.has(action) and !disabled:
        disabled = !KeybindManager.CONTROLLER_BUTTON_REMAP[action]
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
    last_event = text
    _set_rebind_mode(false)
