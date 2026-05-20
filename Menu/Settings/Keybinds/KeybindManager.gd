extends Node
##AUTOLOAD
##

enum InputType {
    KEYBOARD,
    CONTROLLER,
}

signal keybinds_reset

## 'action': 'can rebind'
const DEFAULT_KEYBINDS = {
    "move_up": true,
    "move_down": true,
    "move_left": true,
    "move_right": true,
    "pause": false,
    "interact": true,
    "dodge": true,
}
## 'action': 'can rebind'
const DEFAULT_GAMEPAD_KEYBINDS: Dictionary = {
    "move_up": false, # only 1 move action container will show if stick controlled
    "move_down": false,
    "move_left": false,
    "move_right": false,
    "pause": false,
    "interact": true,
    "dodge": true,
}
## File path to keybinds folder
const MAIN_PATH: String = "res://Menu/Settings/Keybinds/"
## Paths to controller icons from button index or name for sticks/triggers
const CONTROLLER_INDEX_NAMES: Dictionary = {
    0: MAIN_PATH + "Assets/south.png",
    1: MAIN_PATH + "Assets/east.png",
    2: MAIN_PATH + "Assets/west.png",
    3: MAIN_PATH + "Assets/north.png",
    4: MAIN_PATH + "Assets/view.png",
    5: "Guide",
    6: MAIN_PATH + "Assets/menu.png",
    7: MAIN_PATH + "Assets/l_stick_click.png",
    8: MAIN_PATH + "Assets/r_stick_click.png",
    9: MAIN_PATH + "Assets/lb.png",
    10: MAIN_PATH + "Assets/rb.png",
    11: MAIN_PATH + "Assets/dpad_up.png",
    12: MAIN_PATH + "Assets/dpad_down.png",
    13: MAIN_PATH + "Assets/dpad_left.png",
    14: MAIN_PATH + "Assets/dpad_right.png",
    15: "null",
    "left_stick": MAIN_PATH + "Assets/l_stick.png",
    "right_stick": MAIN_PATH + "Assets/r_stick.png",
    "left_trigger": MAIN_PATH + "Assets/lt.png",
    "right_trigger": MAIN_PATH + "Assets/rt.png",
}
## paths to mouse icons from button index
const MOUSE_INDEX_NAMES: Dictionary = {
    1: MAIN_PATH + "Assets/left.png",
    2: MAIN_PATH + "Assets/right.png",
    3: "middle",
    4: MAIN_PATH + "Assets/wheel_up.png",
    5: MAIN_PATH + "Assets/wheel_down.png",
    6: "wheel_left",
    7: "wheel_right",
    8: MAIN_PATH + "Assets/side_up.png",
    9: MAIN_PATH + "Assets/side_down.png",
}

const SAVE_DIR: String = "user://config/"
const SAVE_PATH: String = SAVE_DIR + "keybinds.cfg"
## placeholder save path for adding the file to project folder
const PH_SAVE_PATH: String = "PH_keybind_save_file."
const TYPE_KEYBOARD_NAME: String = "keyboard"
const TYPE_CONTROLLER_NAME: String = "controller"

var keybind_menu: KeybindMenu
var is_saving: bool = false
var is_loading: bool = false
var is_file_invalid: bool = false
## {'action': {KEYBOARD: InputKey, GAMEPAD: InputJoypad}}
var keybinds: Dictionary = {}
var controller_manager: ControllerConnectionManager


func _enter_tree() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    DirAccess.make_dir_absolute(SAVE_DIR)
    controller_manager = ControllerConnectionManager.new()


func _ready() -> void:
    load_keybind_data()


func save_keybind_data() -> void:
    _save_keybinds()
    is_file_invalid = false


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
        "escape", "enter":
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

