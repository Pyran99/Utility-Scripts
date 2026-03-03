extends CanvasLayer



@onready var resume_btn: CustomBaseButton = %CustomBaseButton
@onready var menu_btn: CustomBaseButton = %CustomBaseButton2


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        _on_custom_base_button_pressed()


func _on_custom_base_button_pressed() -> void:
    GameManager.resume_game()
    queue_free()


func _on_custom_base_button_2_pressed() -> void:
    SceneManager.load_level(Levels.levels["main_menu"])
    queue_free()
