extends Control
class_name MainMenu


@export var options_window: OptionsMenu
@export var play_btn: Button
@export var options_btn: Button
@export var quit_btn: Button

@onready var menu_scene: Control = %Scene


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


func _start_music() -> void:
    #GlobalAudioManager.switch_music_by_id(GlobalAudioManager.LevelMusicID.MENU_MUSIC)
    pass


func _on_play_btn_pressed() -> void:
    pass


func _on_options_btn_pressed() -> void:
    if options_window == null: return
    menu_scene.hide()
    options_window.show()
    options_window.set_previous_menu(menu_scene)


func _on_quit_btn_pressed() -> void:
    # GameManager.quit_game()
    get_tree().quit()
    pass


func _on_game_lvl_btn_pressed() -> void:
    #SceneManager.load_level(Levels.levels["test_game_level"])
    pass


func _on_weapon_test_lvl_btn_pressed() -> void:
    #SceneManager.load_level(Levels.levels["weapon_testing"], false)
    pass


func _on_wave_test_lvl_btn_pressed() -> void:
    #SceneManager.load_level(Levels.levels["wave_test_level"], false)
    pass
