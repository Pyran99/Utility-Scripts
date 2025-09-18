extends RefCounted
class_name KeybindManager

##-------------------------
## Add any input to show in keybind menu to DEFAULT_KEY_MAP. bool indicates if key can be rebound, otherwise show key as disabled.
## Choose file type to save keybinds to. Can remove unused functions
##   Config saves only physical keycodes for each actions events -> action = [keycode1, keycode2]
##   Config Full saves InputEventKey objects for each actions events -> action = Array[InputEvent]([Object(InputEventKey), Object(InputEventKey)])
##   Json saves only physical keycodes as strings for each actions events -> 'action': [keycode1, keycode2]
##   Json Full saves InputEventKey data as strings for each actions events -> 'action': ['InputEventKey1', 'InputEventKey2']
## SavingManager creates missing files
## Uncomment any lines from scenes for ControllerIcons if using addon
##-------------------------

## 'action': can_rebind || for any keys that will show in keybind menu
const DEFAULT_KEY_MAP = {
    "move_up": true,
    "move_down": true,
    "move_left": true,
    "move_right": true,
    "interact": true,
    "dodge": true,
    "pause": false,
}
const INPUT_SAVE_PATH = SavingManager.CONFIG_DIR + "keybinds.cfg"
const INPUT_KEYCODES_SAVE_PATH = SavingManager.CONFIG_DIR + "keybinds_keycodes.cfg"

var input_map: Dictionary # {action = [InputEventKey, InputEventKey]}
var save_joypad: bool = false
var allow_mouse_remap: bool = false

enum INPUT_SCHEMES {
    KEYBOARD,
    CONTROLLER,
    TOUCH,
}
var input_scheme: INPUT_SCHEMES = INPUT_SCHEMES.KEYBOARD


# Custom mouse velocity calculation, because Godot
# doesn't implement it on some OSes apparently
const _MOUSE_VELOCITY_DELTA := 0.1
var _t: float
var _mouse_velocity: int
@export_range(0, 10000) var mouse_min_movement: int = 200


# called from SettingsManager ready
func init() -> void:
    load_input_map()


func save_input_map() -> void:
    _save_input_keycodes_as_config()
    # _save_input_map_as_config()


func load_input_map() -> void:
    _load_input_keycodes_from_config()
    # _load_input_map_from_config()

## Reset InputMap to project settings, load default actions to input_map, save
func reset_input_map() -> void:
    InputMap.load_from_project_settings()
    _load_default_input_map()
    save_input_map()


# func change_input_scheme(new_scheme: InputSchemes) -> void:
#     input_scheme = new_scheme
#     changed_input_scheme.emit(input_scheme, input_scheme)


#region Config-------------------------

func _save_keybinds() -> void:
    SettingsManager.settings[Strings.KEYBINDS] = _get_keycodes_from_input_map(input_map)
    SettingsManager.save_settings()


func _load_keybinds() -> void:
    if SettingsManager.settings.has(Strings.KEYBINDS):
        input_map = SettingsManager.settings[Strings.KEYBINDS]
    else:
        reset_input_map()
    _add_events_to_input_map(input_map)

## Save config file with only the keycodes for each action
func _save_input_keycodes_as_config() -> void:
    var keycodes: Dictionary = _get_keycodes_from_input_map(input_map)
    SavingManager.save_as_config_in_file(Strings.KEYBINDS, keycodes, INPUT_KEYCODES_SAVE_PATH)


func _load_input_keycodes_from_config() -> void:
    var data := SavingManager.load_from_config_in_file(Strings.KEYBINDS, INPUT_KEYCODES_SAVE_PATH)
    if data == {}:
        reset_input_map()
        _load_input_keycodes_from_config()
        return
    input_map = data
    _add_event_keycodes_to_input_map(data)

## Save config file with the InputEventKey as objects for each action
func _save_input_map_as_config() -> void:
    SavingManager.save_as_config_in_file(Strings.KEYBINDS, input_map, INPUT_SAVE_PATH)


func _load_input_map_from_config() -> void:
    var data := SavingManager.load_from_config_in_file(Strings.KEYBINDS, INPUT_SAVE_PATH)
    if data.has(Strings.KEYBINDS):
        data = data[Strings.KEYBINDS]
    if data == {}:
        reset_input_map()
        _load_input_map_from_config()
        return
    input_map = data
    _add_event_objects_to_input_map(data)


#endregion


#region JSON-------------------------

## Save json file with only the keycodes for each action
func _save_input_keycodes_json() -> void:
    var keycodes: Dictionary = _get_keycodes_from_input_map(input_map)
    SavingManager.save_file_as_json_unencrypted(keycodes, INPUT_SAVE_PATH)


