extends Node
#AUTOLOAD

#--------------------------------------------#
# SET IN ANY NODE TO BE SAVED
# ADD NODES TO SAVE GROUP

# func get_save_data() -> Dictionary:
#     var save_data = {
#         "health": health # example
#     }
#     return save_data

# func load_save_data(data: Dictionary) -> void:
#     health = data["health"] # example
#     pass
#--------------------------------------------#

const SAVE_DIR = "user://saves/"
const CONFIG_DIR = "user://config/"
const OPTIONS_FILE: String = CONFIG_DIR + "options.cfg"
const SETTINGS_FILE: String = CONFIG_DIR + "settings.cfg"
const MAX_SLOTS = 3
# const JSON_SAVE_FILE: String = "user://saveDataJson.json"
# const BINARY_SAVE_FILE: String = "user://saveDataBinary.dat"
# const RESOURCE_SAVE_FILE: String = "user://saveDataResource.res"

const KEY_PATH = "user://unlock.bin"
const SAVE_GROUP = "savable"

signal save_settings_data

var settings_dict: Dictionary = {}

# const KEY_RESOURCE_PATH = "res://Utility/unlock_key.tres"
# var encryption_key: PackedByteArray


func _ready() -> void:
    if !DirAccess.dir_exists_absolute(SAVE_DIR):
        DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    if !DirAccess.dir_exists_absolute(CONFIG_DIR):
        DirAccess.make_dir_recursive_absolute(CONFIG_DIR)

    _load_or_generate_key()
    load_config_data() # TODO
    # SettingsManager.init()
    KeybindManager.init()


func _load_or_generate_key() -> void:
    if !ProjectSettings.has_setting("game/unlock_key"):
        var crypto := Crypto.new()
        var new_key := crypto.generate_random_bytes(32)
        ProjectSettings.set_setting("game/unlock_key", new_key)

    # var key: UnlockKey = load(KEY_RESOURCE_PATH)
    # if key.encryption_key.is_empty():
    #     print("Generating new key")
    #     var crypto := Crypto.new()
    #     var new_key := crypto.generate_random_bytes(32)
    #     key.encryption_key = new_key
    #     ResourceSaver.save(key, KEY_RESOURCE_PATH)
    #     ProjectSettings.set_setting("game/unlock_key", new_key)
    #     print_debug(key.resource_path)

    ######
    # if FileAccess.file_exists(KEY_PATH):
    #     var file1 = FileAccess.open(KEY_PATH, FileAccess.READ)
    #     if file1:
    #         var key = file1.get_buffer(32)
    #         file1.close()
    #         return key

    # # Generate new key if none exists
    # var crypto = Crypto.new()
    # var new_key = crypto.generate_random_bytes(32)

    # var file = FileAccess.open(KEY_PATH, FileAccess.WRITE)
    # if file:
    #     file.store_buffer(new_key)
    #     file.close()

    # return new_key


func get_save_path(slot: int) -> String:
    assert(slot >= 0 and slot < MAX_SLOTS, "invalid save slot")
    return SAVE_DIR + "save_slot_%d.dat" % slot


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


func _verify_file(_file: FileAccess) -> bool:
    if _file == null:
        push_error("Failed to open file: %s" % FileAccess.get_open_error())
        return false
    return true


#region game saves encrypted TODO----------------------------------------
func save_game_encrypted_json(slot: int) -> bool:
    assert(slot >= 0 and slot < MAX_SLOTS, "invalid save slot")
    var save_data = {}
    var savable_nodes = get_tree().get_nodes_in_group(SAVE_GROUP)
    # Store each node's data with its scene tree path as key
    for node in savable_nodes:
        if !node.has_method("get_save_data"):
            push_error("Node %s does not have a get_save_data method." % node.get_path())
            continue
        save_data[node.get_path()] = {
            "class": node.get_class(),
            "data": node.get_save_data()
        }

    var json_string = JSON.stringify(save_data, "  ", true)
    var file = FileAccess.open_encrypted(
        get_save_path(slot),
        FileAccess.WRITE,
        ProjectSettings.get_setting("game/unlock_key")
    )

    if file:
        file.store_string(json_string)
        file.close()
        print("Game saved to slot %d" % slot)
        return true
    else:
        print("Failed to save game to slot %d" % slot)
        return false


func load_game_encrypted_json(slot: int) -> bool:
    assert(slot >= 0 and slot < MAX_SLOTS, "invalid save slot")
    var save_path = get_save_path(slot)

    if !FileAccess.file_exists(save_path):
        print_debug("No save file found in slot %d" % slot)
        return false

    var file = FileAccess.open_encrypted(
        save_path,
        FileAccess.READ,
        ProjectSettings.get_setting("game/unlock_key")
    )

    if not file:
        print_debug("Failed to load save file from slot %d" % slot)
        return false

    var json_string = file.get_as_text()
    file.close()

    var json = JSON.new()
    var parse_result = json.parse(json_string)

    if parse_result != OK:
        print("Error parsing save file: ", json.get_error_message())
        return false

    var save_data = json.data

    for node_path in save_data.keys():
        var node = get_node_or_null(node_path)
        if node and node.is_in_group(SAVE_GROUP):
            node.load_save_data(save_data[node_path]["data"])

    print("Game loaded from slot %d successfully" % slot)
    return true
