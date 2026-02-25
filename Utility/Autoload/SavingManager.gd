@icon("res://Assets/Packs/Kenney/Game Icons/gear.png")
extends Node
#AUTOLOAD

const SAVE_DIR = "user://saves/"
const CONFIG_DIR = "user://config/"
const SETTINGS_FILE: String = CONFIG_DIR + "settings.cfg"
const SAVE_GROUP = "savable"
const MAX_SLOTS = 3

## all data to be saved
var saved_data: Dictionary = {}


#func _exit_tree() -> void:
    #_remove_cs_commands()


func _ready() -> void:
    if !DirAccess.dir_exists_absolute(SAVE_DIR):
        DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    if !DirAccess.dir_exists_absolute(CONFIG_DIR):
        DirAccess.make_dir_recursive_absolute(CONFIG_DIR)
    #_add_cs_commands.call_deferred()


func save_game(slot: int) -> void:
    save_game_binary(get_save_path(slot))


func load_game(slot: int) -> void:
    load_game_binary(get_save_path(slot))


func add_to_save_group(node: Node) -> void:
    node.add_to_group(SAVE_GROUP)


func get_save_path(slot: int) -> String:
    assert(slot >= 0 and slot < MAX_SLOTS, "invalid save slot")
    return SAVE_DIR + "save_%d.dat" % slot


func has_save_slot(slot: int) -> bool:
    assert(slot >= 0 and slot < MAX_SLOTS, "invalid save slot")
    return FileAccess.file_exists(get_save_path(slot))

## helper func for ui or other systems
func get_all_save_slots_info() -> Array:
    var slots = []
    for i in range(MAX_SLOTS):
        slots.append({
            "slot": i,
            "exists": has_save_slot(i),
            # can add timestamp or other metadata (ex. last save at 10pm)
        })
    return slots

## if save file does not exist, create it
func _create_and_verify_file(save_file: String) -> bool:
    if FileAccess.file_exists(save_file):
        return true
    var file = FileAccess.open(save_file, FileAccess.WRITE)
    if !_verify_file(file, save_file):
        return false
    file.close()
    return true


func _verify_file(_file: FileAccess, path: String = "") -> bool:
    if _file == null:
        push_error("Failed to open file: %s\nError: %s" % [path, FileAccess.get_open_error()])
        return false
    return true


#region config files for settings ----------------------------------------

## Save data in readable config format. [Section] key=value. Loads existing data then overwrites any section in data
func save_config_data(data: Dictionary, save_file: String) -> void:
    var config2 = ConfigFile.new()
    for section in data:
        for key in data[section]:
            config2.set_value(section, key, data[section][key])
    config2.save(save_file)
    return
    # var existing = load_config_data(save_file)
    # # data["Test"] = {"test2": 5.0} # can do multiple sections
    # for section in data:
    #     if !existing.has(section):
    #         existing[section] = {}
    #     for key in data[section]:
    #         existing[section][key] = data[section][key]

    # var config = ConfigFile.new()
    # for section in existing: # ["section1": {}, "section2": {},]
    #     for key in existing[section]:
    #         config.set_value(section, key, existing[section][key])
    # config.save(save_file)


func load_config_data(save_file: String) -> Dictionary:
    print("Loading config data from: %s" % save_file)
    var loaded_data := {}
    _create_and_verify_file(save_file)
    var config := ConfigFile.new()
    var err := config.load(save_file)
    if err != OK:
        push_error("Failed to config load: %s" % save_file)
        return {}
    for section in config.get_sections():
        loaded_data[section] = {}
        for key in config.get_section_keys(section):
            loaded_data[section][key] = config.get_value(section, key)

    return loaded_data

## converts data into {section: {data}} format
func save_config_section(section: String, data: Dictionary, save_file: String) -> void:
    var new_data = {section: data}
    save_config_data(new_data, save_file)

## returns specific config section from file
func load_config_section(section: String, save_file: String) -> Dictionary:
    var existing := load_config_data(save_file)
    var result = existing.get(section, {})
    return result

#endregion


