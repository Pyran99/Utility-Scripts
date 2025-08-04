extends Node
#AUTOLOAD

# for setting brightness
# var environment_res: Environment = preload("res://world_environment.tres")

func _ready():
    # get_window().unresizable = true
    # this is for these managers not being set to autoload
    SettingsManager.init()
    KeybindManager.init()
    pass


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        SceneManager.load_level(Levels.levels["main_menu"])


func quit_game():
    get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
    get_tree().quit()
