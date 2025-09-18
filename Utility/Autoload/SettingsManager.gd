extends Node
#AUTOLOAD


const DEFAULT_SETTINGS: Dictionary = {
    Strings.FULLSCREEN: false,
    Strings.MAXIMIZED: false,
    Strings.WIDTH: 1280,
    Strings.HEIGHT: 720,
    Strings.LOCALE: "en",
    Strings.SCALER_MODE: 1,
    Strings.SCALER_VALUE: 100.0,
    Strings.FSR_SELECTED: 1,
    Strings.BRIGHTNESS: 1.0,
    Strings.MASTER_VOLUME: 0.5,
    Strings.MUSIC_VOLUME: 0.5,
    Strings.SFX_VOLUME: 0.5,
    Strings.MUTE: false,
    Strings.VSYNC: true,
    }

const RESOLUTIONS: Array = [
    {Strings.WIDTH: 1920, Strings.HEIGHT: 1080},
    {Strings.WIDTH: 1600, Strings.HEIGHT: 900},
    {Strings.WIDTH: 1440, Strings.HEIGHT: 900},
    {Strings.WIDTH: 1366, Strings.HEIGHT: 768},
    {Strings.WIDTH: 1280, Strings.HEIGHT: 1024},
    {Strings.WIDTH: 1280, Strings.HEIGHT: 720},
    {Strings.WIDTH: 800, Strings.HEIGHT: 600},
    # {Strings.WIDTH: 2560, Strings.HEIGHT: 1440},
    # {Strings.WIDTH: 3840, Strings.HEIGHT: 2160},
]

var DEFAULT_RESOLUTION: Vector2i = Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))

var player_fullscreen_size: Vector2i
var player_windowed_size: Vector2i

var en_flag # preload flag image
var cs_flag # preload

var locale_list = [
    {Strings.LOCALE: "en", "language": "English", "flag": en_flag},
    {Strings.LOCALE: "cs", "language": "Czech", "flag": cs_flag},
]

var keybind_manager: KeybindManager = preload("res://Utility/Keybinds/KeybindManager.gd").new()
var settings: Dictionary
## If the game has already loaded, options should only need to set values visually
var settings_loaded: bool = false


func init():
    player_fullscreen_size = DisplayServer.screen_get_size()
    player_windowed_size = DisplayServer.screen_get_usable_rect().size


func _ready():
    init()
    load_settings()
    apply_values()
    keybind_manager.init()
    save_settings()


func check_option_settings(options: Dictionary) -> Dictionary:
    var _options = options
    for key in DEFAULT_SETTINGS.keys():
        if !_options.has(key):
            _options[key] = DEFAULT_SETTINGS[key]
            continue
        if typeof(_options[key]) != typeof(DEFAULT_SETTINGS[key]):
            push_warning("Setting %s has been reset to %s" % [key, DEFAULT_SETTINGS[key]])
            _options[key] = DEFAULT_SETTINGS[key]
        continue
    return _options


func save_settings() -> void:
    SavingManager.save_config_data(settings, SavingManager.SETTINGS_FILE)

## Sets loaded config data to settings variable
func load_settings() -> void:
    var data = SavingManager.load_config_data(SavingManager.SETTINGS_FILE)
    if data.is_empty() or !data.has(Strings.SETTINGS):
        data[Strings.SETTINGS] = DEFAULT_SETTINGS.duplicate()
    settings = data

## apply saved settings to game on startup
func apply_values() -> void:
    var _settings = settings[Strings.SETTINGS]
    set_window_mode()
    set_resolution(get_resolution_index())
    # set_resolution_by_value(_settings[Strings.WIDTH], _settings[Strings.HEIGHT])
    set_scaler_mode(_settings[Strings.SCALER_MODE])
    set_scaler_value(_settings[Strings.SCALER_VALUE])
    set_fsr_index(_settings[Strings.FSR_SELECTED])
    set_language(get_language_index())
    set_brightness(_settings[Strings.BRIGHTNESS])
    set_vsync(_settings[Strings.VSYNC])
    set_mute(_settings[Strings.MUTE])
    set_master_volume(_settings[Strings.MASTER_VOLUME])
    set_music_volume(_settings[Strings.MUSIC_VOLUME])
    set_sfx_volume(_settings[Strings.SFX_VOLUME])
    settings_loaded = true


#region Resolution---------------------------------

func set_window_mode() -> void:
    var _settings = settings[Strings.SETTINGS]
    var window_mode = DisplayServer.WINDOW_MODE_WINDOWED
    if _settings[Strings.FULLSCREEN] == true:
        window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
    elif _settings[Strings.MAXIMIZED] == true:
        window_mode = DisplayServer.WINDOW_MODE_MAXIMIZED
    DisplayServer.window_set_mode(window_mode)
    resize_window()