#endregion


#region game saves unencrypted TODO----------------------------------------
func save_game_unencrypted_json(slot: int) -> void:
    assert(slot >= 0 and slot < MAX_SLOTS, "invalid save slot")
    var save_data = {}
    var savable_nodes = get_tree().get_nodes_in_group(SAVE_GROUP)
    for node in savable_nodes:
        if !node.has_method("get_save_data"):
            continue
        save_data[node.get_path()] = {
            "class": node.get_class(),
            "data": node.get_save_data()
        }

    var json_string = JSON.stringify(save_data, "  ", true)

    # Write to file
    var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()
        print("Game saved to slot %d" % slot)
    else:
        print("Failed to save game to slot %d" % slot)


func load_game_unencrypted_json(slot: int) -> void:
    assert(slot >= 0 and slot < MAX_SLOTS, "invalid save slot")
    var save_path = get_save_path(slot)

    if !FileAccess.file_exists(save_path):
        print("No save file found in slot %d" % slot)
        return

    var file = FileAccess.open(save_path, FileAccess.READ)
    if not file:
        print("Failed to load save file from slot %d" % slot)
        return

    var json_string = file.get_as_text()
    file.close()

    var json = JSON.new()
    var parse_result = json.parse(json_string)

    if parse_result != OK:
        print("Error parsing save file: ", json.get_error_message())
        return

    var save_data = json.data

    for node_path in save_data.keys():
        var node = get_node_or_null(node_path)
        if !node.has_method("load_save_data"):
            continue
        if node and node.is_in_group(SAVE_GROUP):
            node.load_save_data(save_data[node_path]["data"])

    print("Game loaded from slot %d successfully" % slot)
#endregion


#region config files for settings ----------------------------------------
## Specify a file to save. File will only contain 'data' & overwrite any existing data
func save_as_config_in_file(section: String, data: Dictionary, save_file: String) -> void:
    var config := ConfigFile.new()
    for key in data:
        config.set_value(section, key, data[key])
    config.save(save_file)

## Loads the config 'section' data from 'save file'
func load_from_config_in_file(section: String, save_file: String) -> Dictionary:
    _create_and_verify_file(save_file)

    var config := ConfigFile.new()
    var err := config.load(save_file)
    if err != OK:
        push_error("Failed to config load: %s" % save_file)
        return {}
    var result := {}
    if config.has_section(section):
        for i in config.get_section_keys(section):
            result[i] = config.get_value(section, i)
    return result

## This func adds data to section in settings_dict, intended if saving all data in 1 file. Requires all data to be in settings_dict otherwise it gets erased
func save_as_config(section: String, data: Dictionary, save_file: String) -> void:
    var config = ConfigFile.new()
    settings_dict[section] = data
    for _section in settings_dict:
        for key in settings_dict[_section]:
            config.set_value(_section, key, settings_dict[_section][key])
    config.save(save_file)

## loads all sections to settings_dict & returns section data
func load_from_config(section: String, save_file: String) -> Dictionary:
    _create_and_verify_file(save_file)

    var config = ConfigFile.new()
    var err = config.load(save_file)
    if err != OK:
        return {}
    var result := {}
    for _section in config.get_sections():
        for i in config.get_section_keys(section):
            result[i] = config.get_value(section, i)
        settings_dict[section] = result
    return result


func save_config_data() -> void:
    # sends signal that managers will put data into settings dict
    save_settings_data.emit() # TODO-2 manager send data to settings dict
    print_debug("Saved config data:\n%s\n" % settings_dict)
    var config = ConfigFile.new()
    for section in settings_dict:
        for key in settings_dict[section]:
            config.set_value(section, key, settings_dict[section][key])

    config.save(CONFIG_DIR + "test.cfg")


func load_config_data() -> void:
    var path = CONFIG_DIR + "test.cfg"
    _create_and_verify_file(path)
    var config := ConfigFile.new()
    var err := config.load(path)
    if err != OK:
        push_error("Failed to config load: %s" % path)
        return
    for section in config.get_sections():
        if !settings_dict.has(section):
            settings_dict[section] = {}
        for key in config.get_section_keys(section):
            settings_dict[section][key] = config.get_value(section, key)

    print_debug(SettingsManager.settings)


#endregion


#region json files ----------------------------------------
## Save 'data' to 'save file' as unencrypted JSON
func save_file_as_json_unencrypted(data: Dictionary, save_file: String) -> void:
    var file = FileAccess.open(save_file, FileAccess.WRITE)
    if !_verify_file(file):
        return
    var json_string = JSON.stringify(data)
    file.store_string(json_string)
    file.close()

