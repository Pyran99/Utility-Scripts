# @tool
extends Node
## uncomment tool then save scene to initialize project settings. comment tool when finished

func _init() -> void:
    ## 640×360 is a good baseline, as it scales to 1280×720, 1920×1080, 2560×1440, and 3840×2160
    ProjectSettings.set_setting("display/window/size/viewport_width", 1280 / 2)
    ProjectSettings.set_setting("display/window/size/viewport_height", 720 / 2)
    ProjectSettings.set_setting("display/window/size/window_width_override", 320 * 4)
    ProjectSettings.set_setting("display/window/size/window_height_override", 180 * 4)
    
    # ProjectSettings.set_setting("display/window/size/borderless", false)
    ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
    ProjectSettings.set_setting("display/window/stretch/aspect", "keep")

    ProjectSettings.set_setting("debug/gdscript/warnings/narrowing_conversion", false)
    ProjectSettings.set_setting("debug/gdscript/warnings/integer_division", false)
    ProjectSettings.set_setting("debug/gdscript/warnings/return_value_discarded", false)

    ProjectSettings.set_setting("rendering/textures/canvas_textures/default_texture_filter", "Nearest") # sharper pixels
    ProjectSettings.set_setting("gui/theme/default_font_multichannel_signed_distance_field", true) # fix blurry default font

    print_debug("Initialized Project Settings, remove 'Tool'.")