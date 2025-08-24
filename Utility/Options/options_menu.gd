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
    print_debug(AudioServer.get_bus_volume_linear(AudioManager.MUSIC_BUS))
    hide()
    scroll_container.clip_contents = true
    load_settings()
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
    if SettingsManager.settings.hash() == original_options.hash():
        return
    settings_changed.emit(Strings.SETTINGS, SettingsManager.settings, SavingManager.SETTINGS_FILE)
    print("Settings saved")

    SavingManager.save_config_data() # TODO-1

## Returns SavingManager config Settings
func load_settings() -> void:
    SettingsManager.settings = SavingManager.load_from_config(Strings.SETTINGS, SavingManager.SETTINGS_FILE)
    if SettingsManager.settings.is_empty():
        SettingsManager.settings = SettingsManager.DEFAULT_SETTINGS.duplicate()
        SavingManager.save_as_config(Strings.SETTINGS, SettingsManager.settings, SavingManager.SETTINGS_FILE)
    else:
        SettingsManager.settings = SettingsManager.check_option_settings(SettingsManager.settings)
    
    print_debug("Settings loaded:\n%s\n" % SettingsManager.settings)

## Set values from saved settings. Calls signals from value changes
func _set_saved_values() -> void:
    _set_toggles()
    update_audio_properties()
    check_scaler_options()
    # brightness_slider.value = SettingsManager.settings[Strings.BRIGHTNESS] if SettingsManager.settings.has(Strings.BRIGHTNESS) else 1.0
    brightness_slider.value = SettingsManager.settings[Strings.BRIGHTNESS]
    
    _on_scaler_item_selected(SettingsManager.settings[Strings.SCALER_MODE])
    scaler_options.select(SettingsManager.settings[Strings.SCALER_MODE])
    if get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR:
        _on_scale_slider_value_changed(SettingsManager.settings[Strings.SCALER_VALUE])
    elif get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR2:
        _on_fsr_options_item_selected(SettingsManager.settings[Strings.FSR_SELECTED])

    match get_tree().root.mode:
        Window.MODE_WINDOWED:
            _on_resolution_btn_item_selected(SettingsManager.settings[Strings.RESOLUTION_INDEX])
            resolution_btn.selected = SettingsManager.settings[Strings.RESOLUTION_INDEX]
    
## Set values from saved settings visually
func _set_visual_values() -> void:
    fullscreen_btn.set_pressed_no_signal(SettingsManager.settings[Strings.FULLSCREEN])
    if !fullscreen_btn.button_pressed:
        maximize_btn.set_pressed_no_signal(SettingsManager.settings[Strings.MAXIMIZED])
    else:
        maximize_btn.set_pressed_no_signal(false)
        
    resolution_btn.selected = SettingsManager.settings[Strings.RESOLUTION_INDEX]
    vsync_btn.set_pressed_no_signal(SettingsManager.settings[Strings.VSYNC])
    brightness_slider.set_value_no_signal(SettingsManager.settings[Strings.BRIGHTNESS])
    scaler_options.selected = SettingsManager.settings[Strings.SCALER_MODE]
    scale_slider.set_value_no_signal(SettingsManager.settings[Strings.SCALER_VALUE])
    fsr_options.selected = SettingsManager.settings[Strings.FSR_SELECTED]
    update_audio_properties()
    check_scaler_options()
    _set_window_mode_states(get_window().mode)


func _set_toggles():
    vsync_btn.button_pressed = SettingsManager.settings[Strings.VSYNC]
    fullscreen_btn.button_pressed = SettingsManager.settings[Strings.FULLSCREEN]
    if !fullscreen_btn.button_pressed:
        maximize_btn.button_pressed = SettingsManager.settings[Strings.MAXIMIZED]
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
    master_slider.value = SettingsManager.settings[Strings.MASTER_VOLUME] if SettingsManager.settings.has(Strings.MASTER_VOLUME) else 0.5
    music_slider.value = SettingsManager.settings[Strings.MUSIC_VOLUME] if SettingsManager.settings.has(Strings.MUSIC_VOLUME) else 0.5
    sfx_slider.value = SettingsManager.settings[Strings.SFX_VOLUME] if SettingsManager.settings.has(Strings.SFX_VOLUME) else 0.5
    mute_btn.button_pressed = SettingsManager.settings[Strings.MUTE] if SettingsManager.settings.has(Strings.MUTE) else false


func _on_mute_btn_toggled(toggled_on: bool) -> void:
    SettingsManager.set_mute(toggled_on)


func _on_master_slider_value_changed(value: float) -> void:
    SettingsManager.set_master_volume(value)


func _on_music_slider_value_changed(value: float) -> void:
    SettingsManager.set_music_volume(value)


func _on_sfx_slider_value_changed(value: float) -> void:
    SettingsManager.set_sfx_volume(value)

#endregion


#region Resolution------------------------------------------

## This can be used to set the text of the resolution button to the real resolution
func _set_resolution_text() -> void:
    # await get_tree().process_frame
    # var window = get_window()
    # var resolution_text = str("%s x %s" % [window.get_size().x, window.get_size().y])
    # resolution_btn.text = resolution_text
    pass