func _load_input_keycodes_json() -> void:
    var data := SavingManager.load_file_from_json_unencrypted(INPUT_SAVE_PATH)
    if data == {}:
        reset_input_map()
        _load_input_keycodes_json()
        return
    input_map = data
    _add_event_keycodes_to_input_map(data)

## Save json file with the InputEventKey as strings for each action
func _save_input_map_json() -> void:
    SavingManager.save_file_as_json_unencrypted(input_map, INPUT_SAVE_PATH)


func _load_input_map_json() -> void:
    var full_data := SavingManager.load_file_from_json_unencrypted(INPUT_SAVE_PATH)
    if full_data == {}:
        reset_input_map()
        _load_input_map_json()
        return
    var new_keycodes = _convert_json_string_to_events(full_data)
    input_map = new_keycodes
    _add_events_to_input_map(new_keycodes)

## Converts JSON InputEventKey strings to InputMap events for each DEFAULT_KEY_MAP action. Only works with InputEventKey
func _convert_json_string_to_events(json_data: Dictionary) -> Dictionary:
    var keycodes: Dictionary = {}
    for action in json_data.keys():
        if !DEFAULT_KEY_MAP.has(action):
            continue
        var codes: Array = []
        for i in json_data[action].size():
            var _event = null
            var value: String = json_data[action][i]
            if value == null or value == "":
                continue
            if value.begins_with("InputEventKey"):
                var key = value.substr(value.find("keycode=") + 1) # TODO test
                print_debug("key: %s" % key)
                var split = key.split(" ")
                var keycode = int(split[0])
                # value.replace("InputEventKey: keycode=", "")
                # value.split(" ")
                # var _key = int(value)
                var ds_keycode = DisplayServer.keyboard_get_keycode_from_physical(keycode)
                _event = _create_input_event_key(ds_keycode)
                codes.append(ds_keycode)
            else:
                print_debug("input is not key ", value)

        keycodes[action] = codes
    return keycodes


#endregion


#region Helpers-------------------------

#region get Inputs

func get_first_key_from_input_action(action: String) -> InputEventKey:
    if !InputMap.has_action(action):
        return null
    for i in InputMap.action_get_events(action):
        if i is InputEventKey:
            return i
    return null


func get_first_joypad_from_input_action(action: String) -> InputEventJoypadButton:
    if !InputMap.has_action(action):
        return null
    for i in InputMap.action_get_events(action):
        if i is InputEventJoypadButton:
            return i
    return null


func get_key_from_map(map: Array) -> InputEventKey:
    for i in map.size():
        if map[i] is InputEventKey:
            return map[i]
    return null


func get_joypad_from_map(map: Array) -> InputEventJoypadButton:
    for i in map.size():
        if map[i] is InputEventJoypadButton:
            return map[i]
    return null


func get_joypad_motion_from_map(map: Array) -> InputEventJoypadMotion:
    for i in map.size():
        if map[i] is InputEventJoypadMotion:
            return map[i]
    return null

#endregion

## If a specific key can be rebound to
func can_use_key(action: String) -> bool:
    var _action: String = action.to_lower()
    match _action:
        "escape":
            return false
        "backspace":
            return false
        _:
            return true

## Resets input_map to default InputMap values
func _load_default_input_map() -> void:
    input_map = {}
    var actions := InputMap.get_actions()
    for a in actions:
        if a.begins_with("ui_") or a.begins_with("DEBUG"): # ignore all engine defaults
            continue
        if !DEFAULT_KEY_MAP.has(a):
            continue
        input_map[a] = []
        for event in InputMap.action_get_events(a):
            input_map[a].append(event)

## Adds data to input_map. Works for either keycodes or InputEvent objects
func _add_events_to_input_map(map: Dictionary) -> void:
    if _parse_map_for_input_object(map): # if has InputEvent
        _add_event_objects_to_input_map(map)
    else:
        _add_event_keycodes_to_input_map(map)

