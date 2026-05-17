@icon("res://Assets/Packs/Kenney/Game Icons/gear.png")
extends Node
#AUTOLOAD

#region old
# signal language_changed(new_locale: String)

# const DEFAULT_SETTINGS: Dictionary = {
#     Strings.FULLSCREEN: false,
#     Strings.MAXIMIZED: false,
#     Strings.WIDTH: 1280,
#     Strings.HEIGHT: 720,
#     Strings.SCALER_MODE: 1,
#     Strings.SCALER_VALUE: 100.0,
#     Strings.FSR_SELECTED: 1,
#     Strings.BRIGHTNESS: 1.0,
#     Strings.VSYNC: true,
#     Strings.LOCALE: "en",
#     }

# const DEFAULT_AUDIO: Dictionary = {
#     Strings.MUTE: false,
#     Strings.MASTER_VOLUME: 0.5,
#     Strings.MUSIC_VOLUME: 0.5,
#     Strings.SFX_VOLUME: 0.5,
# }

# const RESOLUTIONS: Array = [
#     {Strings.WIDTH: 1920, Strings.HEIGHT: 1080},
#     {Strings.WIDTH: 1600, Strings.HEIGHT: 900},
#     {Strings.WIDTH: 1440, Strings.HEIGHT: 900},
#     {Strings.WIDTH: 1366, Strings.HEIGHT: 768},
#     {Strings.WIDTH: 1280, Strings.HEIGHT: 1024},
#     {Strings.WIDTH: 1280, Strings.HEIGHT: 720},
#     {Strings.WIDTH: 800, Strings.HEIGHT: 600},
#     # {Strings.WIDTH: 2560, Strings.HEIGHT: 1440},
#     # {Strings.WIDTH: 3840, Strings.HEIGHT: 2160},
# ]

# var DEFAULT_RESOLUTION: Vector2i = Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))

# var player_fullscreen_size: Vector2i
# var player_windowed_size: Vector2i

# var locale_list = [
#     {Strings.LOCALE: "en", "language": "English", "flag": "res://Assets/Icons/Flags/us.png"},
#     {Strings.LOCALE: "zh", "language": "中国人", "flag": "res://Assets/Icons/Flags/cn.png"},
#     {Strings.LOCALE: "ru", "language": "Русский", "flag": "res://Assets/Icons/Flags/ru.png"},
#     # {Strings.LOCALE: "es", "language": "Español", "flag": "res://Assets/Icons/Flags/es.png"},
#     # {Strings.LOCALE: "pt", "language": "Português", "flag": "res://Assets/Icons/Flags/pt.png"},
#     # {Strings.LOCALE: "de", "language": "Deutsch", "flag": "res://Assets/Icons/Flags/de.png"},
#     # {Strings.LOCALE: "ja", "language": "日本語", "flag": "res://Assets/Icons/Flags/jp.png"},
# ]

# # var keybind_manager: KeybindManager = preload("res://Menu/Keybinds/KeybindManager.gd").new()
# var settings: Dictionary
# ## If the game has already loaded, options should only need to set values visually
# var settings_loaded: bool = false


# func init():
#     player_fullscreen_size = DisplayServer.screen_get_size()
#     player_windowed_size = DisplayServer.screen_get_usable_rect().size


# func _ready():
#     init()
#     load_settings()
#     apply_values()
#     save_settings.call_deferred()


# func check_option_settings(options: Dictionary) -> Dictionary:
#     var _options = options
#     for key in DEFAULT_SETTINGS.keys():
#         if !_options.has(key):
#             _options[key] = DEFAULT_SETTINGS[key]
#             continue
#         if typeof(_options[key]) != typeof(DEFAULT_SETTINGS[key]):
#             push_warning("Setting %s has been reset to %s" % [key, DEFAULT_SETTINGS[key]])
#             _options[key] = DEFAULT_SETTINGS[key]
#         continue
#     return _options


# func save_settings() -> void:
#     SavingManager.save_config_data(settings, SavingManager.SETTINGS_FILE)

# ## Sets loaded config data to settings variable
# func load_settings() -> void:
#     var data = SavingManager.load_config_data(SavingManager.SETTINGS_FILE)
#     if data.is_empty() or !data.has(Strings.SETTINGS):
#         data[Strings.SETTINGS] = DEFAULT_SETTINGS.duplicate()
#     if !data.has(Strings.AUDIO):
#         data[Strings.AUDIO] = DEFAULT_AUDIO.duplicate()
#     settings = data

