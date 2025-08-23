extends RefCounted
class_name SettingsManager


const DEFAULT_SETTINGS: Dictionary = {
    Strings.FULLSCREEN: false,
    Strings.MAXIMIZED: false,
    Strings.RESOLUTION_INDEX: 5,
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
    {Strings.LOCALE: "en", "code": "English", "flag": en_flag},
    {Strings.LOCALE: "cs", "code": "Czech", "flag": cs_flag},
]

## If the game has already loaded, options should only need to set values visually
static var settings_loaded: bool = false

## from GameManager
static func init():
    player_fullscreen_size = DisplayServer.screen_get_size()
    player_windowed_size = DisplayServer.screen_get_usable_rect().size


static func check_option_settings(options: Dictionary) -> Dictionary:
    var _options = options
    for key in DEFAULT_SETTINGS.keys():
        if _options.has(key):
            if typeof(_options[key]) != typeof(DEFAULT_SETTINGS[key]):
                push_warning("Setting %s has been reset to %s" % [key, DEFAULT_SETTINGS[key]])
                _options[key] = DEFAULT_SETTINGS[key]
            continue

        _options[key] = DEFAULT_SETTINGS[key]
        # push_warning("Setting %s was missing from file" % [key])

    return _options


static func set_locale():
    var options = SavingManager.load_from_encoded_file(SavingManager.OPTIONS_FILE)
    if options.has(Strings.LOCALE):
        TranslationServer.set_locale(options[Strings.LOCALE])
    else:
        options[Strings.LOCALE] = "en"
    SavingManager.write_options(Strings.LOCALE, options)
    pass