## Adds [param _event] to [param action] in [InputMap] & saves to [member keybinds].
##[br]Existing [InputMap] event of the same type will be erased
func add_event(action: String, event_to_add: InputEvent, type: InputType) -> void:
    if !keybinds.has(action):
        keybinds[action] = {}
    replace_keybinds_event(action, event_to_add, type)
    var was_added: bool = false
    match type:
        InputType.KEYBOARD:
            if !event_to_add is InputEventKey and event_to_add != null:
                push_warning("incorrect input type for keyboard '%s'" % event_to_add.get_class())
                return
            for event in InputMap.action_get_events(action):
                if event is InputEventKey or event is InputEventMouseButton:
                    replace_action_event(action, event, event_to_add)
                    was_added = true
                    break
        InputType.CONTROLLER:
            if !event_to_add is InputEventJoypadButton and event_to_add != null:
                push_warning("incorrect input type for controller '%s'" % event_to_add.get_class())
                return
            for event in InputMap.action_get_events(action):
                if event is InputEventJoypadButton:
                    replace_action_event(action, event, event_to_add)
                    was_added = true
                    break
        _:
            push_warning("unsupported input type '%s'" % type)
    if !was_added:
        replace_action_event(action, null, event_to_add)

## Erases event [param to_remove] & adds [param to_add]. null to skip
func replace_action_event(_action: String, to_remove: InputEvent, to_add: InputEvent) -> void:
    if !InputMap.has_action(_action):
        printerr("InputMap action not found '%s'" % _action)
        return
    if to_remove != null:
        InputMap.action_erase_event(_action, to_remove)
    if to_add != null:
        InputMap.action_add_event(_action, to_add)

## replaces event from [member keybinds] at [member type]
func replace_keybinds_event(_action: String, _event: InputEvent, type: InputType = InputType.KEYBOARD) -> void:
    if !keybinds.has(_action):
        keybinds[_action] = {}
    keybinds[_action][type] = _event

## Adds any action missing from [member keybinds]. If the event is in use with another action it is erased from InputMap of the missing action
func _add_missing_actions() -> void:
    for action in DEFAULT_KEYBINDS:
        if keybinds.has(action): continue
        keybinds[action] = {}
        var _events := InputMap.action_get_events(action)
        for event in _events:
            if event is InputEventKey:
                if _is_event_in_use(action, event): continue
                keybinds[action][InputType.KEYBOARD] = event
            elif event is InputEventJoypadButton:
                if _is_event_in_use(action, event): continue
                keybinds[action][InputType.CONTROLLER] = event
        print("Added default keybinds for missing action '%s'" % action)
        is_file_invalid = true
    if is_file_invalid:
        save_keybind_data()

## checks if [param event] is in use with another action. Erases [param action] [param event] from InputMap
func _is_event_in_use(action: String, event: InputEvent) -> bool:
    for _action in keybinds:
        for type in keybinds[_action]:
            var saved_event: InputEvent = keybinds[_action][type]
            var is_key := event is InputEventKey and keybinds[_action][type] is InputEventKey
            if is_key:
                if saved_event.physical_keycode == event.physical_keycode:
                    InputMap.action_erase_event(action, event)
                    return true
                continue
            var is_gamepad_btn := event is InputEventJoypadButton and saved_event is InputEventJoypadButton
            var is_mouse_btn := event is InputEventMouseButton and saved_event is InputEventMouseButton
            if is_gamepad_btn or is_mouse_btn:
                if saved_event.button_index == event.button_index:
                    InputMap.action_erase_event(action, event)
                    return true
                continue
            var is_gamepad_motion := event is InputEventJoypadMotion and saved_event is InputEventJoypadMotion
            if is_gamepad_motion:
                if saved_event.axis == event.axis:
                    InputMap.action_erase_event(action, event)
                    return true
                continue
    return false