#region encoded as binary ----------------------------------------
#https://github.com/MorneVenter/godot-blueprint/blob/main/addons/blueprint/autoloads/save_manager.gd#L86

func update_save_data(_key: String, value: Variant, immediate_save: bool = false) -> void:
    if value == null:
        return
    saved_data[_key] = value
    if immediate_save:
        save_game_binary(get_save_path(0))

## Optionally, provide a default return value as the second parameter to assist with typed returns. Will return null by default.
func get_save_data_from(_key: String, default: Variant = null) -> Variant:
    if !saved_data.has(_key):
        return default
    var loaded: Variant = saved_data[_key]
    if loaded == null:
        return default
    return loaded

## Gets the last date and time the current loaded save file was written to.
## format (YYYY-MM-DDTHH:MM:SS)
func get_last_write_date() -> String:
    var date_and_time: String = get_save_data_from("save_date", "")
    return date_and_time


func get_last_save_version() -> String:
    var version: String = get_save_data_from("game_version", ProjectSettings.get_setting("application/config/version", "0.0"))
    return version


func save_game_binary(_file: String) -> void:
    saved_data["save_date"] = Time.get_datetime_string_from_system()
    saved_data["game_version"] = ProjectSettings.get_setting("application/config/version", "0.0")
    _save_groups()
    _save_as_encoded_file(saved_data, _file)
    print("Saved game to: %s" % _file)


func load_game_binary(_file: String) -> void:
    saved_data = _load_from_encoded_file(_file)
    if saved_data.get("game_version", "0.0") != ProjectSettings.get_setting("application/config/version", "0.0"):
        # migration logic
        pass
    _load_groups()


func _delete_save_data(id: int = 0) -> void:
    var save_path: String = get_save_path(id)
    OS.move_to_trash(ProjectSettings.globalize_path(save_path))
    print("deleted save file: %s" % save_path)


func append_save_as_encoded_file(data: Dictionary, _file: String) -> void:
    var save = _load_from_encoded_file(_file)
    for _section in data:
        if !save.has(_section):
            save[_section] = {}
        save[_section] = data[_section]
    # save.merge(data, true)
    _save_as_encoded_file(save, _file)

## file is encoded as bytes
func _save_as_encoded_file(data: Dictionary, _file: String) -> void:
    var file = FileAccess.open(_file, FileAccess.WRITE)
    file.store_var(data)
    file.close()

## file is decoded from bytes
func _load_from_encoded_file(_file: String) -> Dictionary:
    var options = {}
    if !_create_and_verify_file(_file): return options
    if FileAccess.get_size(_file) <= 0: return options

    var file = FileAccess.open(_file, FileAccess.READ)
    var contents = file.get_var()
    file.close()
    if contents == null or contents.is_empty(): return options
    if typeof(contents) == TYPE_DICTIONARY: return contents
    var err
    if typeof(contents) == TYPE_STRING:
        err = JSON.parse_string(contents)
    if err == null:
        print_debug("JSON parse error: ", err)
        return options
    push_warning("data is not a dictionary")
    return options


func _save_groups() -> void:
    get_tree().call_group(SAVE_GROUP, "_save_game_data", saved_data)

## for scripts that may be active before load game, add them to 'savable' & create function '_load_game_data'
func _load_groups() -> void:
    get_tree().call_group(SAVE_GROUP, "_load_game_data", saved_data)

#endregion


#region json files ----------------------------------------
## Save 'data' to 'save file' as JSON string
func save_file_as_json_unencrypted(data: Dictionary, save_file: String) -> void:
    var file = FileAccess.open(save_file, FileAccess.WRITE)
    if !_verify_file(file): return
    var json_string = JSON.stringify(data)
    file.store_string(json_string)
    file.close()

## Load 'save file' from JSON string
func load_file_from_json_unencrypted(save_file: String) -> Dictionary:
    if !_create_and_verify_file(save_file): return {}
    var file = FileAccess.open(save_file, FileAccess.READ)
    if !_verify_file(file): return {}
    var json_string = file.get_as_text()
    file.close()
    if json_string.is_empty():
        return {}
    var json := JSON.new()
    var err = json.parse(json_string)
    if err != OK:
        push_error("Parse Error: %s, in %s, at line %s " % [json.get_error_message(), json_string, json.get_error_line()])
        return {}
    return json.data