## Load 'save file' from unencrypted JSON
func load_file_from_json_unencrypted(save_file: String) -> Dictionary:
    if !FileAccess.file_exists(save_file):
        print_debug("File did not exist: %s" % save_file)
        var _file = FileAccess.open(save_file, FileAccess.WRITE)
        if !_verify_file(_file):
            return {}
        _file.close()

    var file = FileAccess.open(save_file, FileAccess.READ)
    if !_verify_file(file):
        return {}

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
    # alternate file scans
    # while file.eof_reached():
    #     pass
    # while file.get_position() < file.get_length():
    #     var json_string := file.get_line()

## Save 'data' to 'save file' as encrypted JSON
func save_file_as_json_encrypted(data: Dictionary, save_file: String) -> void:
    var file = FileAccess.open_encrypted(save_file, FileAccess.WRITE, ProjectSettings.get_setting("game/unlock_key"))
    if !_verify_file(file):
        return
    var json_string = JSON.stringify(data)
    file.store_string(json_string)
    file.close()

## Load 'save file' from encrypted JSON
func load_file_from_json_encrypted(save_file: String) -> Dictionary:
    var result := {}
    if !FileAccess.file_exists(save_file):
        print_debug("File did not exist: %s" % save_file)
        var _file = FileAccess.open_encrypted(save_file, FileAccess.WRITE, ProjectSettings.get_setting("game/unlock_key"))
        if !_verify_file(_file):
            return {}
        _file.close()

    var file = FileAccess.open_encrypted(save_file, FileAccess.READ, ProjectSettings.get_setting("game/unlock_key"))
    if !_verify_file(file):
        return {}
    var json_string = file.get_as_text()
    file.close()
    if json_string.is_empty():
        return {}
    var json := JSON.new()
    var err = json.parse(json_string)
    if err != OK:
        push_error("Parse Error: %s, in %s, at line %s " % [json.get_error_message(), json_string, json.get_error_line()])
        return {}

    result = json.data
    return result

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
    var file = FileAccess.open_encrypted_with_pass(save_file, FileAccess.READ, password)
    if _verify_file(file):
        return {}
    var json_string = file.get_as_text()
    file.close()
    if json_string.is_empty():
        return {}
    var json := JSON.new()
    var err = json.parse(json_string)
    if err != OK:
        push_error("Parse Error: %s, at line %s, in\n%s  " % [json.get_error_message(), json.get_error_line(), json_string])
        return {}

    return json.data

#endregion

## if save file does not exist, create it
func _create_and_verify_file(save_file: String) -> bool:
    if FileAccess.file_exists(save_file):
        return true
    var file = FileAccess.open(save_file, FileAccess.WRITE)
    if !_verify_file(file):
        return false
    file.close()
    return true

#region encoded as binary ----------------------------------------
##TODO work is needed for decoding.
## file is encoded
# func save_as_encoded_file(data: Variant, _file: String) -> void:
#     var file = FileAccess.open(_file, FileAccess.WRITE)
#     if file:
#         file.store_var(data)
#         file.close()

# ## file is decoded
# func load_from_encoded_file(_file: String) -> Dictionary:
#     var options = {}
#     var file = FileAccess.open(_file, FileAccess.READ)
#     if file:
#         options = file.get_var()
#     else:
#         save_as_encoded_file(options, _file)
#         options = load_from_encoded_file(_file)
#     file.close()
#     return options
#endregion


#region example usage ----------------------------------------
#   # saving in slot-----------------
# func _input(event: InputEvent) -> void:
#     if event.is_action_pressed("debug1"):
#         var slot = 0
#         if Input.is_key_pressed(KEY_SHIFT):
#             slot = 0
#         elif Input.is_key_pressed(KEY_CTRL):
#             slot = 1
#         elif Input.is_key_pressed(KEY_ALT):
#             slot = 2
#         save_game_encrypted_json(slot)

#     if event.is_action_pressed("debug2"):
#         var slot = 0
#         if Input.is_key_pressed(KEY_SHIFT):
#             slot = 0
#         elif Input.is_key_pressed(KEY_CTRL):
#             slot = 1
#         elif Input.is_key_pressed(KEY_ALT):
#             slot = 2
#         load_game_encrypted_json(slot)

#   # in another script-----------------
# func save_to_slot(slot: int) -> void:
#     if SaveManager.save_game(slot):
#         print("Saved successfully!")
#     else:
#         print("Save failed!")

# func load_from_slot(slot: int) -> void:
#     if SaveManager.load_game(slot):
#         print("Loaded successfully!")
#     else:
#         print("Load failed!")

# # For a save/load menu-----------------
# func update_save_menu() -> void:
#     var slots = SaveManager.get_all_save_slots_info()
#     for slot in slots:
#         print("Slot %d: %s" % [slot.slot, "Occupied" if slot.exists else "Empty"])
#endregion