## Resets all inputs to project default & saves
func _reset_input_map() -> void:
    InputMap.load_from_project_settings()
    keybinds.clear()
    for action in InputMap.get_actions():
        if is_action_engine_default(action): continue
        if !DEFAULT_KEYBINDS.has(action): continue
        keybinds[action] = {}
        for event in InputMap.action_get_events(action):
            if event is InputEventKey or event is InputEventMouseButton:
                keybinds[action][InputType.KEYBOARD] = event
            elif event is InputEventJoypadButton:
                keybinds[action][InputType.CONTROLLER] = event
    save_keybind_data()
    keybinds_reset.emit()


func _create_keybind_file() -> void:
    var temp := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    temp.store_string("{}")
    temp.close()


func _create_input_key(keycode: Key) -> InputEventKey:
    var key := InputEventKey.new()
    key.physical_keycode = keycode
    # key.pressed = true
    return key


func _create_gamepad_button(button: JoyButton) -> InputEventJoypadButton:
    var controller := InputEventJoypadButton.new()
    controller.button_index = button
    # controller.pressed = true
    return controller


func _is_input_event(event: Variant) -> bool:
    if event is InputEvent: return true
    return false


#region Save as JSON

func _save_keybinds() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        printerr("File error: ", FileAccess.get_open_error())
        return
    var _save_data: Dictionary = {}
    for action: String in keybinds:
        if !DEFAULT_KEYBINDS.has(action): continue
        _set_save_data(_save_data, action)
    file.store_string(JSON.stringify(_save_data, "", false))
    file.close()


func _set_save_data(_save_data: Dictionary, action: String) -> void:
    var event: InputEvent
    _save_data[action] = {}
    for type: InputType in keybinds[action]:
        if not _is_input_event(keybinds[action][type]): continue
        event = keybinds[action][type]
        match type:
            InputType.KEYBOARD:
                if DEFAULT_KEYBINDS.has(action) and DEFAULT_KEYBINDS[action] == true:
                    _save_data[action]["keyboard"] = get_input_keycode(event)
            InputType.CONTROLLER:
                if DEFAULT_GAMEPAD_KEYBINDS.has(action) and DEFAULT_GAMEPAD_KEYBINDS[action] == true:
                    _save_data[action]["controller"] = get_input_keycode(event)


func _load_keybinds() -> void:
    if !FileAccess.file_exists(SAVE_PATH):
        var temp := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        temp.store_string(JSON.stringify({}, "", false))
        temp.close()
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    var _valid_data := _is_load_file_valid(file)
    if _valid_data.is_empty(): return
    ## {'action': {'keyboard': 87, 'controller': 0}}
    _add_loaded_data(_valid_data)


func _is_load_file_valid(file: FileAccess) -> Dictionary:
    if file == null:
        push_error("File error: ", FileAccess.get_open_error())
        _reset_input_map()
        return {}
    var saved_data = JSON.parse_string(file.get_as_text())
    file.close()
    if saved_data == null or !saved_data is Dictionary or saved_data.is_empty():
        _reset_input_map()
        return {}
    return saved_data


func _add_loaded_data(data: Dictionary) -> void:
    keybinds.clear()
    for action: String in data:
        _create_input_map_from_loaded_data(data, action)
    _add_missing_actions()

## data is added to [member keybinds] from [method add_event]
func _create_input_map_from_loaded_data(data: Dictionary, action: String) -> void:
    var events := InputMap.action_get_events(action)
    keybinds[action] = {}
    if data[action].is_empty():
        _handle_loaded_data_action_empty(action, events)
        return
    _handle_missing_action_types(data, action, events)
    # use updated action events
    events = InputMap.action_get_events(action)
    for existing_event in events:
        # for not allowing controller motion change
        if existing_event is InputEventJoypadMotion or existing_event is InputEventMouseMotion:
            continue
        # # dont remove non rebindable events
        if existing_event is InputEventKey or existing_event is InputEventMouseButton:
            if DEFAULT_KEYBINDS.has(action):
                if DEFAULT_KEYBINDS[action] == false:
                    continue
        elif existing_event is InputEventJoypadButton:
            if DEFAULT_GAMEPAD_KEYBINDS.has(action):
                if DEFAULT_GAMEPAD_KEYBINDS[action] == false:
                    continue
        replace_action_event(action, existing_event, null)
    for type: String in data[action]:
        _add_event_for_type(data, action, type)

