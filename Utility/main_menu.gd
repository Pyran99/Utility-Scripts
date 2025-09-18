extends Control
class_name MainMenu


@export var options_window: OptionsMenu

@onready var scene: Control = %Scene


func _ready():
    %GameLvlBtn.call_deferred("grab_focus")


func _on_game_lvl_btn_pressed() -> void:
    SceneManager.load_level(Levels.levels["test_game_level"])


func _on_weapon_test_lvl_btn_pressed() -> void:
    SceneManager.load_level(Levels.levels["weapon_testing"], false)


func _on_wave_test_lvl_btn_pressed() -> void:
    SceneManager.load_level(Levels.levels["wave_test_level"], false)


func _on_options_btn_pressed() -> void:
    if options_window != null:
        scene.hide()
        options_window.show()
        options_window.set_previous_menu(scene)
        

func _on_quit_btn_pressed() -> void:
    # GameManager.quit_game()
    get_tree().quit()
    pass


func _on_scene_visibility_changed() -> void:
    if is_instance_valid(scene):
        if scene.visible:
            %GameLvlBtn.call_deferred("grab_focus")
