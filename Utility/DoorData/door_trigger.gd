extends Area2D
class_name DoorTrigger

## shows console warning message if doors_in_level not found
@export var toggle_warning: bool = true

## The level that will be loaded by SceneManager
@export_file("*.tscn") var level_path: String

## The position the player will be set to when the new scene loads. Hint: use ruler mode (R) to get the Vector2
@export var spawn_pos: Vector2 = Vector2.ZERO

func _on_body_entered(_body: Node2D) -> void:
    var data = get_tree().get_first_node_in_group("doors_in_level")
    if data:
        data.door_transition_data.door_used = self.name
    elif toggle_warning:
        push_warning("doors_in_level not found")
    SceneManager.load_level(level_path)