## Removes all events if the action type can be rebound
func _handle_loaded_data_action_empty(action: String, events: Array[InputEvent]) -> void:
    for _event in events:
        match _event.get_class():
            "InputEventKey", "InputEventMouseButton":
                if DEFAULT_KEYBINDS.has(action) and DEFAULT_KEYBINDS[action] == true:
                    replace_action_event(action, _event, null)
            "InputEventJoypadButton":
                if DEFAULT_GAMEPAD_KEYBINDS.has(action) and DEFAULT_GAMEPAD_KEYBINDS[action] == true:
                    replace_action_event(action, _event, null)
            "InputEventJoypadMotion", "InputEventMouseMotion":
                continue
            _:
                printerr("unknown event: " + str(_event))

## Removes events if "keyboard" and/or "controller" is missing from loaded data. Missing category means there is no event for action or its not rebindable, thus never added
func _handle_missing_action_types(data: Dictionary, action: String, events: Array[InputEvent]) -> void:
    if !data[action].has(TYPE_KEYBOARD_NAME):
        for _event in events:
            if !_event is InputEventKey and !_event is InputEventMouseButton: continue
            if DEFAULT_KEYBINDS.has(action):
                if DEFAULT_KEYBINDS[action] == false:
                    continue
            replace_action_event(action, _event, null)
    if !data[action].has(TYPE_CONTROLLER_NAME):
        for _event in events:
            if !_event is InputEventJoypadButton: continue
            if DEFAULT_GAMEPAD_KEYBINDS.has(action):
                if DEFAULT_GAMEPAD_KEYBINDS[action] == false:
                    continue
            replace_action_event(action, _event, null)
        
## Adds a new InputEvent with [method add_event] from created events based on [param type] ([member TYPE_KEYBOARD_NAME] or [member TYPE_CONTROLLER_NAME])
func _add_event_for_type(data: Dictionary, action: String, type: String) -> void:
    var event: InputEvent
    match type:
        TYPE_KEYBOARD_NAME:
            event = _create_input_key(int(data[action][type]))
            add_event(action, event, InputType.KEYBOARD)
        TYPE_CONTROLLER_NAME:
            event = _create_gamepad_button(int(data[action][type]))
            add_event(action, event, InputType.CONTROLLER)
        _:
            printerr("Unknown keybind type '%s' for action '%s'" % [type, action])

#endregion


#region Save as Config

## add to save funcs if using
# [keyboard]
# move_up=87
# [controller]
# jump=0

func _save_keybinds_config() -> void:
    var config := ConfigFile.new()
    var dupe := keybinds.duplicate()
    for action: String in dupe:
        if !DEFAULT_KEYBINDS.has(action): continue
        for type: InputType in dupe[action]:
            match type:
                InputType.KEYBOARD:
                    if dupe[action][type] is InputEventMouseButton: continue
                    config.set_value(TYPE_KEYBOARD_NAME, action, get_input_keycode(dupe[action][type]))
                InputType.CONTROLLER:
                    if dupe[action][type] is InputEventJoypadMotion: continue
                    config.set_value(TYPE_CONTROLLER_NAME, action, get_input_keycode(dupe[action][type]))
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
            if !_loaded_data.has(key):
                _loaded_data[key] = {}
            if value == -1: continue
            if section == TYPE_KEYBOARD_NAME:
                _loaded_data[key][section] = value
            elif section == TYPE_CONTROLLER_NAME:
                _loaded_data[key][section] = value
    _add_loaded_data(_loaded_data)

#endregion
