extends Control
class_name OptionsMenu

#-------------------------------------#
# Requires AudioManager
# Requires SavingManager
# Requires SettingsManager
# GameManager with environment resource for bightness
#-------------------------------------#


signal settings_changed(section: String, data: Dictionary, save_file: String)

@export var do_center_window: bool = false
## the menu to show when this is hidden
@export var previous_menu: Control
@export var keybind_menu: Control

var last_selected_resolution: Vector2i = Vector2i(1280, 720)
var window_position: Vector2i
var options: Dictionary = {}
var original_options: Dictionary = {}

#region Nodes onready
@onready var option_panel: PanelContainer = $OptionsPanel
@onready var anim_player: AnimationPlayer = %AnimationPlayer

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

@onready var scroll_container: ScrollContainer = %ScrollContainer

#endregion


func _ready():
    hide()
    scroll_container.clip_contents = true
    options = load_settings()
    if options.is_empty():
        options = SettingsManager.DEFAULT_SETTINGS.duplicate()
        SavingManager.save_as_config("Settings", options, SavingManager.SETTINGS_FILE)
    else:
        options = SettingsManager.check_option_settings(options)
        
    _connect_signals()
    _add_resolutions_to_button()
    reload_language_options()
    if SettingsManager.settings_loaded:
        _set_visual_values()
    else:
        _set_saved_values()
        SettingsManager.settings_loaded = true


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _close_menu()


func _connect_signals() -> void:
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


func save_settings() -> void:
    if options.hash() == original_options.hash():
        return
    settings_changed.emit("Settings", options, SavingManager.SETTINGS_FILE)
    print("Settings saved")

## Returns SavingManager config Settings
func load_settings() -> Dictionary:
    # var data := SavingManager.load_config_data(SavingManager.SETTINGS_FILE)
    # if data.has("Settings"):
    #     data = data["Settings"]
    # print_debug("settings data:\n", data)
    # return data
    return SavingManager.load_from_config("Settings", SavingManager.SETTINGS_FILE)

## Set values from saved settings. Calls signals from value changes
func _set_saved_values() -> void:
    _set_toggles()
    update_audio_properties()
    check_scaler_options()
    # brightness_slider.value = options[Strings.BRIGHTNESS] if options.has(Strings.BRIGHTNESS) else 1.0
    brightness_slider.value = options[Strings.BRIGHTNESS]
    
    _on_scaler_item_selected(options[Strings.SCALER_MODE])
    scaler_options.select(options[Strings.SCALER_MODE])
    if get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR:
        _on_scale_slider_value_changed(options[Strings.SCALER_VALUE])
    elif get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR2:
        _on_fsr_options_item_selected(options[Strings.FSR_SELECTED])

    match get_tree().root.mode:
        Window.MODE_WINDOWED:
            _on_resolution_btn_item_selected(options[Strings.RESOLUTION_INDEX])
            resolution_btn.selected = options[Strings.RESOLUTION_INDEX]
    
## Set values from saved settings visually
func _set_visual_values() -> void:
    fullscreen_btn.set_pressed_no_signal(options[Strings.FULLSCREEN])
    if !fullscreen_btn.button_pressed:
        maximize_btn.set_pressed_no_signal(options[Strings.MAXIMIZED])
    else:
        maximize_btn.set_pressed_no_signal(false)
        
    resolution_btn.selected = options[Strings.RESOLUTION_INDEX]
    vsync_btn.set_pressed_no_signal(options[Strings.VSYNC])
    brightness_slider.set_value_no_signal(options[Strings.BRIGHTNESS])
    scaler_options.selected = options[Strings.SCALER_MODE]
    scale_slider.set_value_no_signal(options[Strings.SCALER_VALUE])
    fsr_options.selected = options[Strings.FSR_SELECTED]
    update_audio_properties()
    check_scaler_options()
    _set_window_mode_states(get_window().mode)


func _set_toggles():
    vsync_btn.button_pressed = options[Strings.VSYNC]
    fullscreen_btn.button_pressed = options[Strings.FULLSCREEN]
    if !fullscreen_btn.button_pressed:
        maximize_btn.button_pressed = options[Strings.MAXIMIZED]
    else:
        maximize_btn.set_pressed_no_signal(false)


func _on_back_btn_pressed() -> void:
    _close_menu()


func _close_menu() -> void:
    anim_player.play_backwards("slide_in")
    await anim_player.animation_finished
    hide()
    if previous_menu:
        previous_menu.show()
    else:
        push_warning("No previous menu to show")


