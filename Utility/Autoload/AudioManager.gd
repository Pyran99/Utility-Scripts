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
    print_debug("\n7. audio load: \n%s" % SettingsManager.settings[Strings.SETTINGS])
    var muted = SettingsManager.settings[Strings.SETTINGS].get(Strings.MUTE, false)
    var master_vol = SettingsManager.settings[Strings.SETTINGS].get(Strings.MASTER_VOLUME, 0.5)
    var music_vol = SettingsManager.settings[Strings.SETTINGS].get(Strings.MUSIC_VOLUME, 0.5)
    var sfx_vol = SettingsManager.settings[Strings.SETTINGS].get(Strings.SFX_VOLUME, 0.5)
    mute_volume(muted)
    set_master_volume(master_vol)
    set_music_volume(music_vol)
    set_sfx_volume(sfx_vol)


func mute_volume(enabled: bool):
    if MASTER_BUS == -1:
        return
    AudioServer.set_bus_mute(MASTER_BUS, enabled)
    is_muted = enabled


func set_master_volume(value: float):
    if MASTER_BUS == -1:
        return
    value = clampf(value, 0.0, 1.0)
    AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(value))
    master_volume = value


func set_music_volume(value: float):
    if MUSIC_BUS == -1:
        return
    value = clampf(value, 0.0, 1.0)
    AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(value))
    music_volume = value


func set_sfx_volume(value: float):
    if SFX_BUS == -1:
        return
    value = clampf(value, 0.0, 1.0)
    AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(value))
    sfx_volume = value
