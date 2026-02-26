# @tool
## uncomment tool then save scene to initialize project settings. comment tool when finished
extends Node
# new settings can be made just by calling set_setting with custom string

func _init() -> void:
    _setup_autoloads()
    _setup_display()
    _setup_misc()
    print_debug("Initialized Project Settings, remove 'Tool'.")


func _setup_autoloads() -> void:
    var save := "autoload/SavingManager"
    var setting := "autoload/SettingsManager"
    var audio := "autoload/AudioManager"
    var global_audio := "autoload/GlobalAudioPlayer"
    var scene := "autoload/SceneManager"
    var game := "autoload/GameManager"
    var keybind := "autoload/KeybindManager"
    if !ProjectSettings.has_setting(save):
        ProjectSettings.set_setting(save, "res://Utility/Autoload/SavingManager.gd")
    if !ProjectSettings.has_setting(setting):
        ProjectSettings.set_setting(setting, "res://Utility/Autoload/SettingsManager.gd")
    if !ProjectSettings.has_setting(audio):
        ProjectSettings.set_setting(audio, "res://Utility/Autoload/AudioManager.gd")
    if !ProjectSettings.has_setting(global_audio):
        ProjectSettings.set_setting(global_audio, "res://Utility/Autoload/global_audio_player.tscn")
    if !ProjectSettings.has_setting(scene):
        ProjectSettings.set_setting(scene, "res://Utility/Autoload/scene_manager.tscn")
    if !ProjectSettings.has_setting(game):
        ProjectSettings.set_setting(game, "res://Utility/Autoload/GameManager.gd")
    if !ProjectSettings.has_setting(keybind):
        ProjectSettings.set_setting(keybind, "res://Menu/Keybinds/KeybindManager.gd")
    

func _setup_display() -> void:
    ## 640×360 is a good baseline, as it scales to 1280×720, 1920×1080, 2560×1440, and 3840×2160
    ProjectSettings.set_setting("display/window/size/viewport_width", int(1280))
    ProjectSettings.set_setting("display/window/size/viewport_height", int(720))
    ProjectSettings.set_setting("display/window/size/window_width_override", 640 * 2)
    ProjectSettings.set_setting("display/window/size/window_height_override", 360 * 2)
    ProjectSettings.set_setting("display/window/size/always_on_top", true)
    # ProjectSettings.set_setting("display/window/size/borderless", false)
    ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
    ProjectSettings.set_setting("display/window/stretch/aspect", "keep")
    ProjectSettings.set_setting("application/run/max_fps", 60)


func _setup_misc() -> void:
    ProjectSettings.set_setting("debug/gdscript/warnings/narrowing_conversion", false)
    ProjectSettings.set_setting("debug/gdscript/warnings/integer_division", false)
    ProjectSettings.set_setting("debug/gdscript/warnings/return_value_discarded", false)
    ProjectSettings.set_setting("rendering/textures/canvas_textures/default_texture_filter", "Nearest") # sharper pixels
    ProjectSettings.set_setting("gui/theme/default_font_multichannel_signed_distance_field", true) # fix blurry default font
    ProjectSettings.set_setting("display/window/size/always_on_top", true)
