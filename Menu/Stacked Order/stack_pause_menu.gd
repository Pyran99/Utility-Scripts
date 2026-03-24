extends Control


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("move_up"):
        print("pause menu input")