@icon("res://Assets/Packs/Kenney/Game Icons/gear.png")
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
    SFX_BUS = AudioServer.get_bus_index("Sfx")
    if MASTER_BUS == -1 or MUSIC_BUS == -1 or SFX_BUS == -1:
        push_warning("Missing audio bus as -1: Master: %s Music: %s Sfx: %s" % [MASTER_BUS, MUSIC_BUS, SFX_BUS])

    _load_options.call_deferred()


func _load_options() -> void:
    var settings = SettingsManager.settings.get(Strings.AUDIO, {})
    var default = SettingsManager.DEFAULT_AUDIO
    var master_vol = settings.get(Strings.MASTER_VOLUME, default[Strings.MASTER_VOLUME])
    var music_vol = settings.get(Strings.MUSIC_VOLUME, default[Strings.MUSIC_VOLUME])
    var sfx_vol = settings.get(Strings.SFX_VOLUME, default[Strings.SFX_VOLUME])
    mute_volume(settings.get(Strings.MUTE, false))
    set_master_volume(master_vol)
    set_music_volume(music_vol)
    set_sfx_volume(sfx_vol)


func mute_volume(enabled: bool):
    is_muted = enabled
    SettingsManager.set_save_setting(Strings.AUDIO, Strings.MUTE, enabled)
    if MASTER_BUS == -1:
        return
    AudioServer.set_bus_mute(MASTER_BUS, enabled)


func set_master_volume(value: float):
    value = clampf(value, 0.0, 1.0)
    master_volume = value
    SettingsManager.set_save_setting(Strings.AUDIO, Strings.MASTER_VOLUME, value)
    if MASTER_BUS == -1: return
    AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(value))


func set_music_volume(value: float):
    value = clampf(value, 0.0, 1.0)
    music_volume = value
    SettingsManager.set_save_setting(Strings.AUDIO, Strings.MUSIC_VOLUME, value)
    if MUSIC_BUS == -1: return
    AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(value))


func set_sfx_volume(value: float):
    value = clampf(value, 0.0, 1.0)
    sfx_volume = value
    SettingsManager.set_save_setting(Strings.AUDIO, Strings.SFX_VOLUME, value)
    if SFX_BUS == -1: return
    AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(value))