## Adds data from {'key': [keycode,],} format to input_map
func _add_event_keycodes_to_input_map(map: Dictionary) -> void:
    for action in map.keys():
        if !DEFAULT_KEY_MAP.has(action) or !InputMap.has_action(action):
            continue
        var action_events := []
        var events = InputMap.action_get_events(action)
        InputMap.action_erase_events(action)
        for e in events.size():
            if events[e] is InputEventKey: # replace InputEventKey with saved keycode
                if map.has(action):
                    if map[action].size() == 0:
                        action_events.append(null)
                        continue
                    var keycode: int = map[action][e]
                    var event = _create_input_event_key(keycode)
                    action_events.append(event)
            else: # other InputEvent can be added directly
                action_events.append(events[e])
                #region Saving controller binds
            # elif events[e] is Dictionary:
            #     if events[e].has("button_index"):
            #         var event = _create_input_event_joypad(events[e]["button_index"])
            #         action_events[action][e] = event
            #     elif events[e].has("axis"):
            #         var event = _create_input_event_joypad_motion(events[e]["axis"], events[e]["axis_value"])
            #         action_events[action][e] = event
        # for i in map[action].size():
        #     var keycode: int = map[action][i]
        #     var event = _create_input_event_key(keycode)
        #     action_events[action][i] = event
        #endregion
        while action_events.size() < 2:
            action_events.append(null)
        input_map[action] = []
        for i in action_events.size():
            input_map[action].append(action_events[i])
            if action_events[i] != null:
                InputMap.action_add_event(action, action_events[i])

    _create_missing_actions()

## Adds data from {'key': [InputEvent,],} format to input_map
func _add_event_objects_to_input_map(map: Dictionary) -> void:
    for action in map.keys():
        if !DEFAULT_KEY_MAP.has(action) or !InputMap.has_action(action):
            continue
        var action_events := []
        for i in map[action].size():
            var event = map[action][i]
            action_events.append(event)

        while action_events.size() < 2:
            action_events.append(null)
        InputMap.action_erase_events(action)
        input_map[action] = []
        for a in action_events.size():
            input_map[action].append(action_events[a])
            if action_events[a] != null:
                InputMap.action_add_event(action, action_events[a])
        # input_map[action] = InputMap.action_get_events(action)

    _create_missing_actions()

## Returns the physical keycodes for every input action in 'map'. {"action": [object InputEventKey,],}. Saves joypad in dictionary by event value names
func _get_keycodes_from_input_map(map: Dictionary) -> Dictionary:
    var keycodes: Dictionary = {}
    for action in map.keys():
        var codes := []
        for _event in map[action]:
            if _event is InputEventKey:
                # codes[0] = _event.physical_keycode
                codes.append(_event.physical_keycode)
            elif !save_joypad:
                continue
            elif _event is InputEventJoypadButton:
                # codes[1] = {}
                codes.append({})
                codes[codes.size() - 1]["button_index"] = _event.button_index
            elif _event is InputEventJoypadMotion:
                # codes[1] = {}
                codes.append({})
                codes[codes.size() - 1]["axis"] = _event.axis
                codes[codes.size() - 1]["axis_value"] = _event.axis_value

        keycodes[action] = codes
    return keycodes

## Returns true if map is saved as {'key': [object InputEventKey],}
func _parse_map_for_input_object(map: Dictionary) -> bool:
    var string = JSON.stringify(map)
    var parse = JSON.parse_string(string)
    for key in parse.keys():
        for i in parse[key].size():
            var value = parse[key][i]
            if value is int or value is float or value == null:
                # keycode files are array of numbers/null
                return false
            if value.begins_with("InputEvent"):
                # input objects will be array of strings/null
                return true
    return false


func _create_missing_actions() -> void:
    for action in DEFAULT_KEY_MAP.keys():
        if !input_map.has(action):
            if InputMap.has_action(action):
                input_map[action] = InputMap.action_get_events(action)
            else:
                input_map[action] = []
            while input_map[action].size() < 2:
                input_map[action].append(null)


func _create_input_event_key(keycode: int) -> InputEventKey:
    if keycode == -1:
        return null
    var event = InputEventKey.new()
    event.physical_keycode = keycode
    return event


func _create_input_event_joypad(button_index: int) -> InputEventJoypadButton:
    var event = InputEventJoypadButton.new()
    event.button_index = button_index
    return event


func _create_input_event_joypad_motion(axis: int, axis_value: float) -> InputEventJoypadMotion:
    var event = InputEventJoypadMotion.new()
    event.axis = axis
    event.axis_value = axis_value
    return event


func _create_input_event_mouse_button(button_index: int) -> InputEventMouseButton:
    var event = InputEventMouseButton.new()
    event.button_index = button_index
    return event

#endregion


func _test_mouse_velocity(relative_vec: Vector2):
    if _t > _MOUSE_VELOCITY_DELTA:
        _t = 0
        _mouse_velocity = 0

    # We do a component sum instead of a length, to save on a
    # sqrt operation, and because length_squared is negatively
    # affected by low value vectors (<10).
    # It is also good enough for this system, so reliability
    # is sacrificed in favor of speed.
    _mouse_velocity += abs(relative_vec.x) + abs(relative_vec.y)
    return _mouse_velocity / _MOUSE_VELOCITY_DELTA > mouse_min_movement
