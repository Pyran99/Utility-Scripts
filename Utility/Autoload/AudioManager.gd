extends Node
#AUTOLOAD

var MASTER_BUS: int = -1
var MUSIC_BUS: int = -1
var SFX_BUS: int = -1

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
    var settings = SettingsManager.settings[Strings.SETTINGS]
    var muted = settings.get(Strings.MUTE, false)
    var master_vol = settings.get(Strings.MASTER_VOLUME, SettingsManager.DEFAULT_SETTINGS[Strings.MASTER_VOLUME])
    var music_vol = settings.get(Strings.MUSIC_VOLUME, SettingsManager.DEFAULT_SETTINGS[Strings.MUSIC_VOLUME])
    var sfx_vol = settings.get(Strings.SFX_VOLUME, SettingsManager.DEFAULT_SETTINGS[Strings.SFX_VOLUME])
    mute_volume(muted)
    set_master_volume(master_vol)
    set_music_volume(music_vol)
    set_sfx_volume(sfx_vol)


func mute_volume(enabled: bool):
    SettingsManager.settings[Strings.SETTINGS][Strings.MUTE] = enabled
    is_muted = enabled
    if MASTER_BUS == -1:
        return
    AudioServer.set_bus_mute(MASTER_BUS, enabled)


func set_master_volume(value: float):
    value = clampf(value, 0.0, 1.0)
    SettingsManager.settings[Strings.SETTINGS][Strings.MASTER_VOLUME] = value
    master_volume = value
    if MASTER_BUS == -1:
        return
    AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(value))


func set_music_volume(value: float):
    value = clampf(value, 0.0, 1.0)
    SettingsManager.settings[Strings.SETTINGS][Strings.MUSIC_VOLUME] = value
    music_volume = value
    if MUSIC_BUS == -1:
        return
    AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(value))


func set_sfx_volume(value: float):
    value = clampf(value, 0.0, 1.0)
    SettingsManager.settings[Strings.SETTINGS][Strings.SFX_VOLUME] = value
    sfx_volume = value
    if SFX_BUS == -1:
        return
    AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(value))
