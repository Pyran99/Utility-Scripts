extends Node
class_name KeybindManager

const DEFAULT_KEY_MAP = {
    "move_forward": [KEY_W, KEY_UP],
    "move_backward": [KEY_S, KEY_DOWN],
    "move_left": [KEY_A, KEY_LEFT],
    "move_right": [KEY_D, KEY_RIGHT],
    # "space": [KEY_SPACE],
    # "left_click": [MOUSE_BUTTON_LEFT],
    # "move_right": "", # for setting key to no value
}
const keymap_path = "user://keybinds.cfg"

static var keymaps: Dictionary

# use ready if setting this to autoload
# called from GameManager
static func init() -> void:
    for action in InputMap.get_actions():
        if InputMap.action_get_events(action).size() != 0:
            keymaps[action] = InputMap.action_get_events(action)
            
    load_keymap()


# func _ready():
#     init()


static func load_keymap():
    if !FileAccess.file_exists(keymap_path):
        reset_keymap()
        # return
    # var temp = SavingManager.load_from_config("Keybinds")
    # print_debug(temp)
    var file = FileAccess.open(keymap_path, FileAccess.READ)
    var temp_keymap = file.get_var(true) as Dictionary
    file.close()
    for action in keymaps.keys():
        if temp_keymap.has(action):
            keymaps[action] = temp_keymap[action]
            InputMap.action_erase_events(action)
            for event in keymaps[action]:
                InputMap.action_add_event(action, event)


static func save_keymap():
    var file = FileAccess.open(keymap_path, FileAccess.WRITE)
    file.store_var(keymaps, true)
    file.close()
    # SavingManager.save_as_config("Keybinds", keymaps)


static func reset_keymap():
    for action in DEFAULT_KEY_MAP:
        InputMap.action_erase_events(action)
        var events = []
        for key in DEFAULT_KEY_MAP[action]:
            var event
            if key == MOUSE_BUTTON_MASK_LEFT or key == MOUSE_BUTTON_MIDDLE or key == MOUSE_BUTTON_RIGHT:
                event = InputEventMouseButton.new()
                event.button_index = key
            else:
                event = InputEventKey.new()
                event.keycode = key
            if event:
                events.append(event)
                InputMap.action_add_event(action, event)
        keymaps[action] = events

    save_keymap()
