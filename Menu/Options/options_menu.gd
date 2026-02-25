extends Control
class_name OptionsMenu

#-------------------------------------#
# Requires AudioManager
# Requires SavingManager
# Requires SettingsManager
# GameManager with environment resource for bightness
#-------------------------------------#


## the menu to show when this is hidden
@export var previous_menu: Control
@export var keybind_menu: Control
@export var visible_animation: String = "slide_in"

var last_selected_resolution: Vector2i = Vector2i(1280, 720)
var window_position: Vector2i
var original_hash: int
var last_focus_item: Control

#region Nodes onready
@onready var option_panel: PanelContainer = $OptionsPanel
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var settings_container: VBoxContainer = %SettingsContainer

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
@onready var keys_btn: Button = %KeybindsBtn
@onready var back_btn: Button = %BackBtn

@onready var scroll_container: ScrollContainer = %ScrollContainer

#endregion


func _ready():
    set_process_unhandled_key_input.call_deferred(visible)
    _connect_signals()
    _add_resolutions_to_button()
    reload_language_options()
    load_settings()
    for i in settings_container.get_children():
        if i is OptionContainer:
            i.options_menu = self
    original_hash = SettingsManager.settings.hash()


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if visible and option_panel.visible:
            get_viewport().set_input_as_handled()
            _close_menu()


func _connect_signals() -> void:
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

    language_btn.item_selected.connect(_on_language_btn_item_selected)

    keys_btn.pressed.connect(_on_keybind_btn_pressed)
    back_btn.pressed.connect(_on_back_btn_pressed)

    SettingsManager.language_changed.connect(_on_language_changed)


func set_previous_menu(menu: Control) -> void:
    previous_menu = menu


func save_settings() -> void:
    if SettingsManager.settings.hash() == original_hash:
        return
    SettingsManager.save_settings()
    original_hash = SettingsManager.settings.hash()
    print("Settings saved")


func load_settings() -> void:
    assert(SettingsManager.settings.has(Strings.SETTINGS))
    if SettingsManager.settings_loaded:
        _set_visual_values()
    else:
        SettingsManager.settings_loaded = true
        _set_saved_values()

## Set values from saved settings. Calls signals from value changes
func _set_saved_values() -> void:
    _set_toggles()
    update_audio_properties()
    check_scaler_options()
    var settings = SettingsManager.settings[Strings.SETTINGS]
    var default = SettingsManager.DEFAULT_SETTINGS
    brightness_slider.value = settings.get(Strings.BRIGHTNESS, default[Strings.BRIGHTNESS])
    var mode = settings.get(Strings.SCALER_MODE, default[Strings.SCALER_MODE])
    _on_scaler_item_selected(mode)
    scaler_options.select(mode)
    var viewport = get_viewport()
    if viewport.scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR:
        _on_scale_slider_value_changed(settings.get(Strings.SCALER_VALUE, default[Strings.SCALER_VALUE]))
    elif viewport.scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR2:
        _on_fsr_options_item_selected(settings.get(Strings.FSR_SELECTED, default[Strings.FSR_SELECTED]))
    match get_tree().root.mode:
        Window.MODE_WINDOWED:
            var idx = SettingsManager.get_resolution_index()
            _on_resolution_btn_item_selected(idx)
            resolution_btn.selected = idx

## Set values from saved settings visually
func _set_visual_values() -> void:
    var settings = SettingsManager.settings[Strings.SETTINGS]
    var default = SettingsManager.DEFAULT_SETTINGS
    fullscreen_btn.set_pressed_no_signal(settings.get(Strings.FULLSCREEN, default[Strings.FULLSCREEN]))
    if !fullscreen_btn.button_pressed:
        maximize_btn.set_pressed_no_signal(settings.get(Strings.MAXIMIZED, default[Strings.MAXIMIZED]))
    else:
        maximize_btn.set_pressed_no_signal(false)
    resolution_btn.selected = SettingsManager.get_resolution_index()
    vsync_btn.set_pressed_no_signal(settings.get(Strings.VSYNC, default[Strings.VSYNC]))
    var _brightness = settings.get(Strings.BRIGHTNESS, default[Strings.BRIGHTNESS])
    brightness_slider.set_value_no_signal(_brightness)
    brightness_value.text = str("%2.2f" % _brightness)
    scaler_options.selected = settings.get(Strings.SCALER_MODE, default[Strings.SCALER_MODE])
    var _scaler = settings.get(Strings.SCALER_VALUE, default[Strings.SCALER_VALUE])
    scale_slider.set_value_no_signal(_scaler)
    scale_text.text = str(_scaler) + "%"
    fsr_options.selected = settings.get(Strings.FSR_SELECTED, default[Strings.FSR_SELECTED])
    update_audio_properties()
    check_scaler_options()
    _set_window_mode_states(get_window().mode)


