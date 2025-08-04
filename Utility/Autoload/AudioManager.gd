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
    # options = OptionsManager.read_options()
    if MASTER_BUS == -1 or MUSIC_BUS == -1 or SFX_BUS == -1:
        push_warning("Missing audio bus as -1: Master: %s Music: %s SFX: %s" % [MASTER_BUS, MUSIC_BUS, SFX_BUS])

    _load_options()

 
func _load_options() -> void:
    options = SavingManager.load_from_config("Settings")
    if options.has("mute"):
        mute_volume(options["mute"])
    if options.has("master_volume") and MASTER_BUS != -1:
        set_master_volume(options["master_volume"])
    if options.has("music_volume") and MUSIC_BUS != -1:
        set_music_volume(options["music_volume"])
    if options.has("sfx_volume") and SFX_BUS != -1:
        set_sfx_volume(options["sfx_volume"])


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
