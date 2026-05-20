extends Control
class_name MainMenu


@export var options_window: Control
@export var play_btn: Button
@export var options_btn: Button
@export var quit_btn: Button

@onready var menu_scene: Control = %Scene
@onready var _3d_level_btn: CustomBaseButton = %"3DLevelBtn"


func _ready():
    _connect_signals()
    #SavingManager.load_game(0)
    #GameManager.change_level_state(GameManager.LevelStates.MENU)
    _start_music()


func _connect_signals() -> void:
    if !play_btn.pressed.is_connected(_on_play_btn_pressed):
        play_btn.pressed.connect(_on_play_btn_pressed)
    if !options_btn.pressed.is_connected(_on_options_btn_pressed):
        options_btn.pressed.connect(_on_options_btn_pressed)
    if !quit_btn.pressed.is_connected(_on_quit_btn_pressed):
        quit_btn.pressed.connect(_on_quit_btn_pressed)
    if !_3d_level_btn.pressed.is_connected(_on_3d_level_pressed):
        _3d_level_btn.pressed.connect(_on_3d_level_pressed)


func _start_music() -> void:
    #GlobalAudioManager.switch_music_by_id(GlobalAudioManager.LevelMusicID.MENU_MUSIC)
    pass


func _on_play_btn_pressed() -> void:
    pass


func _on_options_btn_pressed() -> void:
    if options_window == null:
        menu_scene.hide()
        options_window = load("res://Menu/Settings/Settings/Menu/settings_menu.tscn").instantiate()
        options_window.settings_menu_closed.connect(func(): menu_scene.show())
        get_tree().current_scene.add_child(options_window)


func _on_quit_btn_pressed() -> void:
    get_tree().quit()
    pass


func _on_game_lvl_btn_pressed() -> void:
    pass


func _on_weapon_test_lvl_btn_pressed() -> void:
    pass


func _on_wave_test_lvl_btn_pressed() -> void:
    pass


func _on_3d_level_pressed() -> void:
    SceneManager.load_level(Levels.levels["3d_level"], false)
    pass
