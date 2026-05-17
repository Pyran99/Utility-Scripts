extends Node
##AUTOLOAD
##

signal keybinds_reset

## 'action': 'can rebind'
const DEFAULT_KEYBINDS = {
    "move_up": true,
    "move_down": true,
    "move_left": true,
    "move_right": true,
    "interact": true,
    "jump": true,
    "attack": false,
    "test_action": true,
}
## 'action': 'can rebind'
const CONTROLLER_BUTTON_REMAP: Dictionary = {
    "move_up": false,
    "move_down": false,
    "move_left": false,
    "move_right": false,
    "interact": true,
    "jump": true,
    "attack": true,
    "test_action": true,
}
const CONTROLLER_INDEX_NAMES: Dictionary = {
    0: "res://Assets/GamepadIcons/south.png",
    1: "res://Assets/GamepadIcons/east.png",
    2: "res://Assets/GamepadIcons/west.png",
    3: "res://Assets/GamepadIcons/north.png",
    4: "res://Assets/GamepadIcons/view.png",
    5: "Guide",
    6: "res://Assets/GamepadIcons/menu.png",
    7: "res://Assets/GamepadIcons/l_stick_click.png",
    8: "res://Assets/GamepadIcons/r_stick_click.png",
    9: "res://Assets/GamepadIcons/lb.png",
    10: "res://Assets/GamepadIcons/rb.png",
    11: "res://Assets/GamepadIcons/dpad_up.png",
    12: "res://Assets/GamepadIcons/dpad_down.png",
    13: "res://Assets/GamepadIcons/dpad_left.png",
    14: "res://Assets/GamepadIcons/dpad_right.png",
    15: "null",
}

const SAVE_DIR: String = "user://config/"
const SAVE_PATH: String = SAVE_DIR + "keybinds.json"
## placeholder save path for adding the file to project folder
const PH_SAVE_PATH: String = "PH_keybind_save_file."

var keybind_menu: KeybindMenu
var is_saving: bool = false
var is_loading: bool = false
var is_file_invalid: bool = false
## {'action': {'keyboard': InputKey, 'gamepad': InputJoypad}}
var keybinds: Dictionary = {}


func _enter_tree() -> void:
    DirAccess.make_dir_absolute(SAVE_DIR)


func _ready() -> void:
    load_keybind_data()


func _unhandled_key_input(event: InputEvent) -> void:
    # if event.is_action_pressed("save"):
    #     save_keybind_data()
    if event.is_action_pressed("pause"):
        _toggle_keybind_menu()


func save_keybind_data() -> void:
    _save_keybinds()


func load_keybind_data() -> void:
    _load_keybinds()


func reset_keybinds() -> void:
    _reset_input_map()

## returns the key value from event class
func get_input_keycode(event: InputEvent) -> int:
    if event == null: return -1
    match event.get_class():
        "InputEventKey":
            return DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
        "InputEventMouseButton":
            return event.button_index
        "InputEventJoypadButton":
            return event.button_index
        "InputEventJoypadMotion":
            return event.axis
    return -1


## If a specific key can be rebound to
func can_use_key(action: String) -> bool:
    var _action: String = action.to_lower()
    match _action:
        "escape", "backspace", "enter":
            return false
        _:
            return true

## If a specific key can be rebound to
func can_use_gamepad_key(action: String) -> bool:
    var _action: String = action.to_lower()
    match _action:
        "4", "5", "6": # joypad actions [back,guide,start]
            return false
        _:
            return true


func is_action_engine_default(action: String) -> bool:
    if action.begins_with("ui_") or action.begins_with("DEBUG"):
        return true
    return false


func is_action_in_default(action: String) -> bool:
    if !DEFAULT_KEYBINDS.has(action):
        printerr("unknown action: " + action)
        return false
    return true

