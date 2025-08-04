extends Control
class_name TabOptionsMenu

#TODO this has not been updated

#-------------------------------------#
# Requires AudioManager
# Requires GameManager with environment resource
# Requires SavingManager
# Requires SettingsManager
#-------------------------------------#

signal settings_changed(section: String, data: Dictionary, save_file: String)

var last_selected_resolution: Vector2i = Vector2i(1280, 720)

var window_position: Vector2i

var options: Dictionary = {}

@export var do_center_window: bool = false
@export var previous_menu: Control

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var mute_btn: CheckBox = %MuteBtn

@onready var fullscreen_btn: CheckBox = %FullscreenBtn
@onready var maximize_btn: CheckBox = %MaximizeBtn
@onready var resolution_btn: OptionButton = %ResolutionBtn
@onready var vsync_btn: CheckBox = %VsyncBtn

@onready var brightness_slider: HSlider = %BrightnessSlider
@onready var brightness_value: Label = %BrightnessValue
@onready var scale_text: Label = %Scale
@onready var scaler_options: OptionButton = %ScalerOptions
@onready var scale_slider: HSlider = %ScaleSlider

@onready var fsr_container: HBoxContainer = %FsrContainer
@onready var fsr_options: OptionButton = %FSROptions

@onready var language_btn: OptionButton = %LanguageOptions
@onready var back_btn: Button = %BackBtn
@onready var tab_container: TabContainer = %TabContainer

func _ready():
    # options = SettingsManager.read_options() # encoded values
    options = SavingManager.load_from_config("Settings", SavingManager.CONFIG_SAVE_FILE) # file editable
    if options.is_empty():
        options = SettingsManager.DEFAULT_SETTINGS.duplicate()
        SavingManager.save_as_config("Settings", options, SavingManager.CONFIG_SAVE_FILE)
    _connect_signals()
    _add_resolutions_to_button()
    reload_language_options()
    _set_saved_values()

func _connect_signals() -> void:
    # settings_changed.connect(SettingsManager.write_options)
    settings_changed.connect(SavingManager.save_as_config)
    visibility_changed.connect(_on_visibility_changed)
    get_tree().root.size_changed.connect(_on_window_size_changed)
    
    master_slider.value_changed.connect(_on_master_slider_value_changed)
    music_slider.value_changed.connect(_on_music_slider_value_changed)
    sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
    mute_btn.toggled.connect(_on_mute_btn_toggled)

    fullscreen_btn.toggled.connect(_on_fullscreen_btn_toggled)
    maximize_btn.toggled.connect(_on_maximize_btn_toggled)
    resolution_btn.item_selected.connect(_on_resolution_btn_item_selected)
    vsync_btn.toggled.connect(_on_vsync_btn_toggled)

    brightness_slider.value_changed.connect(_on_gamma_slider_value_changed)
    scale_slider.value_changed.connect(_on_scale_slider_value_changed)
    scaler_options.item_selected.connect(_on_scaler_item_selected)
    fsr_options.item_selected.connect(_on_fsr_options_item_selected)

    back_btn.pressed.connect(_on_back_btn_pressed)

func set_previous_menu(menu: Control) -> void:
    previous_menu = menu

func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _toggle_menu()

func save_settings() -> void:
    settings_changed.emit("Settings", options, SavingManager.CONFIG_SAVE_FILE)
    print_debug("Settings saved")

func load_settings() -> void:
    # options = SettingsManager.read_options() # encoded values
    options = SavingManager.load_from_config("Settings", SavingManager.CONFIG_SAVE_FILE)
    _set_saved_values()

func _set_saved_values() -> void:
    _set_toggles()
    update_audio_properties()
    check_scaler_options()
    brightness_slider.value = options["brightness"] if options.has("brightness") else 1.0

    _on_scaler_item_selected(options["scaler_mode"] if options.has("scaler_mode") else 1)
    scaler_options.select(options["scaler_mode"])
    if get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR:
        _on_scale_slider_value_changed(options["scaler_value"] if options.has("scaler_value") else 100)
    elif get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR2:
        _on_fsr_options_item_selected(options["fsr_selected"] if options.has("fsr_selected") else 1)

    match get_tree().root.mode:
        Window.MODE_WINDOWED:
            var resolution: int = 0
            # get the index of 1280x720 to use as default
            for i in range(SettingsManager.RESOLUTIONS.size()):
                if SettingsManager.RESOLUTIONS[i]["width"] == 1280 and SettingsManager.RESOLUTIONS[i]["height"] == 720:
                    resolution = i
                    break

            _on_resolution_btn_item_selected(options["resolution_index"] if options.has("resolution_index") else resolution)
            resolution_btn.selected = options["resolution_index"] if options.has("resolution_index") else 0
    
    reload_language_options()

func _set_toggles():
    vsync_btn.button_pressed = options["vsync"] if options.has("vsync") else false
    fullscreen_btn.button_pressed = options["fullscreen"] if options.has("fullscreen") else false
    if !fullscreen_btn.button_pressed:
        maximize_btn.button_pressed = options["maximized"] if options.has("maximized") else false
    else:
        maximize_btn.set_pressed_no_signal(false)