func _set_toggles():
    var settings = SettingsManager.settings[Strings.SETTINGS]
    var default = SettingsManager.DEFAULT_SETTINGS
    vsync_btn.button_pressed = settings.get(Strings.VSYNC, default[Strings.VSYNC])
    fullscreen_btn.button_pressed = settings.get(Strings.FULLSCREEN, default[Strings.FULLSCREEN])
    if !fullscreen_btn.button_pressed:
        maximize_btn.button_pressed = settings.get(Strings.MAXIMIZED, default[Strings.MAXIMIZED])
    else:
        maximize_btn.set_pressed_no_signal(false)


func _on_back_btn_pressed() -> void:
    _close_menu()


func _close_menu() -> void:
    anim_player.play_backwards(visible_animation)
    await anim_player.animation_finished
    hide()
    if previous_menu:
        previous_menu.show()
    else:
        push_warning("No previous menu to show")


func _get_focus_first_visible_container() -> Node:
    for child in settings_container.get_children():
        if child.visible:
            if child.get("option_button") != null:
                child.grab_btn_focus()
                return child.option_button
    return null


#region Audio------------------------------------------

func update_audio_properties() -> void:
    var settings = SettingsManager.settings[Strings.AUDIO]
    var default = SettingsManager.DEFAULT_AUDIO
    master_slider.value = settings.get(Strings.MASTER_VOLUME, default[Strings.MASTER_VOLUME])
    music_slider.value = settings.get(Strings.MUSIC_VOLUME, default[Strings.MUSIC_VOLUME])
    # sfx_slider.value = settings.get(Strings.SFX_VOLUME, default[Strings.SFX_VOLUME])
    sfx_slider.set_value_no_signal(settings.get(Strings.SFX_VOLUME, default[Strings.SFX_VOLUME]))
    mute_btn.button_pressed = settings.get(Strings.MUTE, default[Strings.MUTE])


func _on_mute_btn_toggled(toggled_on: bool) -> void:
    AudioManager.mute_volume(toggled_on)


func _on_master_slider_value_changed(value: float) -> void:
    AudioManager.set_master_volume(value)


func _on_music_slider_value_changed(value: float) -> void:
    AudioManager.set_music_volume(value)


#var sfx_click = preload("res://Assets/Audio/Sounds/Button7.wav")

func _on_sfx_slider_value_changed(value: float) -> void:
    AudioManager.set_sfx_volume(value)
    #GlobalAudioManager.play_global_sound(sfx_click)

#endregion


#region Resolution------------------------------------------

## This can be used to set the text of the resolution button to the real resolution
func _set_resolution_text() -> void:
    # await get_tree().process_frame
    # var window = get_window()
    # var resolution_text = str("%s x %s" % [window.get_size().x, window.get_size().y])
    # resolution_btn.text = resolution_text
    # SettingsManager.set_resolution_by_value(window.get_size().x, window.get_size().y)
    pass


func _add_resolutions_to_button() -> void:
    resolution_btn.clear()
    var screen_size = DisplayServer.screen_get_size()
    var idx: int = 0
    var settings = SettingsManager.settings[Strings.SETTINGS]
    for res in SettingsManager.RESOLUTIONS:
        # only add SettingsManager.settings that are smaller than the screen
        if res[Strings.WIDTH] > screen_size.x and res[Strings.HEIGHT] > screen_size.y:
            continue

        resolution_btn.add_item("%s x %s" % [res[Strings.WIDTH], res[Strings.HEIGHT]])
        if settings.has(Strings.WIDTH) and settings.has(Strings.HEIGHT):
            # select the saved resolution
            if res[Strings.WIDTH] == settings[Strings.WIDTH] and res[Strings.HEIGHT] == settings[Strings.HEIGHT]:
                resolution_btn.select(idx)

        idx += 1


func _on_resolution_btn_item_selected(index: int) -> void:
    SettingsManager.set_resolution(index)
    var settings = SettingsManager.settings[Strings.SETTINGS]
    last_selected_resolution = Vector2i(settings[Strings.WIDTH], settings[Strings.HEIGHT])
    window_position = get_window().position
    _set_resolution_text()


func _on_fullscreen_btn_toggled(toggled_on: bool) -> void:
    SettingsManager.set_save_setting(Strings.SETTINGS, Strings.FULLSCREEN, toggled_on)
    resolution_btn.disabled = toggled_on
    maximize_btn.disabled = toggled_on
    maximize_btn.set_pressed_no_signal(false)
    SettingsManager.set_window_mode()
    _set_resolution_text()
    check_scaler_options()


