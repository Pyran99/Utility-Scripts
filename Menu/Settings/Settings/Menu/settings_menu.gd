extends Control
class_name SettingsMenu
## Game settings menu
##
## Settings consist of a list of [SettingsSection] & [SettingsOption]
##[br][member SettingsSection.id] is used as key for [member SettingsManager.settings_data]
##[br]Members: [member general_settings], [member audio_settings], [member video_settings], [member resolution_settings] may contain functions for [SettingsOption]
##[br]To create a new setting: create a new inherited scene of the base setting button type. Add a script that extends the button element type. Override [method SettingsOption._apply_settings] with the implementation of the setting.

const KEYBIND_MENU_PATH: String = "res://Menu/Settings/Keybinds/keybind_menu.tscn"

signal settings_menu_opened
signal settings_menu_closed
signal changes_discarded

## if this menu is in game or main menu; if a setting needs access to something thats only in a level
@export var is_in_game_menu: bool = true
## Sections will be removed before setup
@export var ignored_sections: Array[String]
@export var update_immediately: bool = true

var section_parent: Control
var previous_menu: Control

var general_settings: GeneralSettings
var audio_settings: AudioSettings
var video_settings: VideoSettings
var resolution_settings: ResolutionSettings

@onready var close_btn: Button = %CloseBtn
@onready var apply_btn: Button = %ApplyBtn
@onready var control_btn: Button = %ControlsBtn
@onready var option_panel: Panel = %OptionsPanel


func _enter_tree() -> void:
    general_settings = GeneralSettings.new(self )
    audio_settings = AudioSettings.new(self )
    video_settings = VideoSettings.new(self )
    resolution_settings = ResolutionSettings.new(self )
    section_parent = %Sections
    ignore_sections()


func _ready() -> void:
    _connect_signals()
    apply_btn.disabled = true
    var init_start: bool = SettingsManager.initial_game_start_settings_applied
    SettingsManager.retrieve_settings.emit.call_deferred(!init_start)
    SettingsManager.initial_game_start_settings_applied = true
    set_process_unhandled_key_input(option_panel.is_visible_in_tree())


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_cancel"):
        get_viewport().set_input_as_handled()
        _on_back_pressed()


func set_previous_menu(menu: Control) -> void:
    previous_menu = menu


func ignore_sections() -> void:
    for section in section_parent.get_children():
        if !section is SettingsSection: continue
        if ignored_sections.has(section.id):
            section.queue_free()


func _connect_signals() -> void:
    close_btn.pressed.connect(_on_back_pressed)
    apply_btn.pressed.connect(_on_apply_pressed)
    control_btn.pressed.connect(_on_control_btn_pressed)
    settings_menu_opened.connect(_on_menu_opened)
    settings_menu_closed.connect(_on_menu_closed)
    visibility_changed.connect(_on_visibility_changed)


func _create_keybind_menu() -> void:
    var instance: Control = load(KEYBIND_MENU_PATH).instantiate()
    # instance.set_previous_menu(self )
    # instance.keybind_menu_closed.connect(_on_keybind_menu_closed)
    instance.tree_exiting.connect(_on_keybind_menu_closed)
    add_child(instance)


func _on_visibility_changed() -> void:
    set_process_unhandled_key_input(option_panel.is_visible_in_tree())
    if is_visible_in_tree():
        settings_menu_opened.emit()


func _on_menu_opened() -> void:
    pass


func _on_menu_closed() -> void:
    for section in section_parent.get_children():
        if !section is SettingsSection: continue
        section.discard_changes()
    SettingsManager.save_settings.call_deferred()


func _on_keybind_menu_closed() -> void:
    option_panel.show()
    set_process_unhandled_key_input(option_panel.is_visible_in_tree())


func _on_back_pressed() -> void:
    settings_menu_closed.emit()
    if get_tree().current_scene == self: return
    queue_free()


func _on_apply_pressed() -> void:
    for section in section_parent.get_children():
        if !section is SettingsSection: continue
        # section.apply_stored_changes()
        section.apply_changes_pressed.emit()
    apply_btn.disabled = true
    SettingsManager.changed_elements_count = 0
    SettingsManager.save_settings.call_deferred()


func _on_control_btn_pressed() -> void:
    _create_keybind_menu()
    option_panel.hide()
    set_process_unhandled_key_input(option_panel.is_visible_in_tree())


func _on_discard_changes() -> void:
    for section in section_parent.get_children():
        if !section is SettingsSection: continue
        section.discard_changes()
    apply_btn.disabled = true
    changes_discarded.emit()


func _notification(what: int) -> void:
    # if what == NOTIFICATION_WM_CLOSE_REQUEST:
    #     save_settings()
    pass
