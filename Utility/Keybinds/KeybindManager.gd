extends RefCounted
class_name KeybindManager

#TODO controller inputs
#TODO 2. create a local keycodes dictionary from input map instead of class keycodes var

#-------------------------#
# Add any input to show in keybind menu to DEFAULT_KEY_MAP. bool indicates if key can be rebound, otherwise show key as disabled.
# Choose file type to save keybinds to.
#   Config saves only physical keycodes for each actions events -> action = [keycode1, keycode2]
#   Config Full saves InputEventKey objects for each actions events -> action = Array[InputEvent]([Object(InputEventKey), Object(InputEventKey)])
#   Json saves only physical keycodes as strings for each actions events -> 'action': [keycode1, keycode2]
#   Json Full saves InputEventKey data as strings for each actions events -> 'action': ['InputEventKey1', 'InputEventKey2']
# SavingManager creates missing files
#-------------------------#

## 'action': can_rebind
const DEFAULT_KEY_MAP = {
    "move_forward": true,
    "move_backward": true,
    "move_left": true,
    "move_right": true,
    "jump": true,
    "pause": false,
}
const INPUT_KEYCODES_CONFIG_FILE := SavingManager.CONFIG_DIR + "keybinds.cfg"
const INPUT_MAP_CONFIG_FILE := SavingManager.CONFIG_DIR + "keybinds_full.cfg"

const INPUT_KEYCODES_JSON_FILE := SavingManager.CONFIG_DIR + "keybinds.json"
const INPUT_MAP_JSON_FILE := SavingManager.CONFIG_DIR + "keybinds_full.json"

static var input_map: Dictionary
static var input_map_keycodes: Dictionary

static var config_input_map: Dictionary
static var config_input_map_keycodes: Dictionary

static var json_input_map: Dictionary
static var json_input_map_keycodes: Dictionary

# use ready if setting this to autoload
# called from GameManager ready
static func init() -> void:
    _load_default_input_map()
    load_input_map()


# func _ready():
#     init()


static func save_input_map() -> void:
    _save_input_keycodes_as_config()
    # _save_input_map_as_config()
    # _save_input_keycodes_json()
    # _save_input_map_json()


static func load_input_map() -> void:
    _load_input_keycodes_from_config()
    # _load_input_map_from_config()
    # _load_input_keycodes_json()
    # _load_input_map_json()


static func reset_input_map() -> void:
    InputMap.load_from_project_settings()
    _load_default_input_map()
    save_input_map()


static func can_use_key(action: String) -> bool:
    var _action: String = action.to_lower()
    match _action:
        "escape":
            return false
        "backspace":
            return false
        _:
            return true

#region Config
## Save config file with only the keycodes for each action
static func _save_input_keycodes_as_config() -> void:
    SavingManager.save_as_config_in_file("Keybinds", input_map_keycodes, INPUT_KEYCODES_CONFIG_FILE)


static func _load_input_keycodes_from_config() -> void:
    var data := SavingManager.load_from_config_in_file("Keybinds", INPUT_KEYCODES_CONFIG_FILE)
    if data == {}:
        reset_input_map()
        _load_input_keycodes_from_config()
        return
    _add_events_to_input_map(data)

## Save config file with the InputEventKey as objects for each action
static func _save_input_map_as_config() -> void:
    SavingManager.save_as_config_in_file("Keybinds", input_map, INPUT_MAP_CONFIG_FILE)


static func _load_input_map_from_config() -> void:
    var data := SavingManager.load_from_config_in_file("Keybinds", INPUT_MAP_CONFIG_FILE)
    if data == {}:
        reset_input_map()
        _load_input_map_from_config()
        return
    input_map = data
    _set_input_keycodes()
    _add_events_to_input_map(input_map_keycodes)
#endregion

#region JSON
## Save json file with only the keycodes for each action
static func _save_input_keycodes_json() -> void:
    #TODO. 2
    SavingManager.save_file_as_json_unencrypted(input_map_keycodes, INPUT_KEYCODES_JSON_FILE)


static func _load_input_keycodes_json() -> void:
    var data := SavingManager.load_file_from_json_unencrypted(INPUT_KEYCODES_JSON_FILE)
    if data == {}:
        reset_input_map()
        _load_input_keycodes_json()
        return
    _add_events_to_input_map(data)

## Save json file with the InputEventKey as strings for each action
static func _save_input_map_json() -> void:
    SavingManager.save_file_as_json_unencrypted(input_map, INPUT_MAP_JSON_FILE)


static func _load_input_map_json() -> void:
    var full_data := SavingManager.load_file_from_json_unencrypted(INPUT_MAP_JSON_FILE)
    if full_data == {}:
        reset_input_map()
        _load_input_map_json()
        return
    var new_keycodes = _convert_json_string_to_events(full_data)
    _add_events_to_input_map(new_keycodes)
#endregion

#region Helpers
## Resets input_map to default InputMap values. Sets input_map_keycodes to keycodes
static func _load_default_input_map() -> void:
    input_map.clear()
    for action in InputMap.get_actions():
        if action.begins_with("ui_"):
            continue
        if !DEFAULT_KEY_MAP.has(action):
            continue
        if InputMap.action_get_events(action).size() != 0:
            input_map[action] = InputMap.action_get_events(action)
            # add empty option if not defined in input map. Some actions may have a secondary option without being predefined in InputMap.
            if input_map[action].size() == 1:
                input_map[action].append(null)
                
    _set_input_keycodes()

## Converts keycodes from a dictionary to InputMap events. Only works with InputEventKey. Handles both config & json if data is in 'key': [keycodes] format
static func _add_events_to_input_map(data: Dictionary) -> void:
    for action in data.keys():
        if DEFAULT_KEY_MAP.has(action):
            var event
            for i in data[action].size():
                event = InputEventKey.new()
                var keycode: int = data[action][i]
                event.physical_keycode = keycode
                input_map[action][i] = event
            if input_map[action].size() == 1:
                input_map[action].append(null)

            InputMap.action_erase_events(action)
            for i in input_map[action].size():
                if input_map[action][i] == null:
                    continue
                InputMap.action_add_event(action, input_map[action][i])

    _set_input_keycodes()


static func _set_input_keycodes() -> void:
    for action in input_map:
        var codes: Array = []
        for _event in input_map[action]:
            if _event == null:
                continue
            codes.append(_event.physical_keycode)

        input_map_keycodes[action] = codes

## Converts JSON InputEventKey strings to InputMap events for each DEFAULT_KEY_MAP action. Only works with InputEventKey
static func _convert_json_string_to_events(json_data: Dictionary) -> Dictionary:
    var keycodes: Dictionary = {}
    for action in json_data.keys():
        if !DEFAULT_KEY_MAP.has(action):
            continue
        while json_data[action].size() < 2:
            # make sure there are 2 values
            json_data[action].append(null)
        
        var codes: Array = []
        for i in json_data[action].size():
            var event = null
            if json_data[action][i] == null:
                # input_map_keycodes[key][i] = null
                continue
            if json_data[action][i].begins_with("InputEventKey"):
                json_data[action][i].replace("InputEventKey: keycode=", "")
                json_data[action][i].split(" ")
                var _key = int(json_data[action][i])
                var keycode = DisplayServer.keyboard_get_keycode_from_physical(_key)
                event = InputEventKey.new()
                event.physical_keycode = keycode
                codes.append(keycode)

        keycodes[action] = codes

    return keycodes
#endregion