func _on_maximize_btn_toggled(toggled_on: bool) -> void:
    var window = get_window()
    SettingsManager.set_save_setting(Strings.SETTINGS, Strings.MAXIMIZED, toggled_on)
    SettingsManager.set_window_mode()
    resolution_btn.disabled = toggled_on
    if window.mode == Window.MODE_FULLSCREEN:
        # button shouldnt be active
        return
    if !toggled_on:
        window.size = last_selected_resolution
        window.position = window_position

    _set_resolution_text()
    check_scaler_options()

# for changing window by something like maximized button on window
func _on_window_size_changed() -> void:
    await get_tree().process_frame
    _set_window_mode_states(get_window().mode)
    _set_resolution_text()
    check_scaler_options()

## Set button states based on window mode
func _set_window_mode_states(mode: int) -> void:
    match mode:
        Window.MODE_FULLSCREEN:
            SettingsManager.set_save_setting(Strings.SETTINGS, Strings.FULLSCREEN, true)
            SettingsManager.set_save_setting(Strings.SETTINGS, Strings.MAXIMIZED, false)
            resolution_btn.disabled = true
            maximize_btn.disabled = true
            maximize_btn.set_pressed_no_signal(false)
            fullscreen_btn.set_pressed_no_signal(true)
        Window.MODE_MAXIMIZED:
            SettingsManager.set_save_setting(Strings.SETTINGS, Strings.MAXIMIZED, true)
            SettingsManager.set_save_setting(Strings.SETTINGS, Strings.FULLSCREEN, false)
            resolution_btn.disabled = true
            maximize_btn.set_pressed_no_signal(true)
            fullscreen_btn.set_pressed_no_signal(false)
        Window.MODE_WINDOWED:
            SettingsManager.set_save_setting(Strings.SETTINGS, Strings.FULLSCREEN, false)
            SettingsManager.set_save_setting(Strings.SETTINGS, Strings.MAXIMIZED, false)
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
    SettingsManager.set_scaler_value(value)
    scale_text.text = str(value) + "%"
    # var resolution_scale = value / 100.00
    #--------------for showing resolution in text with scale %--------------#
    # var resolution_text = str(round(get_window().get_size().x * resolution_scale)) + "x" + str(round(get_window().get_size().y * resolution_scale))
    # scale_text.text = (str(value) + "% - " + resolution_text)
    # get_viewport().scaling_3d_scale = resolution_scale


func _on_scaler_item_selected(index: int) -> void:
    var settings = SettingsManager.settings[Strings.SETTINGS]
    SettingsManager.set_scaler_mode(index)
    match index:
        1:
            scale_slider.editable = true
            fsr_container.hide()
            scale_slider.value = settings[Strings.SCALER_VALUE]
        2:
            if ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
                _on_scaler_item_selected(1)
                return
            scale_slider.editable = false
            fsr_container.show()
            _on_fsr_options_item_selected(settings[Strings.FSR_SELECTED])
            fsr_options.select(settings[Strings.FSR_SELECTED])

## default values when using amd fsr scaling
func _on_fsr_options_item_selected(index: int) -> void:
    SettingsManager.set_fsr_index(index)
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
    last_focus_item = %KeybindsBtn
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
    var settings = SettingsManager.settings[Strings.SETTINGS]
    for language in languages:
        language_btn.add_icon_item(language.get("flag"), tr(language["language"]))
        if !settings.has(Strings.LOCALE):
            settings[Strings.LOCALE] = SettingsManager.DEFAULT_SETTINGS[Strings.LOCALE]
        var lang: String = language[Strings.LOCALE]
        var saved_lang: String = settings[Strings.LOCALE]
        if lang == saved_lang:
            language_btn.select(idx)
        idx += 1


func _on_language_btn_item_selected(index: int) -> void:
    SettingsManager.set_language(index)
    reload_language_options()


func _on_language_changed(locale: String) -> void:
    language_btn.select(SettingsManager.get_language_index_by_locale(locale))

#endregion


func _exit_tree() -> void:
    save_settings()
    original_hash = 0


func _on_visibility_changed() -> void:
    set_process_unhandled_key_input(visible)
    if visible:
        original_hash = SettingsManager.settings.hash()
        scroll_container.scroll_vertical = 0
        anim_player.play(visible_animation)
        await anim_player.animation_finished
        # _get_focus_first_visible_container()
    else:
        save_settings()


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        save_settings()


func _on_options_panel_visibility_changed() -> void:
    if get_tree().current_scene == self: return
    _on_language_changed(TranslationServer.get_locale())
    if option_panel.visible and !anim_player.is_playing():
        if last_focus_item != null:
            last_focus_item.grab_focus()
            return
        # _get_focus_first_visible_container()