func _on_back_btn_pressed() -> void:
    _close_menu()

func _close_menu() -> void:
    hide()
    if previous_menu:
        previous_menu.show()

func _toggle_menu() -> void:
    if visible:
        _close_menu()
    else:
        show()

#region Audio------------------------------------------
func update_audio_properties() -> void:
    master_slider.value = options["master_volume"] if options.has("master_volume") else 0.5
    music_slider.value = options["music_volume"] if options.has("music_volume") else 0.5
    sfx_slider.value = options["sfx_volume"] if options.has("sfx_volume") else 0.5
    mute_btn.button_pressed = options["mute"] if options.has("mute") else false

func _on_mute_btn_toggled(toggled_on: bool) -> void:
    options["mute"] = toggled_on
    AudioManager.mute_volume(toggled_on)

func _on_master_slider_value_changed(value: float) -> void:
    AudioManager.set_master_volume(value)
    options["master_volume"] = AudioManager.master_volume

func _on_music_slider_value_changed(value: float) -> void:
    AudioManager.set_music_volume(value)
    options["music_volume"] = AudioManager.music_volume

func _on_sfx_slider_value_changed(value: float) -> void:
    AudioManager.set_sfx_volume(value)
    options["sfx_volume"] = AudioManager.sfx_volume
#endregion

#region Resolution------------------------------------------
## This can be used to set the text of the resolution button to the real resolution
func set_resolution_text() -> void:
    # await get_tree().process_frame
    # var window = get_window()
    # var resolution_text = str("%s x %s" % [window.get_size().x, window.get_size().y])
    # resolution_btn.text = resolution_text
    pass

func set_window_mode() -> void:
    var window_mode = DisplayServer.WINDOW_MODE_WINDOWED
    if options.has("fullscreen") and options["fullscreen"]:
        window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
    DisplayServer.window_set_mode(window_mode)

func resize_window() -> void:
    if !options.has("fullscreen") or !options["fullscreen"]:
        if options.has("width") and options.has("height"):
            var window_size = Vector2i(options["width"], options["height"])
            get_tree().root.size = window_size
            if do_center_window:
                center_window()

func center_window() -> void:
    if options.has("width") and options.has("height"):
        var window_size = Vector2i(options["width"], options["height"])
        var screen_size = DisplayServer.screen_get_size()
        get_tree().root.position = Vector2i((screen_size.x - window_size.x) / 2, (screen_size.y - window_size.y) / 2)

func _add_resolutions_to_button() -> void:
    resolution_btn.clear()
    var screen_size = DisplayServer.screen_get_size()
    var idx: int = 0
    for res in SettingsManager.RESOLUTIONS:
        # only add options that are smaller than the screen
        if res["width"] <= screen_size.x and res["height"] <= screen_size.y:
            resolution_btn.add_item("%s x %s" % [res["width"], res["height"]])
            if options.has("width") and options.has("height"):
                # select the saved resolution
                if res["width"] == options["width"] and res["height"] == options["height"]:
                    resolution_btn.select(idx)
        idx += 1

func _on_resolution_btn_item_selected(index: int) -> void:
    var _size = SettingsManager.RESOLUTIONS[index]
    options["resolution_index"] = index
    options["width"] = _size["width"]
    options["height"] = _size["height"]
    last_selected_resolution = Vector2i(_size["width"], _size["height"])
    window_position = get_window().position
    resize_window()
    set_resolution_text()

func _on_fullscreen_btn_toggled(toggled_on: bool) -> void:
    options["fullscreen"] = toggled_on
    resolution_btn.disabled = toggled_on
    maximize_btn.disabled = toggled_on
    maximize_btn.set_pressed_no_signal(false)
    set_window_mode()
    resize_window()
    set_resolution_text()
    check_scaler_options()

func _on_maximize_btn_toggled(toggled_on: bool) -> void:
    var window = get_window()
    options["maximized"] = toggled_on
    resolution_btn.disabled = toggled_on
    if window.mode == Window.MODE_FULLSCREEN:
        # button shouldnt be active
        return
    if toggled_on:
        await get_tree().process_frame # does not work on startup without this
        window.mode = Window.MODE_MAXIMIZED
    else:
        await get_tree().process_frame
        window.mode = Window.MODE_WINDOWED
        window.size = last_selected_resolution
        window.position = window_position
        if do_center_window:
            center_window()
    set_resolution_text()
    check_scaler_options()

func _on_window_size_changed() -> void:
    var window = get_window()
    await get_tree().process_frame
    match window.mode:
        Window.MODE_FULLSCREEN:
            options["fullscreen"] = true
            options["maximized"] = false
            resolution_btn.disabled = true
            maximize_btn.disabled = true
            maximize_btn.set_pressed_no_signal(false)
            fullscreen_btn.set_pressed_no_signal(true)
        Window.MODE_MAXIMIZED:
            options["maximized"] = true
            options["fullscreen"] = false
            resolution_btn.disabled = true
            maximize_btn.set_pressed_no_signal(true)
            fullscreen_btn.set_pressed_no_signal(false)
        Window.MODE_WINDOWED:
            options["maximized"] = false
            options["fullscreen"] = false
            resolution_btn.disabled = false
            maximize_btn.set_pressed_no_signal(false)
            fullscreen_btn.set_pressed_no_signal(false)

    set_resolution_text()
    check_scaler_options()

