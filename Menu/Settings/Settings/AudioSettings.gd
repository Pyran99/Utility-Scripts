extends RefCounted
class_name AudioSettings


# const SFX_CLICK := preload("res://Assets/Audio/Sounds/Button7.wav")

var owner: SettingsMenu


func _init(_owner: SettingsMenu) -> void:
    owner = _owner

@warning_ignore("unused_parameter")
func set_volume_for(bus: int, value: float, play_sfx: bool = false) -> void:
    if bus == -1: return
    value = clampf(value, 0.0, 1.0)
    AudioServer.set_bus_volume_db(bus, linear_to_db(value))
    var _bus_name: String = AudioServer.get_bus_name(bus)
    # if play_sfx:
    #     GlobalAudioManager.play_ui_sound(SFX_CLICK, false, bus_name)


func set_mute(is_muted: bool) -> void:
    AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), is_muted)
