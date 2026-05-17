extends CheckboxElement


# const FPS_DISPLAY: PackedScene = preload("res://Scenes/UI/fps_display.tscn")

var fps_display: CanvasLayer


func _apply_settings() -> void:
    print("applied " + id + " with value: ", str(current_value))
    parent_section.cache_setting(id, current_value)
    SettingsManager.toggle_fps_display(current_value)
    # if current_value == true:
    #     fps_display = FPS_DISPLAY.instantiate()
    #     UILayers.add(fps_display, UILayers.Layers.MENU_OVERLAY)
    #     return
    # if fps_display:
    #     fps_display.queue_free()