## Adds [param _event] to [param action] in [InputMap] & saves to [member keybinds].
##[br]Existing [InputMap] event of the same type will be erased
func add_event(action: String, event_to_add: InputEvent) -> void:
    if !keybinds.has(action):
        keybinds[action] = {}
    if event_to_add == null:
        print("TODO null event")
        return
    if event_to_add is InputEventKey:
        replace_keybind_event(action, event_to_add, KeybindMenu.TYPE_KEYBOARD_NAME)
        for event in InputMap.action_get_events(action):
            if event is InputEventKey:
                replace_action_event(action, event, event_to_add)
                break
        if !InputMap.action_get_events(action).has(event_to_add):
            InputMap.action_add_event(action, event_to_add)
    elif event_to_add is InputEventJoypadButton:
        replace_keybind_event(action, event_to_add, KeybindMenu.TYPE_GAMEPAD_NAME)
        for event in InputMap.action_get_events(action):
            if event is InputEventJoypadButton:
                replace_action_event(action, event, event_to_add)
                break
        if !InputMap.action_get_events(action).has(event_to_add):
            InputMap.action_add_event(action, event_to_add)
    else:
        push_warning("Undefined keybind type '%s' for action '%s'" % [event_to_add.get_class(), action])


## Erases event [param to_remove] & adds [param to_add]. null to skip
func replace_action_event(_action: String, to_remove: InputEvent, to_add: InputEvent) -> void:
    if !InputMap.has_action(_action):
        print("InputMap action not found '%s'" % _action)
        return
    if to_remove != null:
        InputMap.action_erase_event(_action, to_remove)
    if to_add != null:
        InputMap.action_add_event(_action, to_add)

## replaces event from [member keybinds] at [member type]
func replace_keybind_event(_action: String, _event: InputEvent, type: String = KeybindMenu.TYPE_KEYBOARD_NAME) -> void:
    if !keybinds.has(_action):
        keybinds[_action] = {}
    if _event == null:
        if type.is_empty():
            push_warning("missing keybind type from '%s'" % _action)
            return
        match type:
            KeybindMenu.TYPE_KEYBOARD_NAME:
                keybinds[_action][KeybindMenu.TYPE_KEYBOARD_NAME] = null
            KeybindMenu.TYPE_GAMEPAD_NAME:
                keybinds[_action][KeybindMenu.TYPE_GAMEPAD_NAME] = null
            _:
                push_warning("unsupported keybind type '%s'" % type)
        return
    match _event.get_class():
        "InputEventKey":
            keybinds[_action][KeybindMenu.TYPE_KEYBOARD_NAME] = _event
        "InputEventJoypadButton":
            keybinds[_action][KeybindMenu.TYPE_GAMEPAD_NAME] = _event
        _:
            push_warning("unsupported event class type '%s'" % _event.get_class())


func _toggle_keybind_menu() -> void:
    if keybind_menu == null:
        var scene = load("uid://bs4cgkbvpp04w").instantiate()
        keybind_menu = scene
        get_tree().root.add_child(scene)
    else:
        keybind_menu.queue_free()


func _add_missing_actions() -> void:
    for action in DEFAULT_KEYBINDS:
        if keybinds.has(action): continue
        keybinds[action] = {}
        var _events := InputMap.action_get_events(action)
        for event in _events:
            if event is InputEventKey:
                keybinds[action][KeybindMenu.TYPE_KEYBOARD_NAME] = event
            elif event is InputEventJoypadButton:
                keybinds[action][KeybindMenu.TYPE_GAMEPAD_NAME] = event
        print("Added default keybinds for: " + action)
        is_file_invalid = true
    if is_file_invalid:
        save_keybind_data()

## Resets all inputs to project default
func _reset_input_map() -> void:
    InputMap.load_from_project_settings()
    keybinds.clear()
    for action in InputMap.get_actions():
        if is_action_engine_default(action): continue
        if !DEFAULT_KEYBINDS.has(action): continue
        keybinds[action] = {}
        for event in InputMap.action_get_events(action):
            if event is InputEventKey:
                keybinds[action][KeybindMenu.TYPE_KEYBOARD_NAME] = event
            elif event is InputEventJoypadButton:
                keybinds[action][KeybindMenu.TYPE_GAMEPAD_NAME] = event
    save_keybind_data()
    keybinds_reset.emit()


func _create_keybind_file() -> void:
    var temp := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    temp.store_string("{}")
    temp.close()


func _create_input_key(keycode: Key) -> InputEventKey:
    var key := InputEventKey.new()
    key.physical_keycode = keycode
    key.pressed = true
    return key


func _create_gamepad_button(button: JoyButton) -> InputEventJoypadButton:
    var gamepad := InputEventJoypadButton.new()
    gamepad.button_index = button
    gamepad.pressed = true
    return gamepad


#region Save as JSON