func _add_resolutions_to_button() -> void:
    resolution_btn.clear()
    var screen_size = DisplayServer.screen_get_size()
    var idx: int = 0
    for res in SettingsManager.RESOLUTIONS:
        # only add SettingsManager.settings that are smaller than the screen
        if res[Strings.WIDTH] > screen_size.x and res[Strings.HEIGHT] > screen_size.y:
            continue

        resolution_btn.add_item("%s x %s" % [res[Strings.WIDTH], res[Strings.HEIGHT]])
        if SettingsManager.settings.has(Strings.WIDTH) and SettingsManager.settings.has(Strings.HEIGHT):
            # select the saved resolution
            if res[Strings.WIDTH] == SettingsManager.settings[Strings.WIDTH] and res[Strings.HEIGHT] == SettingsManager.settings[Strings.HEIGHT]:
                resolution_btn.select(idx)

        idx += 1


func _on_resolution_btn_item_selected(index: int) -> void:
    SettingsManager.set_resolution(index)
    last_selected_resolution = Vector2i(SettingsManager.settings[Strings.WIDTH], SettingsManager.settings[Strings.HEIGHT])
    window_position = get_window().position
    # _set_resolution_text()


func _on_fullscreen_btn_toggled(toggled_on: bool) -> void:
    SettingsManager.settings[Strings.FULLSCREEN] = toggled_on
    resolution_btn.disabled = toggled_on
    maximize_btn.disabled = toggled_on
    maximize_btn.set_pressed_no_signal(false)
    SettingsManager.set_window_mode()
    # _set_resolution_text()
    check_scaler_options()


func _on_maximize_btn_toggled(toggled_on: bool) -> void:
    var window = get_window()
    SettingsManager.settings[Strings.MAXIMIZED] = toggled_on
    SettingsManager.set_window_mode()
    resolution_btn.disabled = toggled_on
    if window.mode == Window.MODE_FULLSCREEN:
        # button shouldnt be active
        return
    if !toggled_on:
        window.size = last_selected_resolution
        window.position = window_position

    # _set_resolution_text()
    check_scaler_options()

# for changing window by something like maximized button on window
func _on_window_size_changed() -> void:
    await get_tree().process_frame
    _set_window_mode_states(get_window().mode)
    # _set_resolution_text()
    check_scaler_options()

## Set button states based on window mode
func _set_window_mode_states(mode: int) -> void:
    match mode:
        Window.MODE_FULLSCREEN:
            SettingsManager.settings[Strings.FULLSCREEN] = true
            SettingsManager.settings[Strings.MAXIMIZED] = false
            resolution_btn.disabled = true
            maximize_btn.disabled = true
            maximize_btn.set_pressed_no_signal(false)
            fullscreen_btn.set_pressed_no_signal(true)
        Window.MODE_MAXIMIZED:
            SettingsManager.settings[Strings.MAXIMIZED] = true
            SettingsManager.settings[Strings.FULLSCREEN] = false
            resolution_btn.disabled = true
            maximize_btn.set_pressed_no_signal(true)
            fullscreen_btn.set_pressed_no_signal(false)
        Window.MODE_WINDOWED:
            SettingsManager.settings[Strings.MAXIMIZED] = false
            SettingsManager.settings[Strings.FULLSCREEN] = false
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
    SettingsManager.settings[Strings.SCALER_VALUE] = value
    SettingsManager.set_scaler_value(value)
    scale_text.text = str(value) + "%"
    # var resolution_scale = value / 100.00
    #--------------for showing resolution in text with scale %--------------#
    # var resolution_text = str(round(get_window().get_size().x * resolution_scale)) + "x" + str(round(get_window().get_size().y * resolution_scale))
    # scale_text.text = (str(value) + "% - " + resolution_text)
    # get_viewport().scaling_3d_scale = resolution_scale


func _on_scaler_item_selected(index: int) -> void:
    SettingsManager.settings[Strings.SCALER_MODE] = index
    SettingsManager.set_scaler_mode(index)
    match index:
        1:
            scale_slider.editable = true
            fsr_container.hide()
            scale_slider.value = SettingsManager.settings[Strings.SCALER_VALUE]
        2:
            if ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
                _on_scaler_item_selected(1)
                return
            scale_slider.editable = false
            fsr_container.show()
            _on_fsr_options_item_selected(SettingsManager.settings[Strings.FSR_SELECTED])
            fsr_options.select(SettingsManager.settings[Strings.FSR_SELECTED])

## default values when using amd fsr scaling
func _on_fsr_options_item_selected(index: int) -> void:
    SettingsManager.set_fsr_mode(index)
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


#region Other------------------------------------------

func _on_keybind_btn_pressed() -> void:
    if keybind_menu == null:
        push_warning("keybind menu is null")
        return

    keybind_menu.previous_menu = option_panel
    option_panel.hide()
    keybind_menu.show()


func _on_gamma_slider_value_changed(value: float) -> void:
    brightness_value.text = str("%2.2f" % value)
    SettingsManager.set_brightness(value)


func _on_vsync_btn_toggled(toggled_on: bool) -> void:
    SettingsManager.set_vsync(toggled_on)


func reload_language_options():
    language_btn.clear()
    var idx: int = 0
    var languages = SettingsManager.locale_list
    for language in languages:
        language_btn.add_icon_item(language["flag"], tr(language["code"]))
        if !SettingsManager.settings.has(Strings.LOCALE):
            SettingsManager.settings[Strings.LOCALE] = "en"
        if language[Strings.LOCALE] == SettingsManager.settings[Strings.LOCALE]:
            language_btn.select(idx)
        # var test = TranslationServer.get_loaded_locales()
        # print_debug(test)
        idx += 1


func _on_language_btn_item_selected(index: int) -> void:
    SettingsManager.set_language(index)
    reload_language_options()

#endregion


func _exit_tree() -> void:
    save_settings()


func _on_visibility_changed() -> void:
    if visible:
        set_process_unhandled_key_input(true)
        original_options = SettingsManager.settings.duplicate()
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