#region Audio------------------------------------------
func update_audio_properties() -> void:
    master_slider.value = options[Strings.MASTER_VOLUME] if options.has(Strings.MASTER_VOLUME) else 0.5
    music_slider.value = options[Strings.MUSIC_VOLUME] if options.has(Strings.MUSIC_VOLUME) else 0.5
    sfx_slider.value = options[Strings.SFX_VOLUME] if options.has(Strings.SFX_VOLUME) else 0.5
    mute_btn.button_pressed = options[Strings.MUTE] if options.has(Strings.MUTE) else false


func _on_mute_btn_toggled(toggled_on: bool) -> void:
    options[Strings.MUTE] = toggled_on
    AudioManager.mute_volume(toggled_on)


func _on_master_slider_value_changed(value: float) -> void:
    AudioManager.set_master_volume(value)
    options[Strings.MASTER_VOLUME] = AudioManager.master_volume


func _on_music_slider_value_changed(value: float) -> void:
    AudioManager.set_music_volume(value)
    options[Strings.MUSIC_VOLUME] = AudioManager.music_volume


func _on_sfx_slider_value_changed(value: float) -> void:
    AudioManager.set_sfx_volume(value)
    options[Strings.SFX_VOLUME] = AudioManager.sfx_volume
#endregion


#region Resolution------------------------------------------
## This can be used to set the text of the resolution button to the real resolution
func _set_resolution_text() -> void:
    # await get_tree().process_frame
    # var window = get_window()
    # var resolution_text = str("%s x %s" % [window.get_size().x, window.get_size().y])
    # resolution_btn.text = resolution_text
    pass


func _set_window_mode() -> void:
    var window_mode = DisplayServer.WINDOW_MODE_WINDOWED
    if options[Strings.FULLSCREEN]:
        window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
    DisplayServer.window_set_mode(window_mode)
    # ProjectSettings.set_setting("display/window/size/window_mode", window_mode)

## Resize window if not fullscreen
func _resize_window() -> void:
    if options[Strings.FULLSCREEN]:
        return

    # if options.has(Strings.WIDTH) and options.has(Strings.HEIGHT):
    var window_size = Vector2i(options[Strings.WIDTH], options[Strings.HEIGHT])
    # scales the game window
    get_tree().root.size = window_size
    # scales the content within the window
    # get_tree().root.content_scale_size = window_size
    _center_window()

## Moves the window to center of screen
func _center_window() -> void:
    if !do_center_window:
        return

    var window_size = Vector2i(options[Strings.WIDTH], options[Strings.HEIGHT])
    var current_monitor = DisplayServer.get_keyboard_focus_screen()
    var screen_size := DisplayServer.screen_get_size(current_monitor)
    var screen_pos := DisplayServer.screen_get_position(current_monitor)
    var x = (screen_size.x - window_size.x) / 2
    var y = (screen_size.y - window_size.y) / 2
    get_tree().root.position = Vector2i(screen_pos.x + x, screen_pos.y + y)


func _add_resolutions_to_button() -> void:
    resolution_btn.clear()
    var screen_size = DisplayServer.screen_get_size()
    var idx: int = 0
    for res in SettingsManager.RESOLUTIONS:
        # only add options that are smaller than the screen
        if res[Strings.WIDTH] > screen_size.x and res[Strings.HEIGHT] > screen_size.y:
            continue

        resolution_btn.add_item("%s x %s" % [res[Strings.WIDTH], res[Strings.HEIGHT]])
        if options.has(Strings.WIDTH) and options.has(Strings.HEIGHT):
            # select the saved resolution
            if res[Strings.WIDTH] == options[Strings.WIDTH] and res[Strings.HEIGHT] == options[Strings.HEIGHT]:
                resolution_btn.select(idx)

        idx += 1


func _on_resolution_btn_item_selected(index: int) -> void:
    var value = clampi(index, 0, SettingsManager.RESOLUTIONS.size() - 1)
    var _size = SettingsManager.RESOLUTIONS[value]
    options[Strings.RESOLUTION_INDEX] = value
    options[Strings.WIDTH] = _size[Strings.WIDTH]
    options[Strings.HEIGHT] = _size[Strings.HEIGHT]
    last_selected_resolution = Vector2i(_size[Strings.WIDTH], _size[Strings.HEIGHT])
    window_position = get_window().position
    _resize_window()
    _set_resolution_text()


func _on_fullscreen_btn_toggled(toggled_on: bool) -> void:
    options[Strings.FULLSCREEN] = toggled_on
    resolution_btn.disabled = toggled_on
    maximize_btn.disabled = toggled_on
    maximize_btn.set_pressed_no_signal(false)
    _set_window_mode()
    _resize_window()
    _set_resolution_text()
    check_scaler_options()


func _on_maximize_btn_toggled(toggled_on: bool) -> void:
    var window = get_window()
    options[Strings.MAXIMIZED] = toggled_on
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
        _center_window()

    _set_resolution_text()
    check_scaler_options()


