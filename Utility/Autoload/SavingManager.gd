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

const CONFIG_SAVE_FILE: String = "user://settings.ini"
const OPTIONS_FILE: String = "user://options.cfg"
const SAVE_DIR = "user://saves/"
const MAX_SLOTS = 3
# const JSON_SAVE_FILE: String = "user://saveDataJson.json"
# const BINARY_SAVE_FILE: String = "user://saveDataBinary.dat"
# const RESOURCE_SAVE_FILE: String = "user://saveDataResource.res"

const KEY_PATH = "user://encryption_key.bin"
const SAVE_GROUP = "savable"


var encryption_key: PackedByteArray


func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    encryption_key = _load_or_generate_key()


func _load_or_generate_key() -> PackedByteArray:
    if FileAccess.file_exists(KEY_PATH):
        var file1 = FileAccess.open(KEY_PATH, FileAccess.READ)
        if file1:
            var key = file1.get_buffer(32)
            file1.close()
            return key
    
    # Generate new key if none exists
    var crypto = Crypto.new()
    var new_key = crypto.generate_random_bytes(32)
    
    var file = FileAccess.open(KEY_PATH, FileAccess.WRITE)
    if file:
        file.store_buffer(new_key)
        file.close()
    
    return new_key


func get_save_path(slot: int) -> String:
    assert(slot >= 0 and slot < MAX_SLOTS, "invalid save slot")
    return SAVE_DIR + "save_slot_%d.dat" % slot


#region encrypted
func save_game_encrypted(slot: int) -> bool:
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
        encryption_key
    )

    if file:
        file.store_string(json_string)
        file.close()
        print("Game saved to slot %d" % slot)
        return true
    else:
        print("Failed to save game to slot %d" % slot)
        return false


func load_game_encrypted(slot: int) -> bool:
    assert(slot >= 0 and slot < MAX_SLOTS, "invalid save slot")
    var save_path = get_save_path(slot)

    if !FileAccess.file_exists(save_path):
        print("No save file found in slot %d" % slot)
        return false

    var file = FileAccess.open_encrypted(
        save_path,
        FileAccess.READ,
        encryption_key
    )

    if not file:
        print("Failed to load save file from slot %d" % slot)
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
#endregion-------------------------------------------------------


#region unencrypted
func save_game_unencrypted(slot: int) -> void:
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


func load_game_unencrypted(slot: int) -> void:
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
#endregion------------------------------------------------------


#region settings as config-----------------------------------------
## file editable
func save_as_config(section: String, data: Dictionary) -> void:
    var config = ConfigFile.new()
    for key in data:
        config.set_value(section, key, data[key])
    config.save(CONFIG_SAVE_FILE)

## file editable
func load_from_config(section: String) -> Dictionary:
    var config = ConfigFile.new()
    var err = config.load(CONFIG_SAVE_FILE)
    if err == OK:
        var result := {}
        for i in config.get_section_keys(section):
            result[i] = config.get_value(section, i)
        return result
    else:
        return {}
#endregion-------------------------------------------------------

#region encoded
## file is decoded
func read_options() -> Dictionary:
    var options = {}
    var file = FileAccess.open(OPTIONS_FILE, FileAccess.READ)
    if file:
        options = file.get_var()
        file.close()
    else:
        write_options("Settings", SettingsManager.DEFAULT_SETTINGS)
        options = read_options()
    return options

## file is encoded
func write_options(_section: String, options: Dictionary):
    var file = FileAccess.open(OPTIONS_FILE, FileAccess.WRITE)
    if file:
        file.store_var(options)
        file.close()
#endregion------------------------------------------------------


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

#region example usage
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
#         save_game_encrypted(slot)
    
#     if event.is_action_pressed("debug2"):
#         var slot = 0
#         if Input.is_key_pressed(KEY_SHIFT):
#             slot = 0
#         elif Input.is_key_pressed(KEY_CTRL):
#             slot = 1
#         elif Input.is_key_pressed(KEY_ALT):
#             slot = 2
#         load_game_encrypted(slot)

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
#endregion----------------------------------------------------------------------------------

#region other type references
    #region json
# static func save_as_json(data: Dictionary) -> void:
#     var file = FileAccess.open(JSON_SAVE_FILE, FileAccess.WRITE)
#     var json_string = JSON.stringify(data)
#     file.store_line(json_string)
#     file.close()

# static func load_from_json() -> Dictionary:
#     if !FileAccess.file_exists(JSON_SAVE_FILE):
#         return {}
#     # free all nodes that get saved

#     var file = FileAccess.open(JSON_SAVE_FILE, FileAccess.READ)
#     var json_string = file.get_line()
#     file.close()
#     var result = JSON.parse_string(json_string)
#     return result
    #endregion

    #region binary
# static func save_as_binary(data: Dictionary) -> void:
#     var file = FileAccess.open(BINARY_SAVE_FILE, FileAccess.WRITE)
#     file.store_var(data)
#     file.close()

# static func load_from_binary() -> Dictionary:
#     var file = FileAccess.open(BINARY_SAVE_FILE, FileAccess.READ)
#     var result = file.get_var()
#     file.close()
#     return result
    #endregion

    #region resource
# static func save_as_resource(data: Resource) -> void:
#     ResourceSaver.save(data, RESOURCE_SAVE_FILE)

# static func load_from_resource() -> Resource:
#     if ResourceLoader.exists(RESOURCE_SAVE_FILE):
#         return ResourceLoader.load(RESOURCE_SAVE_FILE)
#     return null
    #endregion
#endregion----------------------------------------------------------------------------------
