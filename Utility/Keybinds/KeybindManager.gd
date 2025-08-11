extends RefCounted
class_name KeybindManager


# const DEFAULT_KEY_MAP = {
#     "move_forward": [KEY_W, KEY_UP],
# }

# Add any input action that will show in keybind menu. bool value indicates if can be rebound
const DEFAULT_KEY_MAP = {
    "move_forward": true,
    "move_backward": true,
    "move_left": true,
    "move_right": true,
    "jump": true,
    "pause": false,
}
const keymap_path = "user://keybinds.cfg"

static var keymaps: Dictionary

# use ready if setting this to autoload
# called from GameManager ready
static func init() -> void:
    _load_default_keymap()
    load_keymap_encoded()


# func _ready():
#     init()


static func load_keymap_encoded() -> void:
    if !FileAccess.file_exists(keymap_path):
        reset_keymap()
        return

    var file = FileAccess.open(keymap_path, FileAccess.READ)
    var temp_keymap = file.get_var(true) as Dictionary
    file.close()
    for action in keymaps.keys():
        if temp_keymap.has(action):
            keymaps[action] = temp_keymap[action]
            InputMap.action_erase_events(action)
            for event in keymaps[action]:
                if event == null:
                    continue
                InputMap.action_add_event(action, event)


static func save_keymap_encoded() -> void:
    var file = FileAccess.open(keymap_path, FileAccess.WRITE)
    file.store_var(keymaps, true)
    file.close()


static func reset_keymap() -> void:
    InputMap.load_from_project_settings()
    _load_default_keymap()
    save_keymap_encoded()

    
static func can_use_key(action: String) -> bool:
    var _action: String = action.to_lower()
    match _action:
        "escape":
            return false
        "backspace":
            return false
        _:
            return true


## Resets keymaps to default InputMap values
static func _load_default_keymap() -> void:
    keymaps.clear()
    for action in InputMap.get_actions():
        if action.begins_with("ui_"):
            continue
        if !DEFAULT_KEY_MAP.has(action):
            continue
        if InputMap.action_get_events(action).size() != 0:
            keymaps[action] = InputMap.action_get_events(action)
            # add empty option if not defined in input map
            if keymaps[action].size() == 1:
                keymaps[action].append(null)