#endregion

#region Quality------------------------------------------
# resolution scaling is not available for 2D
func check_scaler_options() -> void:
    var viewport = get_viewport()
    if ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
        scaler_options.set_item_disabled(2, true) # amd fsr option

    if viewport.scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR2:
        fsr_container.show()
        scale_slider.editable = false
    else:
        fsr_container.hide()
        scale_slider.editable = true

func _on_scale_slider_value_changed(value: float) -> void:
    options["scaler_value"] = value
    var resolution_scale = value / 100.00
    scale_text.text = str(value) + "%"
    #--------------for showing resolution in text with scale %--------------#
    # var resolution_text = str(round(get_window().get_size().x * resolution_scale)) + "x" + str(round(get_window().get_size().y * resolution_scale))
    # scale_text.text = (str(value) + "% - " + resolution_text)
    get_viewport().scaling_3d_scale = resolution_scale

func _on_scaler_item_selected(index: int) -> void:
    var viewport = get_viewport()
    options["scaler_mode"] = index
    match index:
        1:
            viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
            scale_slider.editable = true
            fsr_container.hide()
            scale_slider.value = options["scaler_value"] if options.has("scaler_value") else 100
        2:
            if ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
                _on_scaler_item_selected(1)
                return
            viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
            scale_slider.editable = false
            fsr_container.show()
            _on_fsr_options_item_selected(options["fsr_selected"] if options.has("fsr_selected") else 1)
            fsr_options.select(options["fsr_selected"])

func _on_fsr_options_item_selected(index: int) -> void:
    options["fsr_selected"] = index
    match index:
        1:
            scale_slider.value = 50.00
        2:
            scale_slider.value = 59.00
        3:
            scale_slider.value = 67.00
        4:
            scale_slider.value = 77.00
#endregion

#region Other------------------------------------------
func reload_language_options():
    language_btn.clear()
    var idx: int = 0
    var languages = SettingsManager.locale_list
    for language in languages:
        language_btn.add_icon_item(language["flag"], tr(language["code"]))
        if !options.has("locale"):
            options["locale"] = "en"
        if language["locale"] == options["locale"]:
            language_btn.select(idx)
        # var test = TranslationServer.get_loaded_locales()
        # print_debug(test)
        idx += 1

func _on_language_btn_item_selected(index: int) -> void:
    var language = SettingsManager.locale_list[index]
    options["locale"] = language["locale"]
    SettingsManager.set_locale()
    reload_language_options()

func _on_keybind_btn_pressed() -> void:
    #TODO: show keybinding menu
    pass

func _on_gamma_slider_value_changed(value: float) -> void:
    value = clampf(value, 0.5, 2.0)
    options["brightness"] = value
    brightness_value.text = str("%2.2f" % value)
    if GameManager.get("environment_res"):
        GameManager.environment_res.adjustment_brightness = value

func _on_vsync_btn_toggled(toggled_on: bool) -> void:
    options["vsync"] = toggled_on
    if toggled_on:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
    else:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
#endregion

func _exit_tree() -> void:
    save_settings()

func _on_visibility_changed() -> void:
    if !visible:
        save_settings()
    else:
        load_settings()
        tab_container.current_tab = 0
        tab_container.get_tab_bar().grab_focus()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        save_settings()

#region old------------------------------------------

# func save_data():
#     var data = {
#         "resolution": last_selected_resolution,
#         "resolution_index": resolution_index,
#         "is_fullscreen": is_fullscreen,
#         "is_maximized": is_maximized,
#         "fsr_selected": fsr_selected,
#         "scaler_mode": scaler_selected,
#         "scale_value": scale_value,
#         "vsync_toggled": vsync_toggled,
#         "master_volume": AudioManager.master_volume,
#         "music_volume": AudioManager.music_volume,
#         "sfx_volume": AudioManager.sfx_volume,
#         "mute_toggled": AudioManager.is_muted,
#     }
#     SavingManager.save_as_config("Settings", data)

# func load_data() -> bool:
#     var data = SavingManager.load_from_config("Settings")
#     if data == {}:
#         print("no data found")
#         return false
#     AudioManager.set_master_volume(data.master_volume)
#     AudioManager.set_music_volume(data.music_volume)
#     AudioManager.set_sfx_volume(data.sfx_volume)
#     AudioManager.mute_volume(data.mute_toggled)

#     resolution_btn.selected = data.resolution_index
#     last_selected_resolution = data.resolution
#     is_fullscreen = data.is_fullscreen
#     is_maximized = data.is_maximized

#     fsr_selected = data.fsr_selected
#     scaler_selected = data.scaler_selected
#     scale_value = data.scale_value
#     vsync_toggled = data.vsync_toggled
#     mute_toggled = data.mute_toggled
#     _set_saved_values()
#     return true

#endregion