# ## apply saved settings to game on startup
# func apply_values() -> void:
#     assert(settings.has(Strings.SETTINGS))
#     var _settings = settings[Strings.SETTINGS]
#     set_window_mode()
#     set_resolution(get_resolution_index())
#     # set_resolution_by_value(_settings[Strings.WIDTH], _settings[Strings.HEIGHT])
#     set_scaler_mode(_settings[Strings.SCALER_MODE])
#     set_scaler_value(_settings[Strings.SCALER_VALUE])
#     set_fsr_index(_settings[Strings.FSR_SELECTED])
#     set_language(get_language_index())
#     set_brightness(_settings[Strings.BRIGHTNESS])
#     set_vsync(_settings[Strings.VSYNC])
#     settings_loaded = true


# func set_save_setting(section: String, key: String, value: Variant) -> void:
#     if !settings.has(section):
#         settings[section] = {}
#     settings[section][key] = value

# #region Resolution---------------------------------

# func set_window_mode() -> void:
#     var _settings = settings[Strings.SETTINGS]
#     var window_mode = DisplayServer.WINDOW_MODE_WINDOWED
#     if _settings[Strings.FULLSCREEN] == true:
#         window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
#     elif _settings[Strings.MAXIMIZED] == true:
#         window_mode = DisplayServer.WINDOW_MODE_MAXIMIZED
#     DisplayServer.window_set_mode(window_mode)
#     resize_window()


# func set_resolution(index: int) -> void:
#     var idx = clampi(index, 0, RESOLUTIONS.size() - 1)
#     var size = RESOLUTIONS[idx]
#     set_save_setting(Strings.SETTINGS, Strings.WIDTH, size[Strings.WIDTH])
#     set_save_setting(Strings.SETTINGS, Strings.HEIGHT, size[Strings.HEIGHT])
#     resize_window()

# ## this can be used to set a custom resolution not in RESOLUTIONS array
# func set_resolution_by_value(width: int, height: int) -> void:
#     set_save_setting(Strings.SETTINGS, Strings.WIDTH, width)
#     set_save_setting(Strings.SETTINGS, Strings.HEIGHT, height)
#     resize_window()


# func resize_window() -> void:
#     var _settings = settings[Strings.SETTINGS]
#     if _settings[Strings.FULLSCREEN] == true or _settings[Strings.MAXIMIZED] == true:
#         return
#     var window_size = Vector2i(_settings[Strings.WIDTH], _settings[Strings.HEIGHT])
#     # scales the game window
#     get_tree().root.size = window_size
#     # scales the content within the window
#     # get_tree().root.content_scale_size = window_size
#     center_window(false)


# func center_window(do_center: bool = true) -> void:
#     var _settings = settings[Strings.SETTINGS]
#     if _settings[Strings.FULLSCREEN] == true or _settings[Strings.MAXIMIZED] == true or !do_center:
#         return
#     var window_size = Vector2i(_settings[Strings.WIDTH], _settings[Strings.HEIGHT])
#     var current_monitor = DisplayServer.get_keyboard_focus_screen()
#     var screen_size := DisplayServer.screen_get_size(current_monitor)
#     var screen_pos := DisplayServer.screen_get_position(current_monitor)
#     var x = (screen_size.x - window_size.x) / 2
#     var y = (screen_size.y - window_size.y) / 2
#     get_tree().root.position = Vector2i(screen_pos.x + x, screen_pos.y + y)

# ## get index of current resolution in RESOLUTIONS array. Defaults to 5(1280x720) if not found
# func get_resolution_index() -> int:
#     var _settings = settings[Strings.SETTINGS]
#     var idx := RESOLUTIONS.find({Strings.WIDTH: _settings[Strings.WIDTH], Strings.HEIGHT: _settings[Strings.HEIGHT]})
#     if idx == -1:
#         idx = RESOLUTIONS.find({Strings.WIDTH: 1280, Strings.HEIGHT: 720})
#     return idx


# #endregion

# #region Quality---------------------------------

# func set_scaler_mode(index: int) -> void:
#     var _settings = settings[Strings.SETTINGS]
#     var viewport = get_viewport()
#     if ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
#         viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
#     else:
#         viewport.scaling_3d_mode = _settings[Strings.SCALER_MODE]
#     set_save_setting(Strings.SETTINGS, Strings.SCALER_MODE, index)


# func set_scaler_value(value: float) -> void:
#     var _settings = settings[Strings.SETTINGS]
#     var viewport = get_viewport()
#     var resolution_scale = _settings[Strings.SCALER_VALUE] / 100.00
#     viewport.scaling_3d_scale = resolution_scale
#     set_save_setting(Strings.SETTINGS, Strings.SCALER_VALUE, value)