func _on_window_size_changed() -> void:
    await get_tree().process_frame
    _set_window_mode_states(get_window().mode)
    _set_resolution_text()
    check_scaler_options()

## Set button states based on window mode
func _set_window_mode_states(mode: int) -> void:
    match mode:
        Window.MODE_FULLSCREEN:
            options[Strings.FULLSCREEN] = true
            options[Strings.MAXIMIZED] = false
            resolution_btn.disabled = true
            maximize_btn.disabled = true
            maximize_btn.set_pressed_no_signal(false)
            fullscreen_btn.set_pressed_no_signal(true)
        Window.MODE_MAXIMIZED:
            options[Strings.MAXIMIZED] = true
            options[Strings.FULLSCREEN] = false
            resolution_btn.disabled = true
            maximize_btn.set_pressed_no_signal(true)
            fullscreen_btn.set_pressed_no_signal(false)
        Window.MODE_WINDOWED:
            options[Strings.MAXIMIZED] = false
            options[Strings.FULLSCREEN] = false
            resolution_btn.disabled = false
            maximize_btn.set_pressed_no_signal(false)
            fullscreen_btn.set_pressed_no_signal(false)


#endregion


#region Quality------------------------------------------
## resolution scaling is not available for 2D
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
    options[Strings.SCALER_VALUE] = value
    var resolution_scale = value / 100.00
    scale_text.text = str(value) + "%"
    #--------------for showing resolution in text with scale %--------------#
    # var resolution_text = str(round(get_window().get_size().x * resolution_scale)) + "x" + str(round(get_window().get_size().y * resolution_scale))
    # scale_text.text = (str(value) + "% - " + resolution_text)
    get_viewport().scaling_3d_scale = resolution_scale


func _on_scaler_item_selected(index: int) -> void:
    var viewport = get_viewport()
    options[Strings.SCALER_MODE] = index
    match index:
        1:
            viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
            scale_slider.editable = true
            fsr_container.hide()
            scale_slider.value = options[Strings.SCALER_VALUE]
        2:
            if ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
                _on_scaler_item_selected(1)
                return
            viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
            scale_slider.editable = false
            fsr_container.show()
            _on_fsr_options_item_selected(options[Strings.FSR_SELECTED])
            fsr_options.select(options[Strings.FSR_SELECTED])

## default values when using amd fsr scaling
func _on_fsr_options_item_selected(index: int) -> void:
    options[Strings.FSR_SELECTED] = index
    match index:
        1:
            scale_slider.value = 50.00
        2:
            scale_slider.value = 59.00
        3:
            scale_slider.value = 67.00
        4:
            scale_slider.value = 77.00
        _:
            scale_slider.value = 50.00
#endregion


#region language------------------------------------------
func reload_language_options():
    language_btn.clear()
    var idx: int = 0
    var languages = SettingsManager.locale_list
    for language in languages:
        language_btn.add_icon_item(language["flag"], tr(language["code"]))
        if !options.has(Strings.LOCALE):
            options[Strings.LOCALE] = "en"
        if language[Strings.LOCALE] == options[Strings.LOCALE]:
            language_btn.select(idx)
        # var test = TranslationServer.get_loaded_locales()
        # print_debug(test)
        idx += 1


func _on_language_btn_item_selected(index: int) -> void:
    var language = SettingsManager.locale_list[index]
    options[Strings.LOCALE] = language[Strings.LOCALE]
    TranslationServer.set_locale(options[Strings.LOCALE])
    reload_language_options()


#endregion


#region Other------------------------------------------
func _on_keybind_btn_pressed() -> void:
    if keybind_menu == null:
        push_warning("keybind menu is null")
        return

    keybind_menu.previous_menu = option_panel
    option_panel.hide()
    keybind_menu.show()


func _on_gamma_slider_value_changed(value: float) -> void:
    value = clampf(value, 0.5, 2.0)
    options[Strings.BRIGHTNESS] = value
    brightness_value.text = str("%2.2f" % value)
    if GameManager.get("environment_res") != null:
        GameManager.environment_res.adjustment_brightness = value


func _on_vsync_btn_toggled(toggled_on: bool) -> void:
    options[Strings.VSYNC] = toggled_on
    if toggled_on:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
    else:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
#endregion


func _exit_tree() -> void:
    save_settings()


func _on_visibility_changed() -> void:
    if visible:
        set_process_unhandled_key_input(true)
        original_options = options.duplicate()
        scroll_container.scroll_vertical = 0
        anim_player.play("slide_in")
        await anim_player.animation_finished
        master_slider.call_deferred("grab_focus")
    else:
        set_process_unhandled_key_input(false)
        save_settings()
        original_options.clear()


# func _notification(what: int) -> void:
#     if what == NOTIFICATION_WM_CLOSE_REQUEST:
#         save_settings()
