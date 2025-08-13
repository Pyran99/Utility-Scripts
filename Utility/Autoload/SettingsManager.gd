extends RefCounted
class_name SettingsManager


const DEFAULT_SETTINGS: Dictionary = {
    "fullscreen": false,
    "maximized": false,
    "resolution_index": 5,
    "width": 1280,
    "height": 720,
    "locale": "en",
    "scaler_mode": 1,
    "scaler_value": 100.0,
    "fsr_selected": 1,
    "brightness": 1.0,
    "master_volume": 0.5,
    "music_volume": 0.5,
    "sfx_volume": 0.5,
    "mute": false,
    "vsync": true,
    }

const RESOLUTIONS: Array = [
    {"width": 1920, "height": 1080},
    {"width": 1600, "height": 900},
    {"width": 1440, "height": 900},
    {"width": 1366, "height": 768},
    {"width": 1280, "height": 1024},
    {"width": 1280, "height": 720},
    {"width": 800, "height": 600},
    # {"width": 2560, "height": 1440},
    # {"width": 3840, "height": 2160},
]

var DEFAULT_RESOLUTION: Vector2i = Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))

static var player_fullscreen_size: Vector2i
static var player_windowed_size: Vector2i

static var en_flag # preload flag image
static var cs_flag # preload

static var locale_list = [
    {"locale": "en", "code": "English", "flag": en_flag},
    {"locale": "cs", "code": "Czech", "flag": cs_flag},
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
        push_warning("Setting %s was missing from file" % [key])

    return _options


static func set_locale():
    var options = SavingManager.load_from_encoded_file(SavingManager.OPTIONS_FILE)
    if options.has("locale"):
        TranslationServer.set_locale(options["locale"])
    else:
        options["locale"] = "en"
    SavingManager.write_options("Locale", options)
    pass