## Save 'data' to 'save file' as encrypted JSON
func save_file_as_json_encrypted(data: Dictionary, save_file: String) -> void:
    var file = FileAccess.open_encrypted(save_file, FileAccess.WRITE, ProjectSettings.get_setting("game/unlock_key"))
    if !_verify_file(file): return
    var json_string = JSON.stringify(data)
    file.store_string(json_string)
    file.close()

## Load 'save file' from encrypted JSON
func load_file_from_json_encrypted(save_file: String) -> Dictionary:
    var _file: FileAccess = null
    if !FileAccess.file_exists(save_file):
        print_debug("File did not exist: %s" % save_file)
        _file = FileAccess.open_encrypted(save_file, FileAccess.WRITE, ProjectSettings.get_setting("game/unlock_key"))
        if !_verify_file(_file): return {}
    if _file == null:
        _file = FileAccess.open_encrypted(save_file, FileAccess.READ, ProjectSettings.get_setting("game/unlock_key"))
        if !_verify_file(_file): return {}

    var json_string = _file.get_as_text()
    _file.close()
    if json_string.is_empty(): return {}
    var json := JSON.new()
    var err = json.parse(json_string)
    if err != OK:
        push_error("Parse Error: %s, in %s, at line %s " % [json.get_error_message(), json_string, json.get_error_line()])
        return {}
    return json.data

## Save 'data' to 'save file' as encrypted JSON with password
func save_file_as_json_with_password(data: Dictionary, save_file: String, password: String) -> void:
    var file = FileAccess.open_encrypted_with_pass(save_file, FileAccess.WRITE, password)
    if !_verify_file(file):
        return
    var json_string = JSON.stringify(data)
    file.store_string(json_string)
    file.close()

## Load 'save file' from encrypted JSON with password
func load_file_as_json_with_password(data: Dictionary, save_file: String, password: String) -> Dictionary:
    var _file: FileAccess = null
    if !FileAccess.file_exists(save_file):
        print_debug("File did not exist: %s" % save_file)
        _file = FileAccess.open_encrypted_with_pass(save_file, FileAccess.WRITE, password)
        if !_verify_file(_file): return {}
    if _file == null:
        _file = FileAccess.open_encrypted_with_pass(save_file, FileAccess.READ, password)
        if !_verify_file(_file): return {}

    var json_string = _file.get_as_text()
    _file.close()
    if json_string.is_empty(): return {}
    var json := JSON.new()
    var err = json.parse(json_string)
    if err != OK:
        push_error("Parse Error: %s, at line %s, in\n%s  " % [json.get_error_message(), json.get_error_line(), json_string])
        return {}
    return json.data

#endregion


#region Console ----------------------------------------

# func _add_cs_commands() -> void:
#     GameManager.console_manager.add_command("save_game", _cs_save_game, ["slot"], 0, "Save game")
#     GameManager.console_manager.add_command("delete_save", _cs_delete_save, ["slot"], 0, "Delete save")


# func _remove_cs_commands() -> void:
#     GameManager.console_manager.remove_command("save_game")
#     GameManager.console_manager.remove_command("delete_save")


# func _cs_save_game(_slot: String = "") -> void:
#     var slot = _slot.to_int()
#     if slot != 0:
#         slot = 0
#     save_game(slot)
#     GameManager.print_to_console("Saved game to slot %d" % slot)


# func _cs_delete_save(_slot: String = "") -> void:
#     var slot = _slot.to_int()
#     if slot != 0:
#         slot = 0
#     _delete_save_data(slot)
#     GameManager.print_to_console("Save slot deleted %d" % slot)

#endregion


# # For a save/load menu-----------------
# func update_save_menu() -> void:
#     var slots = SaveManager.get_all_save_slots_info()
#     for slot in slots:
#         print("Slot %d: %s" % [slot.slot, "Occupied" if slot.exists else "Empty"])
