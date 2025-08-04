extends Control
class_name MainMenu

## add 2d_scrolling_texture shader for scrolling background
@export var background: TextureRect
@export var menu_window: Control
@export var options_window: Control
@export var credits_window: Control

@onready var start_btn: Button = %StartBtn
@onready var options_btn: Button = %OptionsBtn
@onready var credits_btn: Button = %CreditsBtn
@onready var quit_btn: Button = %QuitBtn


func _on_start_btn_pressed() -> void:
    SceneManager.load_level(Levels.levels["level_1"])
    pass


func _on_options_btn_pressed() -> void:
    if !options_window:
        return
    options_window.set_previous_menu(menu_window)
    menu_window.hide()
    options_window.show()


func _on_credits_btn_pressed() -> void:
    if !credits_window:
        return


func _on_quit_btn_pressed() -> void:
    GameManager.quit_game()


func _on_menu_visibility_changed() -> void:
    if menu_window.visible:
        await get_tree().process_frame
        start_btn.call_deferred("grab_focus")