# func set_fsr_index(index: int) -> void:
#     set_save_setting(Strings.SETTINGS, Strings.FSR_SELECTED, index)

# #endregion


# #region Other---------------------------------

# func set_brightness(value: float) -> void:
#     value = clampf(value, 0.5, 2.0)
#     #if GameManager.get("environment_res") != null:
#         #GameManager.environment_res.adjustment_brightness = value
#     set_save_setting(Strings.SETTINGS, Strings.BRIGHTNESS, value)


# func set_vsync(value: bool) -> void:
#     if value:
#         DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
#     else:
#         DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
#     set_save_setting(Strings.SETTINGS, Strings.VSYNC, value)


# func set_language(index: int) -> void:
#     index = clampi(index, 0, locale_list.size() - 1)
#     var locale = locale_list[index][Strings.LOCALE]
#     TranslationServer.set_locale(locale)
#     language_changed.emit(locale)
#     set_save_setting(Strings.SETTINGS, Strings.LOCALE, locale)


# func set_language_by_locale(locale: String) -> void:
#     var index = get_language_index_by_locale(locale)
#     set_language(index)


# func get_language_index() -> int:
#     var idx: int = 0
#     for locale: Dictionary in locale_list:
#         if locale[Strings.LOCALE] == settings[Strings.SETTINGS][Strings.LOCALE]:
#             idx = locale_list.find(locale)
#             break
#     return idx


# func get_language_index_by_locale(_locale: String) -> int:
#     var idx: int = 0
#     for locale: Dictionary in locale_list:
#         if locale[Strings.LOCALE] == _locale:
#             idx = locale_list.find(locale)
#             break
#     return idx

# ##NYI
# func set_max_fps(value: int) -> void:
#     Engine.max_fps = value
#     settings[Strings.SETTINGS][Strings.MAX_FPS] = value

# #endregion
#endregion


##AUTOLOAD Handles game options data
##
##Option data can be saved with [method save_settings] & loaded with [method load_settings]
##[br]Data from sections can be retrieved with [method get_section_settings]. Specific values can be retrieved with [method get_setting_from]
##[br]Values can be set or changed with [method update_setting_for]
##[br]Data is saved as [member settings_data](section)(key) = value
##[br]Load order:
    ##[br]1. [method load_settings] deferred.
    ##[br]2. create temp settings menu if [SettingsSection] dont exist yet. 
    ##[br]3. [SettingsOption] adds to refs in owner section. 
    ##[br]4. [SettingsSection] adds to refs in Manager.
    ##[br]5. [method SettingsSection.load_settings] deferred if empty
    ##[br]6. [SettingsMenu] call [signal retrieve_settings] deferred with opposite value of [member initial_game_start_settings_applied].
    ##[br]7. [SettingsOption] loads data from [SettingsManager] or uses default
    ##[br]8. [SettingsSection] load cache from [member SettingsManager.settings_data]
    ##[br]9. [method SettingsOption._apply_settings]

## from settings menu ready
@warning_ignore("unused_signal")
signal retrieve_settings(apply_values: bool)
@warning_ignore("unused_signal")
signal language_changed(new_locale: String)

const FPS_DISPLAY: String = "uid://dv16lqdwbd1nh"
const SETTINGS_MENU: String = "uid://qw8e7sxo35s"
const LANGUAGES: Dictionary = {
        "en": {
            "language": "English",
            "flag": "res://Assets/Icons/Flags/us.png",
        },
        "zh": {
            "language": "中国人",
            "flag": "res://Assets/Icons/Flags/cn.png",
        },
        "ru": {
            "language": "Русский",
            "flag": "res://Assets/Icons/Flags/ru.png",
        },
        "es": {
            "language": "Español",
            "flag": "res://Assets/Icons/Flags/es.png",
        },
        "pt": {
            "language": "Português",
            "flag": "res://Assets/Icons/Flags/pt.png",
        },
        "de": {
            "language": "Deutsch",
            "flag": "res://Assets/Icons/Flags/de.png",
        },
        "ja": {
            "language": "日本語",
            "flag": "res://Assets/Icons/Flags/jp.png",
        },
        # "English": "en",
    }

var folder: String = OS.get_user_data_dir()
var file: String = "settings"
var extension: String = ".cfg"
var path: String = folder + "/" + file + extension

var settings_data: Dictionary

## each section type: graphics, audio, control,
var sections_ref: Dictionary

var no_save_file: bool = false
var invalid_save_file: bool = false
var changed_elements_count: int = 0
## If the loaded data has been applied already. Set from [SettingsMenu]
var initial_game_start_settings_applied: bool = false

