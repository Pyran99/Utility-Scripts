extends Node
#AUTOLOAD

var MASTER_BUS: int = -1
var MUSIC_BUS: int = -1
var SFX_BUS: int = -1

var options: Dictionary
var is_muted: bool = false
var master_volume: float = 0.5
var music_volume: float = 0.5
var sfx_volume: float = 0.5


func _ready():
    MASTER_BUS = AudioServer.get_bus_index("Master")
    MUSIC_BUS = AudioServer.get_bus_index("Music")
    SFX_BUS = AudioServer.get_bus_index("SFX")
    if MASTER_BUS == -1 or MUSIC_BUS == -1 or SFX_BUS == -1:
        push_warning("Missing audio bus as -1: Master: %s Music: %s SFX: %s" % [MASTER_BUS, MUSIC_BUS, SFX_BUS])

    _load_options()


func _load_options() -> void:
    options = SavingManager.load_from_config(Strings.SETTINGS, SavingManager.SETTINGS_FILE)
    if options.has(Strings.MUTE):
        mute_volume(options[Strings.MUTE])
    if options.has(Strings.MASTER_VOLUME) and MASTER_BUS != -1:
        set_master_volume(options[Strings.MASTER_VOLUME])
    if options.has(Strings.MUSIC_VOLUME) and MUSIC_BUS != -1:
        set_music_volume(options[Strings.MUSIC_VOLUME])
    if options.has(Strings.SFX_VOLUME) and SFX_BUS != -1:
        set_sfx_volume(options[Strings.SFX_VOLUME])


func mute_volume(enabled: bool):
    AudioServer.set_bus_mute(MASTER_BUS, enabled)
    is_muted = enabled


func set_master_volume(value: float):
    value = clampf(value, 0.0, 1.0)
    AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(value))
    master_volume = value


func set_music_volume(value: float):
    value = clampf(value, 0.0, 1.0)
    AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(value))
    music_volume = value


func set_sfx_volume(value: float):
    value = clampf(value, 0.0, 1.0)
    AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(value))
    sfx_volume = value
