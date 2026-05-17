extends RefCounted
class_name GeneralSettings

# brightness, vsync, language, atk opacity, dmg numbers, fps, max fps

var owner: SettingsMenu

func _init(_owner: SettingsMenu) -> void:
    owner = _owner


#is in game
func set_brightness(value: float) -> void:
    value = clampf(value, 0.5, 2.0)
    if GameManager.get("environment_res") != null:
        GameManager.environment_res.adjustment_brightness = value


func set_vsync(value: bool) -> void:
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)


func set_language(index: int) -> void:
    # index = clampi(index, 0, locale_list.size() - 1)
    # var locale = locale_list[index][Strings.LOCALE]
    # TranslationServer.set_locale(locale)
    # language_changed.emit(locale)
    pass


func set_language_by_locale(locale: String) -> void:
    var index = get_language_index_by_locale(locale)
    set_language(index)


func get_language_index() -> int:
    var idx: int = 0
    # for locale: Dictionary in locale_list:
    #     if locale[Strings.LOCALE] == settings[Strings.SETTINGS][Strings.LOCALE]:
    #         idx = locale_list.find(locale)
    #         break
    return idx


func get_language_index_by_locale(_locale: String) -> int:
    var idx: int = 0
    # for locale: Dictionary in locale_list:
    #     if locale[Strings.LOCALE] == _locale:
    #         idx = locale_list.find(locale)
    #         break
    return idx


#is in game
func toggle_fps_display(show: bool) -> void:
    # if show:
    #     if fps_display:
    #         fps_display.show()
    #         return
    #     await get_tree().process_frame
    #     fps_display = FPS_DISPLAY.instantiate()
    #     UILayers.add(fps_display, UILayers.Layers.MENU_OVERLAY)
    #     return
    # if fps_display:
    #     fps_display.hide()
    pass

##NYI
func set_max_fps(value: int) -> void:
    Engine.max_fps = value
