extends Node
# class_name SettingsManager
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

static var player_fullscreen_size: Vector2i
static var player_windowed_size: Vector2i

static var en_flag # preload flag image
static var cs_flag # preload

static var locale_list = [
    {Strings.LOCALE: "en", "language": "English", "flag": en_flag},
    {Strings.LOCALE: "cs", "language": "Czech", "flag": cs_flag},
]

## If the game has already loaded, options should only need to set values visually
static var settings_loaded: bool = false
static var settings: Dictionary

## from GameManager
static func init():
    player_fullscreen_size = DisplayServer.screen_get_size()
    player_windowed_size = DisplayServer.screen_get_usable_rect().size
    # SavingManager.save_settings_data.connect(save_settings) # TODO-3


func _ready():
    init()
    load_settings()
    KeybindManager.init()
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
    SavingManager.save_config_data(settings, SavingManager.CONFIG_DIR + "test.ini")

## Returns SavingManager config Settings
func load_settings() -> void:
    var data = SavingManager.load_config_data(SavingManager.CONFIG_DIR + "test.ini")
    if data.is_empty() or !data.has(Strings.SETTINGS):
        data[Strings.SETTINGS] = DEFAULT_SETTINGS.duplicate()
    settings = data
    print_debug("5: Settings loaded:\n%s" % settings)
    apply_values()

## apply saved settings to game on startup
func apply_values() -> void:
    set_window_mode()
    set_resolution(get_resolution_index())
    set_scaler_mode(settings[Strings.SETTINGS][Strings.SCALER_MODE])
    set_scaler_value(settings[Strings.SETTINGS][Strings.SCALER_VALUE])
    set_fsr_index(settings[Strings.SETTINGS][Strings.FSR_SELECTED])
    set_language(get_language_index())
    set_brightness(settings[Strings.SETTINGS][Strings.BRIGHTNESS])
    set_vsync(settings[Strings.SETTINGS][Strings.VSYNC])
    set_mute(settings[Strings.SETTINGS][Strings.MUTE])
    set_master_volume(settings[Strings.SETTINGS][Strings.MASTER_VOLUME])
    set_music_volume(settings[Strings.SETTINGS][Strings.MUSIC_VOLUME])
    set_sfx_volume(settings[Strings.SETTINGS][Strings.SFX_VOLUME])


#region Resolution

func set_window_mode() -> void:
    var window_mode = DisplayServer.WINDOW_MODE_WINDOWED
    if settings[Strings.SETTINGS][Strings.FULLSCREEN] == true:
        window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
    elif settings[Strings.SETTINGS][Strings.MAXIMIZED] == true:
        window_mode = DisplayServer.WINDOW_MODE_MAXIMIZED
    DisplayServer.window_set_mode(window_mode)
    resize_window()


func set_resolution(index: int) -> void:
    var idx = clampi(index, 0, RESOLUTIONS.size() - 1)
    var size = RESOLUTIONS[idx]
    settings[Strings.SETTINGS][Strings.WIDTH] = size[Strings.WIDTH]
    settings[Strings.SETTINGS][Strings.HEIGHT] = size[Strings.HEIGHT]
    resize_window()


func resize_window() -> void:
    if settings[Strings.SETTINGS][Strings.FULLSCREEN] == true or settings[Strings.SETTINGS][Strings.MAXIMIZED] == true:
        return

    # if settings.has(Strings.WIDTH) and settings.has(Strings.HEIGHT):
    var window_size = Vector2i(settings[Strings.SETTINGS][Strings.WIDTH], settings[Strings.SETTINGS][Strings.HEIGHT])
    # scales the game window
    get_tree().root.size = window_size
    # scales the content within the window
    # get_tree().root.content_scale_size = window_size
    center_window()


func center_window(do_center: bool = true) -> void:
    if settings[Strings.SETTINGS][Strings.FULLSCREEN] == true or settings[Strings.SETTINGS][Strings.MAXIMIZED] == true or !do_center:
        return
    var window_size = Vector2i(settings[Strings.SETTINGS][Strings.WIDTH], settings[Strings.SETTINGS][Strings.HEIGHT])
    var current_monitor = DisplayServer.get_keyboard_focus_screen()
    var screen_size := DisplayServer.screen_get_size(current_monitor)
    var screen_pos := DisplayServer.screen_get_position(current_monitor)
    var x = (screen_size.x - window_size.x) / 2
    var y = (screen_size.y - window_size.y) / 2
    get_tree().root.position = Vector2i(screen_pos.x + x, screen_pos.y + y)


func get_resolution_index() -> int:
    var idx := RESOLUTIONS.find({Strings.WIDTH: settings[Strings.SETTINGS][Strings.WIDTH], Strings.HEIGHT: settings[Strings.SETTINGS][Strings.HEIGHT]})
    if idx == -1:
        idx = 5 # default to 1280x720 if not found
    return idx


#endregion

#region Quality

func set_scaler_mode(index: int) -> void:
    settings[Strings.SETTINGS][Strings.SCALER_MODE] = index
    var viewport = get_viewport()
    if ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
        viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
    else:
        viewport.scaling_3d_mode = settings[Strings.SETTINGS][Strings.SCALER_MODE]

    # print_debug("viewport.scaling_3d_mode: %s" % viewport.scaling_3d_mode)


func set_scaler_value(value: float) -> void:
    settings[Strings.SETTINGS][Strings.SCALER_VALUE] = value
    var viewport = get_viewport()
    var resolution_scale = settings[Strings.SETTINGS][Strings.SCALER_VALUE] / 100.00
    viewport.scaling_3d_scale = resolution_scale

    # print_debug("viewport.scaling_3d_scale: %s" % viewport.scaling_3d_scale)


func set_fsr_index(index: int) -> void:
    settings[Strings.SETTINGS][Strings.FSR_SELECTED] = index

#endregion

#region Audio

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

#region Other

func set_brightness(value: float) -> void:
    value = clampf(value, 0.5, 2.0)
    settings[Strings.SETTINGS][Strings.BRIGHTNESS] = value
    if GameManager.get("environment_res") != null:
        GameManager.environment_res.adjustment_brightness = value


func set_vsync(value: bool) -> void:
    settings[Strings.SETTINGS][Strings.VSYNC] = value
    if value:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
    else:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func set_language(index: int) -> void:
    index = clampi(index, 0, locale_list.size() - 1)
    var locale = locale_list[index][Strings.LOCALE]
    print_debug("Setting language to: %s" % locale)
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