var temp_settings_menu: Control
var is_saving: bool = false

var fps_display: CanvasLayer


func _ready():
    create_directory_and_load()


func create_directory_and_load() -> void:
    DirAccess.make_dir_absolute(folder)
    if FileAccess.file_exists(path):
        load_settings.call_deferred()
        no_save_file = false
    else:
        no_save_file = true
        print("Settings file not found: %s" % path)


func save_settings() -> void:
    if is_saving: return
    is_saving = true
    var config := ConfigFile.new()
    for section in settings_data:
        for element: String in settings_data[section]:
            config.set_value(section, element, settings_data[section][element])
    var err := config.save(path)
    if err != OK:
        push_error("Failed to config save: %s" % path)
        return
    no_save_file = false
    invalid_save_file = false
    set_deferred("is_saving", false)
    print("saved settings")


func load_settings() -> void:
    var config := ConfigFile.new()
    var err := config.load(path)
    if err != OK:
        push_error("Failed to config load: %s" % path)
        return
    var data: Dictionary = {}
    for section in config.get_sections():
        data[section] = {}
        for key in config.get_section_keys(section):
            data[section][key] = config.get_value(section, key)
    verify_settings_data(data)
    settings_data = data.duplicate(true)
    if temp_settings_menu:
        temp_settings_menu.queue_free()


func update_setting_section(section: String, data: Dictionary) -> void:
    settings_data[section] = data


func update_setting_for(section: String, element: String, value: Variant) -> void:
    settings_data[section][element] = value


func get_section_settings(section: String) -> Dictionary:
    return settings_data.get(section, {})


func get_setting_from(section: String, element: String) -> Variant:
    if !settings_data.has(section): return null
    var value: Variant = settings_data[section].get(element, null)
    return value


func toggle_fps_display(show: bool) -> void: # keep
    if show:
        if fps_display:
            fps_display.show()
            return
        await get_tree().process_frame
        # fps_display = load(FPS_DISPLAY).instantiate()
        # UILayers.add(fps_display, UILayers.Layers.MENU_OVERLAY)
        return
    if fps_display:
        fps_display.hide()


#region validate data


func verify_settings_data(_data: Dictionary) -> void:
    print("\ndata file: ", _data)
    var sections := sections_ref.duplicate()
    if sections.size() == 0:
        print("creating temp settings menu")
        var scene: PackedScene = load("uid://qw8e7sxo35s")
        temp_settings_menu = scene.instantiate()
        temp_settings_menu.hide()
        add_child(temp_settings_menu)
        sections = sections_ref.duplicate()
    var invalid_entries: Dictionary = {}
    for section in _data:
        if is_valid_section(invalid_entries, section):
            verify_elements(invalid_entries, _data, section)
    check_for_missing_sections(_data, sections)
    if invalid_entries.size() > 0:
        remove_invalid_entries(_data, invalid_entries, sections)
        invalid_save_file = true
    print("validated data: ", _data, "\n")


func is_valid_section(invalid_entries: Dictionary, _section: String) -> bool:
    if sections_ref.has(_section):
        return true
    # Add the invalid section to the invalid entries list
    invalid_entries[_section] = []
    push_warning("Invalid section '", _section, "' found.")
    return false


func verify_elements(invalid_entries: Dictionary, _data: Dictionary, _section: String) -> void:
    var valid_elements: Array = get_valid_elements(_section)
    for element in _data[_section]:
        if valid_elements.has(element): continue
        if not invalid_entries.has(_section):
            invalid_entries[_section] = []
        invalid_entries[_section].append(element)
        push_warning("Invalid element '" + element + "' found in section '" + _section + "'.")


func get_valid_elements(_section: String) -> Array:
    if sections_ref.has(_section):
        return sections_ref[_section].option_elements.keys()
    # if ELEMENT_PANEL_REFERENCE_TABLE_.has(_section):
    #     return ELEMENT_PANEL_REFERENCE_TABLE_[_section].ELEMENT_REFERENCE_TABLE_.keys()
    return []


func check_for_missing_sections(_data: Dictionary, valid_entries: Dictionary) -> void:
    for section in valid_entries:
        if _data.has(section): continue
        _data[section] = {}
        invalid_save_file = true
        push_warning("Settings section is missing: ", section)


func remove_invalid_entries(_data: Dictionary, invalid_entries: Dictionary, valid_entries: Dictionary) -> void:
    for section in invalid_entries:
        if valid_entries.has(section):
            for element in invalid_entries[section]:
                _data[section].erase(element)
        else:
            _data.erase(section)

#endregion