func _save_keybinds() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        printerr("File error: ", FileAccess.get_open_error())
        return
    var _save_data: Dictionary = {}
    for action in keybinds:
        _set_save_data(_save_data, action)
    file.store_string(JSON.stringify(_save_data, "", false))
    file.close()
    is_file_invalid = false


func _set_save_data(_save_data: Dictionary, action: String) -> void:
    var event: InputEvent
    _save_data[action] = {}
    for type in keybinds[action]:
        if not keybinds[action][type] is InputEvent: continue
        event = keybinds[action][type]
        match type:
            KeybindMenu.TYPE_KEYBOARD_NAME:
                _save_data[action][type] = get_input_keycode(event)
            KeybindMenu.TYPE_GAMEPAD_NAME:
                _save_data[action][type] = get_input_keycode(event)


func _load_keybinds() -> void:
    if !FileAccess.file_exists(SAVE_PATH):
        var temp := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        temp.store_string(JSON.stringify({}, "", false))
        temp.close()
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    var _valid_data := _is_load_file_valid(file)
    if _valid_data.is_empty(): return
    ## {'action': {'keyboard': 87, 'gamepad': 0}}
    keybinds.clear()
    _add_loaded_data(_valid_data)


func _is_load_file_valid(file: FileAccess) -> Dictionary:
    if file == null:
        push_error("File error: ", FileAccess.get_open_error())
        _reset_input_map()
        save_keybind_data()
        return {}
    var saved_data = JSON.parse_string(file.get_as_text())
    file.close()
    if saved_data == null or !saved_data is Dictionary or saved_data.is_empty():
        _reset_input_map()
        save_keybind_data()
        return {}
    return saved_data


func _add_loaded_data(_data: Dictionary) -> void:
    for action: String in _data:
        _create_input_map_from_loaded_data(_data, action)
    _add_missing_actions()


func _create_input_map_from_loaded_data(_data: Dictionary, action: String) -> void:
    var event: InputEvent
    keybinds[action] = {}
    for type: String in _data[action]:
        match type:
            KeybindMenu.TYPE_KEYBOARD_NAME:
                event = _create_input_key(_data[action][type])
                add_event(action, event)
            KeybindMenu.TYPE_GAMEPAD_NAME:
                event = _create_gamepad_button(_data[action][type])
                add_event(action, event)
            _:
                printerr("Unknown keybind type '%s' for action '%s'" % [type, action])
        
#endregion


#region Save as Config
## add to save funcs
# [keyboard]
# move_up=87
# [gamepad]
# jump=0

func _save_keybinds_config() -> void:
    if keybinds.is_empty():
        _reset_input_map()
    var config := ConfigFile.new()
    var dupe := keybinds.duplicate()
    for action in dupe:
        if !is_action_in_default(action): continue
        for type in dupe[action]:
            match type:
                KeybindMenu.TYPE_KEYBOARD_NAME:
                    config.set_value(KeybindMenu.TYPE_KEYBOARD_NAME, action, get_input_keycode(dupe[action][type]))
                KeybindMenu.TYPE_GAMEPAD_NAME:
                    config.set_value(KeybindMenu.TYPE_GAMEPAD_NAME, action, get_input_keycode(dupe[action][type]))
    config.save(PH_SAVE_PATH + "cfg")


func _load_keybinds_config() -> void:
    if !FileAccess.file_exists(PH_SAVE_PATH + "cfg"):
        var file = FileAccess.open(PH_SAVE_PATH + "cfg", FileAccess.WRITE)
        file.close()
        _reset_input_map()
        keybinds_reset.emit()
        return
    var config := ConfigFile.new()
    var err = config.load(PH_SAVE_PATH + "cfg")
    if err != OK: return
    var _loaded_data: Dictionary = {}
    for section in config.get_sections():
        for key in config.get_section_keys(section):
            var value = config.get_value(section, key)
            _loaded_data[key] = {}
            if section == KeybindMenu.TYPE_KEYBOARD_NAME:
                var input_key := _create_input_key(value)
                _loaded_data[key][KeybindMenu.TYPE_KEYBOARD_NAME] = input_key
                add_event(section, input_key)
            elif section == KeybindMenu.TYPE_GAMEPAD_NAME:
                var input_key := _create_gamepad_button(value)
                _loaded_data[key][KeybindMenu.TYPE_GAMEPAD_NAME] = input_key
                add_event(section, input_key)
    keybinds = _loaded_data.duplicate()

#endregion