func set_resolution(index: int) -> void:
    var idx = clampi(index, 0, RESOLUTIONS.size() - 1)
    var size = RESOLUTIONS[idx]
    var _settings = settings[Strings.SETTINGS]
    _settings[Strings.WIDTH] = size[Strings.WIDTH]
    _settings[Strings.HEIGHT] = size[Strings.HEIGHT]
    resize_window()

## this can be used to set a custom resolution not in RESOLUTIONS array
func set_resolution_by_value(width: int, height: int) -> void:
    var _settings = settings[Strings.SETTINGS]
    _settings[Strings.WIDTH] = width
    _settings[Strings.HEIGHT] = height
    resize_window()


func resize_window() -> void:
    var _settings = settings[Strings.SETTINGS]
    if _settings[Strings.FULLSCREEN] == true or _settings[Strings.MAXIMIZED] == true:
        return
    var window_size = Vector2i(_settings[Strings.WIDTH], _settings[Strings.HEIGHT])
    # scales the game window
    get_tree().root.size = window_size
    # scales the content within the window
    # get_tree().root.content_scale_size = window_size
    center_window(false)


func center_window(do_center: bool = true) -> void:
    var _settings = settings[Strings.SETTINGS]
    if _settings[Strings.FULLSCREEN] == true or _settings[Strings.MAXIMIZED] == true or !do_center:
        return
    var window_size = Vector2i(_settings[Strings.WIDTH], _settings[Strings.HEIGHT])
    var current_monitor = DisplayServer.get_keyboard_focus_screen()
    var screen_size := DisplayServer.screen_get_size(current_monitor)
    var screen_pos := DisplayServer.screen_get_position(current_monitor)
    var x = (screen_size.x - window_size.x) / 2
    var y = (screen_size.y - window_size.y) / 2
    get_tree().root.position = Vector2i(screen_pos.x + x, screen_pos.y + y)

## get index of current resolution in RESOLUTIONS array. Defaults to 5(1280x720) if not found
func get_resolution_index() -> int:
    var _settings = settings[Strings.SETTINGS]
    var idx := RESOLUTIONS.find({Strings.WIDTH: _settings[Strings.WIDTH], Strings.HEIGHT: _settings[Strings.HEIGHT]})
    if idx == -1:
        idx = 5
    return idx


#endregion

#region Quality---------------------------------

func set_scaler_mode(index: int) -> void:
    var _settings = settings[Strings.SETTINGS]
    _settings[Strings.SCALER_MODE] = index
    var viewport = get_viewport()
    if ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
        viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
    else:
        viewport.scaling_3d_mode = _settings[Strings.SCALER_MODE]


func set_scaler_value(value: float) -> void:
    var _settings = settings[Strings.SETTINGS]
    _settings[Strings.SCALER_VALUE] = value
    var viewport = get_viewport()
    var resolution_scale = _settings[Strings.SCALER_VALUE] / 100.00
    viewport.scaling_3d_scale = resolution_scale


func set_fsr_index(index: int) -> void:
    settings[Strings.SETTINGS][Strings.FSR_SELECTED] = index

#endregion

#region Audio---------------------------------

func set_mute(value: bool) -> void:
    settings[Strings.SETTINGS][Strings.MUTE] = value
    AudioManager.mute_volume(value)

func set_master_volume(value: float) -> void:
    settings[Strings.SETTINGS][Strings.MASTER_VOLUME] = value
    AudioManager.set_master_volume(value)

func set_music_volume(value: float) -> void:
    settings[Strings.SETTINGS][Strings.MUSIC_VOLUME] = value
    AudioManager.set_music_volume(value)

func set_sfx_volume(value: float) -> void:
    settings[Strings.SETTINGS][Strings.SFX_VOLUME] = value
    AudioManager.set_sfx_volume(value)

#endregion

#region Other---------------------------------

func set_brightness(value: float) -> void:
    value = clampf(value, 0.5, 2.0)
    settings[Strings.SETTINGS][Strings.BRIGHTNESS] = value
    # if GameManager.get("environment_res") != null:
    #     GameManager.environment_res.adjustment_brightness = value


func set_vsync(value: bool) -> void:
    settings[Strings.SETTINGS][Strings.VSYNC] = value
    if value:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
    else:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func set_language(index: int) -> void:
    index = clampi(index, 0, locale_list.size() - 1)
    var locale = locale_list[index][Strings.LOCALE]
    settings[Strings.SETTINGS][Strings.LOCALE] = locale
    TranslationServer.set_locale(locale)


func get_language_index() -> int:
    var idx: int = 0
    for d: Dictionary in locale_list:
        if d[Strings.LOCALE] == settings[Strings.SETTINGS][Strings.LOCALE]:
            idx = locale_list.find(d)
            break
    return idx

#endregion
